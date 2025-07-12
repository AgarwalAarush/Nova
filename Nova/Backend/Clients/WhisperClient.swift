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
import SwiftWhisper

class WhisperClient {
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
    
    func isModelAvailable(_ modelSize: WhisperConfiguration.ModelSize) -> Bool {
        let modelURL = configuration.modelURL(for: modelSize.rawValue)
        return FileManager.default.fileExists(atPath: modelURL.path)
    }
    
    func getModelStatus(_ modelSize: WhisperConfiguration.ModelSize) -> WhisperModelStatus {
        if let task = modelDownloadTasks[modelSize.rawValue] {
            let progress = Float(task.progress.fractionCompleted)
            return .downloading(progress: progress)
        }
        
        if isModelAvailable(modelSize) {
            if whisperInstance != nil && modelSize.rawValue == configuration.defaultModelName {
                return .loaded
            } else {
                return .downloaded
            }
        }
        
        return .notDownloaded
    }
    
    // MARK: - Audio Transcription
    
    func transcribe(request: WhisperTranscriptionRequest) async throws -> WhisperTranscriptionResponse {
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
            
            // Convert SwiftWhisper segments to our model
            let whisperSegments = segments.enumerated().map { index, segment in
                WhisperSegment(
                    id: index,
                    text: segment.text,
                    startTime: TimeInterval(segment.startTime),
                    endTime: TimeInterval(segment.endTime),
                    confidence: 1.0, // SwiftWhisper doesn't provide confidence scores
                    words: nil // Word-level timestamps would need additional processing
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
        
        do {
            let audioFile = try AVAudioFile(forReading: url)
            let format = audioFile.processingFormat
            
            let frameCount = AVAudioFrameCount(audioFile.length)
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
            
            try audioFile.read(into: buffer)
            
            // Convert to 16kHz mono if needed
            if format.sampleRate != Double(configuration.audioSampleRate) || format.channelCount != 1 {
                return try await resampleAudio(buffer: buffer)
            }
            
            // Convert to Float array
            guard let floatChannelData = buffer.floatChannelData else {
                throw WhisperError.audioProcessingFailed(
                    NSError(domain: "WhisperClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get audio channel data"])
                )
            }
            
            let frameLength = Int(buffer.frameLength)
            let samples = Array(UnsafeBufferPointer(start: floatChannelData[0], count: frameLength))
            
            return samples
            
        } catch {
            throw WhisperError.audioProcessingFailed(error)
        }
    }
    
    private func resampleAudio(buffer: AVAudioPCMBuffer) async throws -> [Float] {
        // This is a simplified resampling approach
        // In production, you'd want to use AVAudioConverter for proper resampling
        let originalSampleRate = buffer.format.sampleRate
        let targetSampleRate = Double(configuration.audioSampleRate)
        
        guard let floatChannelData = buffer.floatChannelData else {
            throw WhisperError.audioProcessingFailed(
                NSError(domain: "WhisperClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get audio channel data"])
            )
        }
        
        let frameLength = Int(buffer.frameLength)
        let originalSamples = Array(UnsafeBufferPointer(start: floatChannelData[0], count: frameLength))
        
        if originalSampleRate == targetSampleRate {
            return originalSamples
        }
        
        // Simple linear interpolation resampling (for production, use AVAudioConverter)
        let ratio = originalSampleRate / targetSampleRate
        let newSampleCount = Int(Double(originalSamples.count) / ratio)
        var resampledSamples: [Float] = []
        resampledSamples.reserveCapacity(newSampleCount)
        
        for i in 0..<newSampleCount {
            let originalIndex = Double(i) * ratio
            let lowerIndex = Int(floor(originalIndex))
            let upperIndex = min(lowerIndex + 1, originalSamples.count - 1)
            let fraction = Float(originalIndex - Double(lowerIndex))
            
            let interpolatedValue = originalSamples[lowerIndex] * (1.0 - fraction) + 
                                  originalSamples[upperIndex] * fraction
            resampledSamples.append(interpolatedValue)
        }
        
        return resampledSamples
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