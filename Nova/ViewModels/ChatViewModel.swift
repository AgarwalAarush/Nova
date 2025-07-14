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
        print("🎤 Starting dictation...")
        guard !isDictating && !isTranscribing else { 
            print("🎤 Cannot start dictation - already dictating: \(isDictating) or transcribing: \(isTranscribing)")
            return 
        }
        guard let audioRecorder = audioRecorder else { 
            print("🎤 No audio recorder available")
            return 
        }
        
        Task {
            do {
                currentRecordingURL = try await audioRecorder.startRecording()
                print("🎤 Recording started, URL: \(currentRecordingURL?.absoluteString ?? "nil")")
                await MainActor.run {
                    isDictating = true
                    errorMessage = nil
                }
            } catch AudioRecorderError.permissionDenied {
                print("🎤 Microphone permission denied")
                await MainActor.run {
                    errorMessage = "Microphone access denied. Please enable microphone access for Nova in:\nSystem Settings > Privacy & Security > Microphone\n\nThen restart the app."
                }
            } catch {
                print("🎤 Failed to start recording: \(error)")
                await MainActor.run {
                    errorMessage = "Failed to start recording: \(error.localizedDescription)"
                }
            }
        }
    }
    
    @MainActor
    private func stopDictation() {
        print("🎤 Stopping dictation...")
        guard isDictating else { 
            print("🎤 Not currently dictating")
            return 
        }
        guard let audioRecorder = audioRecorder else { 
            print("🎤 No audio recorder available")
            return 
        }
        
        guard let recordingURL = audioRecorder.stopRecording() else {
            print("🎤 Failed to get recording URL from audio recorder")
            isDictating = false
            return
        }
        
        print("🎤 Recording stopped, URL: \(recordingURL.absoluteString)")
        isDictating = false
        isTranscribing = true
        currentRecordingURL = recordingURL
        
        Task {
            await transcribeAudio(from: recordingURL)
        }
    }
    
    @MainActor
    private func transcribeAudio(from url: URL) async {
        print("🎤 Starting transcription for file: \(url)")
        
        do {
            // Check if file exists and has content
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw NSError(domain: "AudioTranscription", code: 1, userInfo: [NSLocalizedDescriptionKey: "Recording file not found"])
            }
            
            let fileSize = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64 ?? 0
            print("🎤 Audio file size: \(fileSize) bytes")
            
            if fileSize == 0 {
                throw NSError(domain: "AudioTranscription", code: 2, userInfo: [NSLocalizedDescriptionKey: "Recording file is empty"])
            }
            
            print("🎤 Calling whisperService.transcribeFile...")
            let response = try await whisperService.transcribeFile(at: url)
            print("🎤 Transcription response received: \(response)")
            
            let transcription = response.fullText.trimmingCharacters(in: .whitespacesAndNewlines)
            print("🎤 Transcribed text: '\(transcription)'")
            
            // Check for common silent audio indicators
            let silentIndicators = ["[ Silence ]", "[BLANK_AUDIO]", "[silence]", "[blank_audio]", "[ silence ]"]
            let isSilentAudio = silentIndicators.contains { transcription.lowercased().contains($0.lowercased()) }
            
            if !transcription.isEmpty && !isSilentAudio {
                // Append transcription to current input with a space if needed
                if !currentInput.isEmpty && !currentInput.hasSuffix(" ") {
                    currentInput += " "
                }
                currentInput += transcription
                print("🎤 Updated currentInput: '\(currentInput)'")
            } else {
                if isSilentAudio {
                    print("🎤 ⚠️ Warning: Whisper detected silent/blank audio - microphone may not be working")
                    errorMessage = "No speech detected - check microphone permissions and try speaking louder"
                } else {
                    print("🎤 Warning: Transcription result is empty")
                    errorMessage = "No speech detected in recording"
                }
            }
            
            // Clean up the audio file
            try? FileManager.default.removeItem(at: url)
            currentRecordingURL = nil
            
        } catch {
            print("🎤 Transcription error: \(error)")
            errorMessage = "Transcription failed: \(error.localizedDescription)"
            // Clean up the audio file even on error
            try? FileManager.default.removeItem(at: url)
            currentRecordingURL = nil
        }
        
        isTranscribing = false
        print("🎤 Transcription process completed")
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