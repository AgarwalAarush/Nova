//
//  WhisperClient.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/11/25.
//

import Foundation
import AVFoundation
// NOTE: SwiftWhisper must be added as a Swift Package Manager dependency
// Add: https://github.com/exPHAT/SwiftWhisper.git to your project dependencies
#if canImport(SwiftWhisper)
import SwiftWhisper
#endif

// Mock classes for when SwiftWhisper is not available
#if !canImport(SwiftWhisper)
class WhisperProgressDelegate {
    let progressCallback: (Double) -> Void
    
    init(progressCallback: @escaping (Double) -> Void) {
        self.progressCallback = progressCallback
    }
}

class Whisper {
    var delegate: WhisperProgressDelegate?
    
    init(fromFileURL url: URL) throws {
        // Mock initialization
    }
    
    func transcribe(audioFrames: [Float]) async throws -> [MockWhisperSegment] {
        // Mock transcription
        return [MockWhisperSegment(text: "Mock transcription result", startTime: 0.0, endTime: 1.0)]
    }
}

struct MockWhisperSegment {
    let text: String
    let startTime: Float
    let endTime: Float
}
#endif

class WhisperClient: @unchecked Sendable {
    private let configuration: WhisperConfiguration
    private var whisperInstance: Whisper?
    private let session: URLSession
    private var modelDownloadTasks: [String: URLSessionDownloadTask] = [:]
    
    // Progress tracking
    private var progressCallbacks: [(WhisperProgress) -> Void] = []
    
    init(configuration: WhisperConfiguration = .shared) {
        self.configuration = configuration
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 120.0  // Longer timeout for model downloads
        sessionConfig.timeoutIntervalForResource = 600.0
        self.session = URLSession(configuration: sessionConfig)
    }
    
    deinit {
        // Cancel any ongoing downloads
        modelDownloadTasks.values.forEach { $0.cancel() }
    }
    
    // MARK: - Model Management
    
    func loadModel(_ modelSize: WhisperConfiguration.ModelSize) async throws {
        print("🎤 loadModel called with modelSize: \(modelSize)")
        print("🎤 Looking for model: \(configuration.defaultModelName)")
        
        // Debug: List what's in the bundle
        if let bundlePath = Bundle.main.resourcePath {
            print("🎤 Bundle resource path: \(bundlePath)")
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: bundlePath)
                let binFiles = contents.filter { $0.hasSuffix(".bin") }
                print("🎤 .bin files in bundle: \(binFiles)")
                
                // Also check for the specific file we're looking for
                let targetFile = "\(configuration.defaultModelName).bin"
                let fileExists = contents.contains(targetFile)
                print("🎤 Looking for '\(targetFile)' - exists: \(fileExists)")
            } catch {
                print("🎤 Error listing bundle contents: \(error)")
            }
        }
        
        // Try multiple possible model names and locations in the bundle
        let possibleNames = ["ggml-small", "model", "base", "small"]
        let possiblePaths = ["Resources/Models/", ""]
        var foundModelURL: URL?
        
        for path in possiblePaths {
            for modelName in possibleNames {
                let resourceName = path.isEmpty ? modelName : "\(path)\(modelName)"
                if let bundleModelURL = Bundle.main.url(forResource: resourceName, withExtension: "bin") {
                    print("🎤 ✅ Found .bin model in app bundle: \(resourceName).bin at \(bundleModelURL.path)")
                    foundModelURL = bundleModelURL
                    break
                } else {
                    print("🎤 ❌ No \(resourceName).bin found in bundle")
                }
            }
            if foundModelURL != nil { break }
        }
        
        // If found a model in bundle, try to load it
        if let bundleModelURL = foundModelURL {
            print("🎤 Loading .bin model from app bundle...")
            notifyProgress(.init(type: .modelLoading, progress: 0.0, message: "Loading model..."))
            
            #if canImport(SwiftWhisper)
            print("🎤 SwiftWhisper is available, attempting to load...")
            do {
                whisperInstance = try Whisper(fromFileURL: bundleModelURL)
                print("🎤 ✅ SwiftWhisper model loaded successfully!")
                notifyProgress(.init(type: .modelLoading, progress: 1.0, message: "Model loaded successfully"))
                return
            } catch {
                print("🎤 ❌ Failed to load SwiftWhisper model: \(error)")
                throw WhisperError.modelLoadFailed(error)
            }
            #else
            print("🎤 SwiftWhisper not available, using mock loading")
            // Mock loading when SwiftWhisper isn't available but model file exists
            try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            notifyProgress(.init(type: .modelLoading, progress: 1.0, message: "Mock model loaded from bundle"))
            return
            #endif
        } else {
            print("🎤 ❌ No .bin models found in app bundle")
        }
        
        // Then try Core ML model from app bundle
        if Bundle.main.url(forResource: configuration.coreMLModelName, withExtension: "mlmodelc") != nil {
            print("🎤 Using Core ML model from app bundle: \(configuration.coreMLModelName)")
            notifyProgress(.init(type: .modelLoading, progress: 0.0, message: "Loading Core ML model..."))
            
            // For Core ML, we don't need to "load" the model in the same way
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            notifyProgress(.init(type: .modelLoading, progress: 1.0, message: "Core ML model ready"))
            return
        }
        
        #if canImport(SwiftWhisper)
        // Finally try models from Documents directory
        let modelURL = configuration.modelURL(for: modelSize.rawValue)
        
        guard FileManager.default.fileExists(atPath: modelURL.path) else {
            throw WhisperError.modelNotFound(modelSize.rawValue)
        }
        
        notifyProgress(.init(type: .modelLoading, progress: 0.0, message: "Loading \(modelSize.displayName)..."))
        
        do {
            whisperInstance = try Whisper(fromFileURL: modelURL)
        } catch {
            throw WhisperError.modelLoadFailed(error)
        }
        
        notifyProgress(.init(type: .modelLoading, progress: 1.0, message: "Model loaded successfully"))
        #else
        // Mock model loading for when SwiftWhisper is not available
        print("🎤 No models available, using mock implementation")
        notifyProgress(.init(type: .modelLoading, progress: 0.0, message: "Mock loading \(modelSize.displayName)..."))
        
        // Simulate loading time
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        notifyProgress(.init(type: .modelLoading, progress: 1.0, message: "Mock model loaded successfully"))
        #endif
    }
    
    func isModelAvailable(_ modelSize: WhisperConfiguration.ModelSize) -> Bool {
        // First check for .bin model in app bundle
        if Bundle.main.url(forResource: configuration.defaultModelName, withExtension: "bin") != nil {
            print("🎤 Found .bin model in app bundle: \(configuration.defaultModelName).bin")
            return true
        }
        
        // Then check for Core ML model in app bundle
        if Bundle.main.url(forResource: configuration.coreMLModelName, withExtension: "mlmodelc") != nil {
            print("🎤 Found Core ML model in app bundle: \(configuration.coreMLModelName).mlmodelc")
            return true
        }
        
        #if canImport(SwiftWhisper)
        // Finally check for ggml model files in Documents
        let modelURL = configuration.modelURL(for: modelSize.rawValue)
        let exists = FileManager.default.fileExists(atPath: modelURL.path)
        print("🎤 Checking Documents directory for model: \(modelURL.path) - exists: \(exists)")
        return exists
        #else
        // Mock implementation - always return true for testing
        print("🎤 Using mock implementation - no SwiftWhisper")
        return true
        #endif
    }
    
    func getModelStatus(_ modelSize: WhisperConfiguration.ModelSize) -> WhisperModelStatus {
        #if canImport(SwiftWhisper)
        // Check if currently downloading
        if let task = modelDownloadTasks[modelSize.rawValue] {
            let progress = Float(task.progress.fractionCompleted)
            return .downloading(progress: progress)
        }
        
        // Check if available on disk
        if isModelAvailable(modelSize) {
            // Check if currently loaded
            if whisperInstance != nil {
                return .loaded
            } else {
                return .downloaded
            }
        }
        
        return .notDownloaded
        #else
        // Mock implementation
        return .downloaded
        #endif
    }
    
    func downloadModel(_ modelSize: WhisperConfiguration.ModelSize) async throws {
        let modelURL = configuration.modelURL(for: modelSize.rawValue)
        let downloadURL = modelSize.downloadURL
        
        // Check if model already exists
        if FileManager.default.fileExists(atPath: modelURL.path) {
            return
        }
        
        // Cancel any existing download for this model
        modelDownloadTasks[modelSize.rawValue]?.cancel()
        
        return try await withCheckedThrowingContinuation { continuation in
            var observation: NSKeyValueObservation?
            
            let task = session.downloadTask(with: downloadURL) { tempURL, response, error in
                defer {
                    Task { @MainActor in
                        self.modelDownloadTasks[modelSize.rawValue] = nil
                    }
                    observation?.invalidate()
                }
                
                if let error = error {
                    continuation.resume(throwing: WhisperError.downloadFailed(error))
                    return
                }
                
                guard let tempURL = tempURL else {
                    continuation.resume(throwing: WhisperError.downloadFailed(
                        NSError(domain: "WhisperClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "No download URL"])
                    ))
                    return
                }
                
                do {
                    // Ensure models directory exists
                    let modelsDir = modelURL.deletingLastPathComponent()
                    try FileManager.default.createDirectory(at: modelsDir, withIntermediateDirectories: true)
                    
                    // Remove existing file if it exists
                    if FileManager.default.fileExists(atPath: modelURL.path) {
                        try FileManager.default.removeItem(at: modelURL)
                    }
                    
                    // Move downloaded file to final location
                    try FileManager.default.moveItem(at: tempURL, to: modelURL)
                    
                    Task { @MainActor in
                        self.notifyProgress(.init(type: .modelDownload, progress: 1.0, 
                                                message: "\(modelSize.displayName) downloaded successfully"))
                    }
                    
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: WhisperError.downloadFailed(error))
                }
            }
            
            // Track download progress
            observation = task.progress.observe(\.fractionCompleted) { progress, _ in
                let progressValue = Float(progress.fractionCompleted)
                Task { @MainActor in
                    self.notifyProgress(.init(type: .modelDownload, progress: progressValue,
                                           message: "Downloading \(modelSize.displayName)... \(Int(progressValue * 100))%"))
                }
            }
            
            modelDownloadTasks[modelSize.rawValue] = task
            task.resume()
        }
    }
    
    // MARK: - Audio Transcription
    
    func transcribe(request: WhisperTranscriptionRequest) async throws -> WhisperTranscriptionResponse {
        #if canImport(SwiftWhisper)
        guard let whisper = whisperInstance else {
            throw WhisperError.modelNotFound("No model loaded")
        }
        
        let startTime = Date()
        
        do {
            notifyProgress(.init(type: .transcription, progress: 0.0, message: "Starting transcription..."))
            
            // Set up whisper delegate if needed for progress tracking
            whisper.delegate = WhisperProgressDelegate { progress in
                Task { @MainActor in
                    self.notifyProgress(.init(type: .transcription, progress: Float(progress), 
                                            message: "Transcribing... \(Int(progress * 100))%"))
                }
            }
            
            // Perform transcription
            let segments = try await whisper.transcribe(audioFrames: request.audioData)
            
            let processingTime = Date().timeIntervalSince(startTime)
            let duration = Double(request.audioData.count) / Double(configuration.audioSampleRate)
            
            // Convert segments to our model
            let whisperSegments = segments.enumerated().map { index, segment in
                WhisperSegment(
                    id: index,
                    text: segment.text,
                    startTime: TimeInterval(segment.startTime),
                    endTime: TimeInterval(segment.endTime),
                    confidence: 1.0,
                    words: nil
                )
            }
            
            notifyProgress(.init(type: .transcription, progress: 1.0, message: "Transcription completed"))
            
            return WhisperTranscriptionResponse(
                segments: whisperSegments,
                detectedLanguage: request.language,
                duration: duration,
                processingTime: processingTime
            )
            
        } catch {
            throw WhisperError.transcriptionFailed(error)
        }
        #else
        // Fallback implementation for when SwiftWhisper is not available
        print("🎤 SwiftWhisper not available, using fallback mock transcription")
        
        let startTime = Date()
        notifyProgress(.init(type: .transcription, progress: 0.0, message: "Starting mock transcription..."))
        
        // Simulate processing time
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        notifyProgress(.init(type: .transcription, progress: 0.5, message: "Processing audio..."))
        
        // Simulate more processing
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        let processingTime = Date().timeIntervalSince(startTime)
        let duration = Double(request.audioData.count) / Double(configuration.audioSampleRate)
        
        // Create mock transcription result
        let mockSegment = WhisperSegment(
            id: 0,
            text: "Hello, this is a test transcription since SwiftWhisper is not configured.",
            startTime: 0.0,
            endTime: duration,
            confidence: 1.0,
            words: nil
        )
        
        notifyProgress(.init(type: .transcription, progress: 1.0, message: "Mock transcription completed"))
        
        return WhisperTranscriptionResponse(
            segments: [mockSegment],
            detectedLanguage: request.language ?? "en",
            duration: duration,
            processingTime: processingTime
        )
        #endif
    }
    
    // MARK: - Audio Processing
    
    func convertAudioToPCM(_ input: WhisperAudioInput) async throws -> [Float] {
        switch input {
        case .audioFrames(let frames):
            return frames
            
        case .fileURL(let url):
            return try await convertAudioFileToPCM(url: url)
            
        case .data(let data, let format):
            // For data conversion, we'd need to write to a temporary file first
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(format.fileExtension)
            
            try data.write(to: tempURL)
            defer { try? FileManager.default.removeItem(at: tempURL) }
            
            return try await convertAudioFileToPCM(url: tempURL)
        }
    }
    
    private func convertAudioFileToPCM(url: URL) async throws -> [Float] {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw WhisperError.fileNotFound(url)
        }
        
        print("🎤 Converting audio file to 16kHz PCM using AVAudioConverter: \(url.path)")
        
        do {
            let inputFile = try AVAudioFile(forReading: url)
            let inputFormat = inputFile.processingFormat
            
            print("🎤 Input format: \(inputFormat.sampleRate)Hz, \(inputFormat.channelCount) channels")
            
            // Create target format: 16kHz, mono, float32
            guard let outputFormat = AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: 16000,
                channels: 1,
                interleaved: false
            ) else {
                throw WhisperError.audioProcessingFailed(
                    NSError(domain: "WhisperClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create output format"])
                )
            }
            
            print("🎤 Target format: \(outputFormat.sampleRate)Hz, \(outputFormat.channelCount) channels")
            
            // Create converter
            guard let converter = AVAudioConverter(from: inputFormat, to: outputFormat) else {
                throw WhisperError.audioProcessingFailed(
                    NSError(domain: "WhisperClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create audio converter"])
                )
            }
            
            // Calculate output buffer size
            let inputFrameCount = AVAudioFrameCount(inputFile.length)
            let outputFrameCount = AVAudioFrameCount(Double(inputFrameCount) * outputFormat.sampleRate / inputFormat.sampleRate)
            
            print("🎤 Converting \(inputFrameCount) frames to \(outputFrameCount) frames")
            
            // Create buffers
            guard let inputBuffer = AVAudioPCMBuffer(pcmFormat: inputFormat, frameCapacity: inputFrameCount),
                  let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: outputFrameCount) else {
                throw WhisperError.audioProcessingFailed(
                    NSError(domain: "WhisperClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create audio buffers"])
                )
            }
            
            // Read input file
            try inputFile.read(into: inputBuffer)
            inputBuffer.frameLength = inputFrameCount
            
            // Convert audio
            var error: NSError?
            let status = converter.convert(to: outputBuffer, error: &error) { inNumPackets, outStatus in
                outStatus.pointee = .haveData
                return inputBuffer
            }
            
            if status == .error {
                throw WhisperError.audioProcessingFailed(error ?? 
                    NSError(domain: "WhisperClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Audio conversion failed"])
                )
            }
            
            // Extract float samples
            guard let floatChannelData = outputBuffer.floatChannelData else {
                throw WhisperError.audioProcessingFailed(
                    NSError(domain: "WhisperClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get float channel data"])
                )
            }
            
            let frameLength = Int(outputBuffer.frameLength)
            let samples = Array(UnsafeBufferPointer(start: floatChannelData[0], count: frameLength))
            
            print("🎤 ✅ Audio conversion complete: \(samples.count) samples at 16kHz")
            return samples
            
        } catch {
            print("🎤 ❌ Audio conversion failed: \(error)")
            throw WhisperError.audioProcessingFailed(error)
        }
    }
    
    
    // MARK: - Progress Tracking
    
    func addProgressCallback(_ callback: @escaping (WhisperProgress) -> Void) {
        progressCallbacks.append(callback)
    }
    
    private func notifyProgress(_ progress: WhisperProgress) {
        DispatchQueue.main.async {
            self.progressCallbacks.forEach { $0(progress) }
        }
    }
}

// MARK: - WhisperProgressDelegate

private class WhisperProgressDelegate: WhisperDelegate {
    private let progressCallback: (Double) -> Void
    
    init(progressCallback: @escaping (Double) -> Void) {
        self.progressCallback = progressCallback
    }
    
    func whisper(_ aWhisper: Whisper, didUpdateProgress progress: Double) {
        progressCallback(progress)
    }
    
    func whisper(_ aWhisper: Whisper, didProcessNewSegments segments: [Segment], atIndex index: Int) {
        // Handle new segments if needed
    }
    
    func whisper(_ aWhisper: Whisper, didCompleteWithSegments segments: [Segment]) {
        progressCallback(1.0)
    }
    
    func whisper(_ aWhisper: Whisper, didErrorWith error: Error) {
        // Handle errors if needed
    }
} 