//
//  ChatViewModel.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/11/25.
//

import Foundation
import SwiftUI

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var currentInput: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isDictating: Bool = false
    @Published var isTranscribing: Bool = false
    
    private let aiService: AIService
    private var audioRecorder: AudioRecorderService?
    private let whisperService = WhisperService()
    private var currentRecordingURL: URL?
    
    init(aiService: AIService = OllamaService()) {
        self.aiService = aiService
        addMessage("Welcome to Nova! How can I assist you today?", isUser: false)
        
        // Initialize audio recorder on main actor
        Task { @MainActor in
            self.audioRecorder = AudioRecorderService()
        }
    }
    
    func sendMessage() {
        guard !currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard !isLoading else { return }
        
        let userMessage = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
        addMessage(userMessage, isUser: true)
        currentInput = ""
        
        Task {
            await generateAIResponse(for: userMessage)
        }
    }
    
    private func addMessage(_ content: String, isUser: Bool) {
        let message = ChatMessage(content: content, isUser: isUser)
        messages.append(message)
    }
    
    @MainActor
    private func generateAIResponse(for userMessage: String) async {
        isLoading = true
        errorMessage = nil
        
        // Create placeholder message for streaming
        let placeholderMessage = ChatMessage(content: "", isUser: false, isStreaming: true)
        messages.append(placeholderMessage)
        let messageIndex = messages.count - 1
        
        do {
            let stream = aiService.generateStreamingResponse(for: userMessage)
            var fullResponse = ""
            
            for try await chunk in stream {
                fullResponse += chunk
                // Update the placeholder message with accumulated response
                messages[messageIndex] = ChatMessage(content: fullResponse, isUser: false, isStreaming: true)
            }
            
            // Mark streaming as complete
            messages[messageIndex] = ChatMessage(content: fullResponse, isUser: false, isStreaming: false)
        } catch {
            let errorMsg = error.localizedDescription
            errorMessage = errorMsg
            // Replace placeholder with error message
            messages[messageIndex] = ChatMessage(content: "Sorry, I encountered an error: \(errorMsg)", isUser: false, isStreaming: false)
        }
        
        isLoading = false
    }
    
    func retryLastMessage() {
        guard let lastUserMessage = messages.last(where: { $0.isUser }) else { return }
        
        Task {
            await generateAIResponse(for: lastUserMessage.content)
        }
    }
    
    func clearConversation() {
        messages.removeAll()
        if let ollamaService = aiService as? OllamaService {
            ollamaService.clearConversationHistory()
        }
        addMessage("Welcome to Nova! How can I assist you today?", isUser: false)
    }
    
    @MainActor
    func toggleDictation() {
        if isDictating {
            stopDictation()
        } else {
            startDictation()
        }
    }
    
    @MainActor
    private func startDictation() {
        guard !isDictating && !isTranscribing else { return }
        guard let audioRecorder = audioRecorder else { return }
        
        Task {
            do {
                currentRecordingURL = try await audioRecorder.startRecording()
                await MainActor.run {
                    isDictating = true
                    errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to start recording: \(error.localizedDescription)"
                }
            }
        }
    }
    
    @MainActor
    private func stopDictation() {
        guard isDictating else { return }
        guard let audioRecorder = audioRecorder else { return }
        
        guard let recordingURL = audioRecorder.stopRecording() else {
            isDictating = false
            return
        }
        
        isDictating = false
        isTranscribing = true
        currentRecordingURL = recordingURL
        
        Task {
            await transcribeAudio(from: recordingURL)
        }
    }
    
    @MainActor
    private func transcribeAudio(from url: URL) async {
        do {
            let response = try await whisperService.transcribeFile(at: url)
            let transcription = response.fullText
            
            // Append transcription to current input with a space if needed
            if !currentInput.isEmpty && !currentInput.hasSuffix(" ") {
                currentInput += " "
            }
            currentInput += transcription
            
            // Clean up the audio file
            try? FileManager.default.removeItem(at: url)
            currentRecordingURL = nil
            
        } catch {
            errorMessage = "Transcription failed: \(error.localizedDescription)"
            // Clean up the audio file even on error
            try? FileManager.default.removeItem(at: url)
            currentRecordingURL = nil
        }
        
        isTranscribing = false
    }
    
    @MainActor
    func cancelDictation() {
        if isDictating, let audioRecorder = audioRecorder {
            Task {
                await audioRecorder.cancelRecording()
                isDictating = false
            }
        }
        
        if let url = currentRecordingURL {
            try? FileManager.default.removeItem(at: url)
            currentRecordingURL = nil
        }
        
        isTranscribing = false
    }
}