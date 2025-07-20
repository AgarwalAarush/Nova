//
//  WhisperService.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/11/25.
//

import Foundation
import SwiftUI
import Combine

/// Enum to track the current state of Whisper model loading
enum WhisperModelState {
    case notLoaded
    case loading(progress: Float)
    case loaded
    case failed(Error)
    
    var isReady: Bool {
        if case .loaded = self {
            return true
        }
        return false
    }
}

class WhisperService: AudioTranscriptionService, ObservableObject {
    private let client: WhisperClient
    private let configuration: WhisperConfiguration
    
    @Published var modelState: WhisperModelState = .notLoaded
    
    var currentModel: WhisperConfiguration.ModelSize
    let availableModels: [WhisperConfiguration.ModelSize] = WhisperConfiguration.ModelSize.allCases
    
    // Progress tracking
    private var progressCallbacks: [(WhisperProgress) -> Void] = []
    
    // Background loading task
    private var loadingTask: Task<Void, Never>?
    
    // Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    init(client: WhisperClient = WhisperClient(), 
         configuration: WhisperConfiguration = .shared) {
        self.client = client
        self.configuration = configuration
        self.currentModel = AppConfig.shared.whisperModelSize
        
        // Set up progress tracking
        self.client.addProgressCallback { [weak self] progress in
            self?.notifyProgress(progress)
            
            // Update model state based on progress
            if progress.type == .modelLoading {
                Task { @MainActor in
                    if progress.progress >= 1.0 {
                        self?.modelState = .loaded
                    } else {
                        self?.modelState = .loading(progress: progress.progress)
                    }
                }
            }
        }
        
        // Observe model changes from AppConfig
        AppConfig.shared.$whisperModelSize
            .sink { [weak self] newModelSize in
                Task { @MainActor in
                    self?.handleModelChange(to: newModelSize)
                }
            }
            .store(in: &cancellables)
        
        // Start background loading if enabled
        if AppConfig.shared.enableBackgroundLoading {
            startBackgroundModelLoading()
        }
    }
    
    deinit {
        loadingTask?.cancel()
    }
    
    // MARK: - Model Change Handling
    
    /// Handle model change from AppConfig
    @MainActor
    private func handleModelChange(to newModelSize: WhisperConfiguration.ModelSize) {
        print("🎤 Model changed from \(currentModel) to \(newModelSize)")
        
        // Skip if model hasn't actually changed
        guard newModelSize != currentModel else { return }
        
        // Cancel any ongoing loading
        loadingTask?.cancel()
        
        // Update current model
        currentModel = newModelSize
        
        // Reset model state
        modelState = .notLoaded
        
        // Start loading the new model if background loading is enabled
        if AppConfig.shared.enableBackgroundLoading {
            startBackgroundModelLoading()
        }
    }
    
    // MARK: - Background Model Loading
    
    /// Start loading the model in the background
    func startBackgroundModelLoading() {
        guard case .notLoaded = modelState else { return }
        
        print("🎤 Starting background model loading...")
        loadingTask = Task.detached(priority: .utility) { [weak self] in
            await self?.loadModelInBackground()
        }
    }
    
    private func loadModelInBackground() async {
        do {
            Task { @MainActor in
                self.modelState = .loading(progress: 0.0)
            }
            
            print("🎤 Background model loading started...")
            try await ensureModelReady()
            
            Task { @MainActor in
                self.modelState = .loaded
            }
            print("🎤 ✅ Background model loading completed successfully")
            
        } catch {
            print("🎤 ❌ Background model loading failed: \(error)")
            Task { @MainActor in
                self.modelState = .failed(error)
            }
        }
    }
    
    /// Wait for the model to be ready, loading it if necessary
    private func waitForModelReady() async throws {
        switch modelState {
        case .loaded:
            // Already ready
            return
            
        case .loading:
            // Wait for loading to complete
            print("🎤 Waiting for model loading to complete...")
            while case .loading = modelState {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
            
            // Check final state
            if case .failed(let error) = modelState {
                throw error
            }
            
        case .failed(let error):
            throw error
            
        case .notLoaded:
            // Start loading now
            print("🎤 Model not loaded, starting immediate load...")
            try await ensureModelReady()
        }
    }
    
    // MARK: - AudioTranscriptionService Implementation
    
    func transcribeAudio(input: WhisperAudioInput, 
                        request: WhisperTranscriptionRequest) async throws -> WhisperTranscriptionResponse {
        // Wait for model to be ready if it's still loading
        try await waitForModelReady()
        
        // Validate audio duration if converting from input
        if case .fileURL(_) = input {
            // We'll validate duration after conversion
        }
        
        do {
            // Convert audio input to PCM format required by Whisper
            let audioFrames = try await client.convertAudioToPCM(input)
            
            // Validate audio duration
            let duration = Double(audioFrames.count) / Double(configuration.audioSampleRate)
            if duration > configuration.maxAudioDurationSeconds {
                throw AIServiceError.audioTooLong
            }
            
            // Create the request with converted audio data
            let transcriptionRequest = WhisperTranscriptionRequest(
                audioData: audioFrames,
                language: request.language,
                task: request.task,
                temperature: request.temperature,
                wordTimestamps: request.wordTimestamps
            )
            
            // Perform transcription
            let response = try await client.transcribe(request: transcriptionRequest)
            
            return response
            
        } catch let error as WhisperError {
            // Convert WhisperError to AIServiceError
            throw mapWhisperError(error)
        } catch let error as AIServiceError {
            throw error
        } catch {
            throw AIServiceError.audioProcessingFailed(error)
        }
    }
    
    func downloadModel(_ modelSize: WhisperConfiguration.ModelSize) async throws {
        do {
            try await client.downloadModel(modelSize)
        } catch let error as WhisperError {
            throw mapWhisperError(error)
        } catch {
            throw AIServiceError.modelDownloadFailed(error)
        }
    }
    
    func isModelAvailable(_ modelSize: WhisperConfiguration.ModelSize) -> Bool {
        #if canImport(SwiftWhisper)
        return self.client.isModelAvailable(modelSize)
        #else
        // Mock implementation - always return true for testing
        return true
        #endif
    }
    
    func getModelStatus(_ modelSize: WhisperConfiguration.ModelSize) -> WhisperModelStatus {
        #if canImport(SwiftWhisper)
        return self.client.getModelStatus(modelSize)
        #else
        // Mock implementation
        return .downloaded
        #endif
    }
    
    // MARK: - High-level Convenience Methods
    
    /// Transcribe audio file with automatic format detection
    func transcribeFile(at url: URL, 
                       language: String? = nil,
                       task: WhisperTask = .transcribe) async throws -> WhisperTranscriptionResponse {
        let input = WhisperAudioInput.fileURL(url)
        let request = WhisperTranscriptionRequest(
            audioData: [], // Will be populated by convertAudioToPCM
            language: language,
            task: task,
            temperature: 0.0,
            wordTimestamps: false
        )
        
        return try await transcribeAudio(input: input, request: request)
    }
    
    /// Transcribe audio data with specified format
    func transcribeData(_ data: Data, 
                       format: AudioFormat,
                       language: String? = nil,
                       task: WhisperTask = .transcribe) async throws -> WhisperTranscriptionResponse {
        let input = WhisperAudioInput.data(data, format: format)
        let request = WhisperTranscriptionRequest(
            audioData: [], // Will be populated by convertAudioToPCM
            language: language,
            task: task,
            temperature: 0.0,
            wordTimestamps: false
        )
        
        return try await transcribeAudio(input: input, request: request)
    }
    
    /// Transcribe pre-processed audio frames (16kHz PCM)
    func transcribeFrames(_ audioFrames: [Float],
                         language: String? = nil,
                         task: WhisperTask = .transcribe,
                         wordTimestamps: Bool = false) async throws -> WhisperTranscriptionResponse {
        let input = WhisperAudioInput.audioFrames(audioFrames)
        let request = WhisperTranscriptionRequest(
            audioData: audioFrames,
            language: language,
            task: task,
            temperature: 0.0,
            wordTimestamps: wordTimestamps
        )
        
        return try await transcribeAudio(input: input, request: request)
    }
    
    // MARK: - Model Management
    
    /// Switch to a different model size
    func switchModel(to modelSize: WhisperConfiguration.ModelSize) async throws {
        currentModel = modelSize
        modelState = .notLoaded
        
        // Download model if not available
        if !isModelAvailable(modelSize) {
            try await downloadModel(modelSize)
        }
        
        // Load the model
        try await loadCurrentModel()
    }
    
    /// Ensure the current model is downloaded and loaded
    func ensureModelReady() async throws {
        #if canImport(SwiftWhisper)
        if !isModelAvailable(currentModel) {
            try await downloadModel(currentModel)
        }
        
        try await ensureModelLoaded()
        #else
        // Mock implementation when SwiftWhisper is not available
        print("🎤 Using mock model - SwiftWhisper not configured")
        modelState = .loaded
        #endif
    }
    
    /// Get available disk space for model downloads
    func getAvailableDiskSpace() -> Int64? {
        do {
            let resourceValues = try configuration.modelsDirectory.resourceValues(forKeys: [.volumeAvailableCapacityKey])
            return resourceValues.volumeAvailableCapacity.map { Int64($0) }
        } catch {
            return nil
        }
    }
    
    /// Get size of downloaded models on disk
    func getModelsSizeOnDisk() -> Int64 {
        do {
            let modelFiles = try FileManager.default.contentsOfDirectory(
                at: configuration.modelsDirectory,
                includingPropertiesForKeys: [.fileSizeKey],
                options: []
            )
            
            var totalSize: Int64 = 0
            for url in modelFiles {
                let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
                totalSize += Int64(resourceValues.fileSize ?? 0)
            }
            
            return totalSize
        } catch {
            return 0
        }
    }
    
    /// Delete a specific model from disk
    func deleteModel(_ modelSize: WhisperConfiguration.ModelSize) throws {
        let modelURL = configuration.modelURL(for: modelSize.rawValue)
        if FileManager.default.fileExists(atPath: modelURL.path) {
            try FileManager.default.removeItem(at: modelURL)
        }
        
        if currentModel == modelSize {
            modelState = .notLoaded
        }
    }
    
    // MARK: - Progress Tracking
    
    func addProgressCallback(_ callback: @escaping (WhisperProgress) -> Void) {
        progressCallbacks.append(callback)
    }
    
    func removeAllProgressCallbacks() {
        progressCallbacks.removeAll()
    }
    
    // MARK: - Private Helpers
    
    private func ensureModelLoaded() async throws {
        print("🎤 ensureModelLoaded() called - modelState: \(modelState)")
        
        #if canImport(SwiftWhisper)
        if !modelState.isReady {
            print("🎤 Model not loaded, calling loadCurrentModel()")
            try await loadCurrentModel()
        } else {
            print("🎤 Model already loaded")
        }
        #else
        // Mock implementation when SwiftWhisper is not available
        print("🎤 Using mock implementation - SwiftWhisper not available")
        Task { @MainActor in
            modelState = .loaded
        }
        #endif
    }
    
    private func loadCurrentModel() async throws {
        print("🎤 loadCurrentModel() called with currentModel: \(currentModel)")
        
        #if canImport(SwiftWhisper)
        do {
            Task { @MainActor in
                modelState = .loading(progress: 0.0)
            }
            
            print("🎤 Calling client.loadModel(\(currentModel))")
            try await client.loadModel(currentModel)
            
            Task { @MainActor in
                modelState = .loaded
            }
            print("🎤 Model loaded successfully")
        } catch let error as WhisperError {
            print("🎤 WhisperError occurred: \(error)")
            let mappedError = mapWhisperError(error)
            Task { @MainActor in
                modelState = .failed(mappedError)
            }
            throw mappedError
        } catch {
            print("🎤 Other error occurred: \(error)")
            let serviceError = AIServiceError.modelNotFound
            Task { @MainActor in
                modelState = .failed(serviceError)
            }
            throw serviceError
        }
        #else
        // Mock implementation when SwiftWhisper is not available
        print("🎤 Loading mock model (SwiftWhisper not available)")
        Task { @MainActor in
            modelState = .loaded
        }
        #endif
    }
    
    private func mapWhisperError(_ error: WhisperError) -> AIServiceError {
        switch error {
        case .modelNotFound:
            return .modelNotFound
        case .modelLoadFailed(let underlying):
            return .modelDownloadFailed(underlying)
        case .audioProcessingFailed(let underlying):
            return .audioProcessingFailed(underlying)
        case .transcriptionFailed(let underlying):
            return .audioProcessingFailed(underlying)
        case .invalidAudioFormat:
            return .audioFormatUnsupported
        case .audioTooLong:
            return .audioTooLong
        case .downloadFailed(let underlying):
            return .modelDownloadFailed(underlying)
        case .fileNotFound:
            return .audioProcessingFailed(error)
        }
    }
    
    private func notifyProgress(_ progress: WhisperProgress) {
        DispatchQueue.main.async {
            self.progressCallbacks.forEach { $0(progress) }
        }
    }
}

// MARK: - Convenience Extensions

extension WhisperService {
    /// Quick transcription with automatic model setup
    static func quickTranscribe(fileURL: URL, 
                               language: String? = nil) async throws -> String {
        let service = WhisperService()
        try await service.ensureModelReady()
        let response = try await service.transcribeFile(at: fileURL, language: language)
        return response.fullText
    }
    
    /// Transcribe and return segments with timestamps
    func transcribeWithTimestamps(fileURL: URL,
                                 language: String? = nil) async throws -> [WhisperSegment] {
        let response = try await transcribeFile(at: fileURL, language: language)
        return response.segments
    }
    
    /// Detect language of audio file
    func detectLanguage(fileURL: URL) async throws -> String? {
        let response = try await transcribeFile(at: fileURL)
        return response.detectedLanguage
    }
} 