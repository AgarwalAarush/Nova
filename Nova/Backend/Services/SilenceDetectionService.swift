//
//  SilenceDetectionService.swift
//  Nova
//
//  Implementation of RMS-based silence detection system
//  Based on Jarvis voice assistant silence detection algorithm
//

import Foundation
import AVFoundation

@MainActor
class SilenceDetectionService: ObservableObject {
    // MARK: - Configuration Constants
    
    /// Base RMS threshold for silence detection
    private let baseThreshold: Float = 0.005
    
    /// Minimum allowed adaptive threshold
    private let minThreshold: Float = 0.002
    
    /// Maximum allowed adaptive threshold
    private let maxThreshold: Float = 0.02
    
    /// Multiplier for adaptive threshold calculation
    private let adaptiveMultiplier: Float = 1.5
    
    /// Number of audio level samples in rolling window
    private let bufferSize: Int = 10
    
    /// Number of consecutive silence chunks before stopping recording
    private let silenceDurationBlocks: Int = 25
    
    // MARK: - State Variables
    
    /// Current adaptive threshold value
    @Published private(set) var adaptiveThreshold: Float
    
    /// Rolling window of recent audio levels
    private var audioLevelsBuffer: [Float] = []
    
    /// Counter for consecutive silence chunks
    private var silenceCounter: Int = 0
    
    /// Whether currently in recording/monitoring mode
    private var isMonitoring: Bool = false
    
    /// Debug mode for logging RMS values
    var debugEnabled: Bool = false
    
    // MARK: - Initialization
    
    init() {
        self.adaptiveThreshold = baseThreshold
    }
    
    // MARK: - Public Interface
    
    /// Calculate RMS (Root Mean Square) value for audio chunk
    /// - Parameter audioData: 16-bit PCM audio samples
    /// - Returns: RMS value in range 0.0 to 1.0
    func calculateRMS(from audioData: Data) -> Float {
        let samples = audioData.withUnsafeBytes { bytes in
            bytes.bindMemory(to: Int16.self)
        }
        
        guard !samples.isEmpty else { return 0.0 }
        
        // Convert 16-bit integers to normalized float32 (-1.0 to 1.0)
        var sum: Float = 0.0
        for sample in samples {
            let normalizedSample = Float(sample) / 32768.0
            sum += normalizedSample * normalizedSample
        }
        
        let mean = sum / Float(samples.count)
        return sqrt(mean)
    }
    
    /// Detect if audio chunk represents silence
    /// - Parameter audioChunk: Audio data to analyze
    /// - Returns: True if silence detected, false if voice activity
    func detectSilence(in audioChunk: Data) -> Bool {
        let rms = calculateRMS(from: audioChunk)
        
        // Update adaptive threshold if monitoring
        if isMonitoring {
            updateAdaptiveThreshold(with: rms)
        }
        
        // Choose threshold based on monitoring state
        let threshold = isMonitoring ? adaptiveThreshold : baseThreshold
        
        // Debug logging
        if debugEnabled && isMonitoring && silenceCounter % 10 == 0 {
            print("🔇 RMS: \(String(format: "%.4f", rms)), Threshold: \(String(format: "%.4f", threshold)), Counter: \(silenceCounter)")
        }
        
        return rms < threshold
    }
    
    /// Process silence detection result and update counter
    /// - Parameter isSilent: Result from detectSilence
    /// - Returns: True if silence duration exceeded (should stop recording)
    func processSilenceResult(_ isSilent: Bool) -> Bool {
        if isSilent {
            silenceCounter += 1
            return silenceCounter >= silenceDurationBlocks
        } else {
            silenceCounter = 0
            return false
        }
    }
    
    /// Start monitoring mode (enables adaptive threshold)
    func startMonitoring() {
        print("🔇 Starting silence detection monitoring")
        isMonitoring = true
        resetAdaptiveThreshold()
    }
    
    /// Stop monitoring mode
    func stopMonitoring() {
        print("🔇 Stopping silence detection monitoring")
        isMonitoring = false
        silenceCounter = 0
    }
    
    /// Reset adaptive threshold system
    func resetAdaptiveThreshold() {
        audioLevelsBuffer.removeAll()
        adaptiveThreshold = baseThreshold
        silenceCounter = 0
        print("🔇 Reset adaptive threshold to \(baseThreshold)")
    }
    
    /// Get current threshold value for debugging
    func getCurrentThreshold() -> Float {
        return isMonitoring ? adaptiveThreshold : baseThreshold
    }
    
    /// Get current silence counter for debugging
    func getSilenceCounter() -> Int {
        return silenceCounter
    }
    
    // MARK: - Private Methods
    
    /// Update adaptive threshold based on current RMS value
    /// - Parameter currentRMS: Current RMS value from audio
    private func updateAdaptiveThreshold(with currentRMS: Float) {
        // Add to rolling window
        audioLevelsBuffer.append(currentRMS)
        
        // Maintain buffer size
        if audioLevelsBuffer.count > bufferSize {
            audioLevelsBuffer.removeFirst()
        }
        
        // Calculate new threshold after sufficient samples
        if audioLevelsBuffer.count >= 5 {
            let avgLevel = audioLevelsBuffer.reduce(0, +) / Float(audioLevelsBuffer.count)
            let newThreshold = avgLevel * adaptiveMultiplier
            
            // Clamp to min/max bounds
            adaptiveThreshold = max(minThreshold, min(maxThreshold, newThreshold))
            
            if debugEnabled {
                print("🔇 Updated adaptive threshold: \(String(format: "%.4f", adaptiveThreshold)) (avg: \(String(format: "%.4f", avgLevel)))")
            }
        }
    }
}

// MARK: - Configuration Extension

extension SilenceDetectionService {
    /// Audio processing configuration that matches RMS documentation
    struct AudioConfig {
        static let sampleRate: Double = 16000.0
        static let chunkSize: Int = 1280  // 80ms chunks
        static let channels: Int = 1
        static let bitDepth: Int = 16
        
        /// Calculate chunk duration in seconds
        static var chunkDuration: Double {
            return Double(chunkSize) / sampleRate
        }
        
        /// Calculate silence duration in seconds
        static var silenceDuration: Double {
            return chunkDuration * Double(25) // 25 chunks ≈ 2 seconds
        }
    }
}