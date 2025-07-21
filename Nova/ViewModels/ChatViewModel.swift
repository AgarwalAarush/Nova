//
//  ChatViewModel.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/11/25.
//

import Foundation
import SwiftUI
import Combine

enum ViewMode: CaseIterable {
    case normal
    case compactVoice
}

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var currentInput: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isDictating: Bool = false
    @Published var isTranscribing: Bool = false
    @Published var viewMode: ViewMode = .normal
    @Published var previousNormalHeight: CGFloat = 900
    
    // Continuous listening properties
    @Published var isContinuousListening: Bool = false
    @Published var isVoiceActive: Bool = false
    @Published var continuousAudioLevel: Float = 0.0
    
    // Escape key navigation state
    @Published var isInputFocused: Bool = false
    
    let aiServiceRouter: AIServiceRouter
    private var audioRecorder: AudioRecorderService?
    private var whisperService: WhisperService?
    private var currentRecordingURL: URL?
    private let clipboardService = ClipboardService.shared
    
    // Continuous audio monitoring
    private var continuousAudioService: ContinuousAudioService?
    private var cancellables = Set<AnyCancellable>()
    
    
    init(aiServiceRouter: AIServiceRouter? = nil) {
        // Initialize AI service router - it will create its own automation service
        self.aiServiceRouter = aiServiceRouter ?? AIServiceRouter()
        
        addMessage("Welcome to Nova! How can I assist you today?", isUser: false)
        
        // Initialize audio services asynchronously
        Task { @MainActor in
            self.audioRecorder = AudioRecorderService()
            self.setupContinuousAudioService()
        }
    }
    
    func setWhisperService(_ service: WhisperService) {
        self.whisperService = service
    }
    
    func setAIServiceRouter(_ router: AIServiceRouter) {
        // The router is already set in init, but we could update it here if needed
        // For now, we'll keep the existing router since it's initialized with the correct config
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
        // Use the enhanced routing method for all AI responses
        await generateAIResponseWithRouting(for: userMessage, isFromContinuousAudio: false)
    }
    
    /// Format error messages to be more user-friendly
    private func formatErrorMessage(_ error: Error) -> String {
        if let aiError = error as? AIServiceError {
            switch aiError {
            case .ollamaNotRunning:
                return "Ollama is not running. Please start Ollama by running 'ollama serve' in your terminal, or restart the Ollama app."
            case .ollamaModelNotInstalled(let model):
                return "The model '\(model)' is not installed. Please install it by running 'ollama pull \(model)' in your terminal."
            case .ollamaModelLoading(let model):
                return "The model '\(model)' is loading. Large models can take several minutes to load on first use. Please wait and try again."
            case .networkError(let networkError):
                if let nsError = networkError as NSError?, nsError.code == -1001 {
                    return "Request timed out. This usually happens when the AI model is loading for the first time. Please try again in a moment."
                }
                return "Network error: \(networkError.localizedDescription)"
            case .modelNotFound:
                return "The selected AI model is not available. Please check your model configuration or try a different model."
            case .rateLimited:
                return "Rate limit exceeded. Please wait a moment and try again."
            case .serverError(let code):
                return "Server error (code \(code)). Please try again later."
            default:
                return error.localizedDescription
            }
        }
        
        return error.localizedDescription
    }
    
    func retryLastMessage() {
        guard let lastUserMessage = messages.last(where: { $0.isUser }) else { return }
        
        Task {
            await generateAIResponse(for: lastUserMessage.content)
        }
    }
    
    /// Check if Ollama is running and properly configured
    func checkOllamaStatus() async -> (isRunning: Bool, hasModel: Bool, error: String?) {
        guard let ollamaService = aiServiceRouter.getCurrentService() as? OllamaService else {
            return (false, false, "Ollama service not available")
        }
        
        do {
            try await ollamaService.checkAvailability()
            return (true, true, nil)
        } catch let error as AIServiceError {
            switch error {
            case .ollamaNotRunning:
                return (false, false, "Ollama is not running")
            case .ollamaModelNotInstalled(let model):
                return (true, false, "Model '\(model)' is not installed")
            default:
                return (false, false, error.localizedDescription)
            }
        } catch {
            return (false, false, error.localizedDescription)
        }
    }
    
    /// Launch Ollama using the system's default app launcher
    func launchOllama() {
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = ["-a", "Ollama"]
        
        do {
            try task.run()
        } catch {
            print("Failed to launch Ollama: \(error)")
        }
    }
    
    /// Open terminal and run ollama serve command
    func startOllamaServer() {
        let script = """
        tell application "Terminal"
            activate
            do script "ollama serve"
        end tell
        """
        
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(nil)
        }
    }
    
    /// Open terminal and run ollama pull command for a specific model
    func installOllamaModel(_ model: String) {
        let script = """
        tell application "Terminal"
            activate
            do script "ollama pull \(model)"
        end tell
        """
        
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(nil)
        }
    }
    
    func clearConversation() {
        messages.removeAll()
        aiServiceRouter.clearAllConversationHistory()
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
    func toggleViewMode() {
        viewMode = viewMode == .normal ? .compactVoice : .normal
    }
    
    // MARK: - Escape Key Navigation
    
    @MainActor
    func handleEscapeKey() {
        // Plain escape only removes focus, no view switching
        // Focus removal is handled by GrowingTextView
    }
    
    @MainActor
    func handleCommandEscapeKey() {
        // Command+Escape toggles between ChatView and CompactVoiceView
        toggleViewMode()
    }
    
    @MainActor
    func handleCommandPKey() {
        // Command+P toggles window pinning (always on top)
        AppConfig.shared.enableWindowPinning.toggle()
    }
    
    @MainActor
    func setInputFocus(_ focused: Bool) {
        isInputFocused = focused
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
                isDictating = true
                errorMessage = nil
            } catch AudioRecorderError.permissionDenied {
                print("🎤 Microphone permission denied")
                errorMessage = "Microphone access denied. Please enable microphone access for Nova in:\nSystem Settings > Privacy & Security > Microphone\n\nThen restart the app."
            } catch {
                print("🎤 Failed to start recording: \(error)")
                errorMessage = "Failed to start recording: \(error.localizedDescription)"
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
            
            guard let whisperService = self.whisperService else {
                throw NSError(domain: "AudioTranscription", code: 3, userInfo: [NSLocalizedDescriptionKey: "WhisperService not available"])
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
                if viewMode == .compactVoice || isContinuousListening {
                    // In continuous listening mode, auto-process with AI routing
                    print("🎤 🤖 Continuous mode: Processing transcription with AI routing")
                    await processContinuousAudioTranscription(transcription)
                } else {
                    // In normal mode, append transcription to current input with a space if needed
                    if !currentInput.isEmpty && !currentInput.hasSuffix(" ") {
                        currentInput += " "
                    }
                    currentInput += transcription
                    print("🎤 Updated currentInput: '\(transcription)'")
                }
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
    
    /// Process transcribed audio from continuous listening with AI routing
    @MainActor
    private func processContinuousAudioTranscription(_ transcription: String) async {
        print("🎤 🤖 Processing continuous audio transcription: '\(transcription)'")
        
        // Format message with current clipboard content for enhanced context
        let clipboardContent = clipboardService.getCurrentClipboardContent()
        let contextualMessage = formatVoiceMessage(clipboardContent: clipboardContent, userPrompt: transcription)
        
        // Add user message to conversation
        addMessage(transcription, isUser: true)
        
        // Generate AI response with routing (includes tool calling)
        print("🎤 🤖 Generating AI response with routing for continuous audio...")
        await generateAIResponseWithRouting(for: contextualMessage, isFromContinuousAudio: true)
    }
    
    /// Enhanced AI response generation with routing for continuous audio
    @MainActor
    private func generateAIResponseWithRouting(for userMessage: String, isFromContinuousAudio: Bool = false) async {
        isLoading = true
        errorMessage = nil
        
        let logPrefix = isFromContinuousAudio ? "🎤 🤖" : "💬"
        print("\(logPrefix) Starting AI response generation with routing...")
        
        // Create placeholder message for streaming
        let placeholderMessage = ChatMessage(content: "", isUser: false, isStreaming: true)
        messages.append(placeholderMessage)
        let messageIndex = messages.count - 1
        
        do {
            // Use the routing-enabled response generation for intelligent tool calling
            print("\(logPrefix) Calling generateResponseWithRouting...")
            let response = try await aiServiceRouter.generateResponseWithRouting(for: userMessage)
            
            print("\(logPrefix) AI response received (\(response.count) chars)")
            
            // Update the message with the final response
            Task { @MainActor in
                if messageIndex < messages.count {
                    messages[messageIndex].content = response
                    messages[messageIndex].isStreaming = false
                    print("\(logPrefix) ✅ AI response updated in conversation")
                }
            }
        } catch {
            let errorMsg = formatErrorMessage(error)
            errorMessage = errorMsg
            print("\(logPrefix) ❌ AI response error: \(errorMsg)")
            
            // Update content with error message
            Task { @MainActor in
                if messageIndex < messages.count {
                    messages[messageIndex].content = "Sorry, I encountered an error: \(errorMsg)"
                    messages[messageIndex].isStreaming = false
                }
            }
        }
        
        isLoading = false
        print("\(logPrefix) AI response generation completed")
    }
    
    private func formatVoiceMessage(clipboardContent: String, userPrompt: String) -> String {
        let formattedMessage = """
        <clipboard>\(clipboardContent)</clipboard>
        
        <user_prompt>\(userPrompt)</user_prompt>
        """
        return formattedMessage
    }
    
    // MARK: - Continuous Audio Service
    
    private func setupContinuousAudioService() {
        continuousAudioService = ContinuousAudioService()
        continuousAudioService?.delegate = self
        
        // Bind published properties
        if let service = continuousAudioService {
            // Monitor service state changes
            service.$isMonitoring
                .receive(on: DispatchQueue.main)
                .sink { [weak self] isMonitoring in
                    self?.isContinuousListening = isMonitoring
                }
                .store(in: &cancellables)
            
            service.$isVoiceActive
                .receive(on: DispatchQueue.main)
                .sink { [weak self] isActive in
                    self?.isVoiceActive = isActive
                }
                .store(in: &cancellables)
            
            service.$audioLevel
                .receive(on: DispatchQueue.main)
                .sink { [weak self] level in
                    self?.continuousAudioLevel = level
                }
                .store(in: &cancellables)
        }
    }
    
    @MainActor
    func toggleContinuousListening() {
        guard let service = continuousAudioService else {
            print("🎙️ Continuous audio service not available")
            return
        }
        
        if isContinuousListening {
            service.stopContinuousMonitoring()
        } else {
            Task {
                do {
                    try await service.startContinuousMonitoring()
                } catch {
                    print("🎙️ Failed to start continuous monitoring: \(error)")
                    errorMessage = "Failed to start continuous listening: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - ContinuousAudioServiceDelegate

extension ChatViewModel: ContinuousAudioServiceDelegate {
    nonisolated func didCaptureVoiceSegment(audioURL: URL) {
        Task { @MainActor in
            print("🎙️ Voice segment captured, starting transcription: \(audioURL.lastPathComponent)")
            isTranscribing = true
            await transcribeAudio(from: audioURL)
        }
    }
    
    nonisolated func voiceActivityDidChange(isActive: Bool) {
        Task { @MainActor in
            self.isVoiceActive = isActive
            print("🎙️ Voice activity changed: \(isActive ? "active" : "silent")")
        }
    }
    
    nonisolated func continuousAudioDidEncounterError(_ error: Error) {
        Task { @MainActor in
            print("🎙️ Continuous audio error: \(error)")
            errorMessage = "Continuous listening error: \(error.localizedDescription)"
            
            // Stop continuous listening on error
            if isContinuousListening {
                continuousAudioService?.stopContinuousMonitoring()
            }
        }
    }
}
