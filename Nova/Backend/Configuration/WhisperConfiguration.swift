//
//  WhisperConfiguration.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/11/25.
//

import Foundation

struct WhisperConfiguration {
    static let shared = WhisperConfiguration()
    
    let defaultModelName: String
    let modelsDirectory: URL
    let audioSampleRate: Int
    let audioChannels: Int
    let maxAudioDurationSeconds: Double
    
    private init() {
        self.defaultModelName = "ggml-small"
        
        // For Core ML models in app bundle, we don't need a separate directory
        // But we'll keep this for compatibility
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.modelsDirectory = documentsPath.appendingPathComponent("WhisperModels", isDirectory: true)
        
        // Audio configuration for Whisper
        self.audioSampleRate = 16000  // Whisper requires 16kHz
        self.audioChannels = 1        // Mono audio
        self.maxAudioDurationSeconds = 30.0 * 60.0  // 30 minutes max
        
        // Ensure models directory exists
        try? FileManager.default.createDirectory(at: modelsDirectory, withIntermediateDirectories: true)
    }
    
    var defaultModelURL: URL {
        // First try to get .bin model from Resources/Models in app bundle
        if let bundleURL = Bundle.main.url(forResource: "Resources/Models/\(defaultModelName)", withExtension: "bin") {
            return bundleURL
        }
        // Try direct path in bundle
        if let bundleURL = Bundle.main.url(forResource: defaultModelName, withExtension: "bin") {
            return bundleURL
        }
        // Then try Core ML models in Resources/Models
        if let bundleURL = Bundle.main.url(forResource: "Resources/Models/\(defaultModelName)", withExtension: "mlmodelc") {
            return bundleURL
        }
        // Try direct Core ML path
        if let bundleURL = Bundle.main.url(forResource: defaultModelName, withExtension: "mlmodelc") {
            return bundleURL
        }
        // Fallback to Documents directory
        return modelsDirectory.appendingPathComponent("\(defaultModelName).bin")
    }
    
    func modelURL(for modelName: String) -> URL {
        // First try to get .bin model from Resources/Models in app bundle
        if let bundleURL = Bundle.main.url(forResource: "Resources/Models/\(modelName)", withExtension: "bin") {
            return bundleURL
        }
        // Try direct path in bundle
        if let bundleURL = Bundle.main.url(forResource: modelName, withExtension: "bin") {
            return bundleURL
        }
        // Then try Core ML models in Resources/Models
        if let bundleURL = Bundle.main.url(forResource: "Resources/Models/\(modelName)", withExtension: "mlmodelc") {
            return bundleURL
        }
        // Try direct Core ML path
        if let bundleURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") {
            return bundleURL
        }
        // Fallback to Documents directory
        return modelsDirectory.appendingPathComponent("\(modelName).bin")
    }
    
    /// Get Core ML model name for the bundled model
    var coreMLModelName: String {
        return defaultModelName
    }
    
    // Available model configurations
    enum ModelSize: String, CaseIterable {
        case tiny = "tiny"
        case base = "base"
        case small = "small"
        case medium = "medium"
        case large = "large"
        
        var displayName: String {
            switch self {
            case .tiny: return "Tiny (~39 MB)"
            case .base: return "Base (~142 MB)"
            case .small: return "Small (~488 MB)"
            case .medium: return "Medium (~1.5 GB)"
            case .large: return "Large (~2.9 GB)"
            }
        }
        
        var downloadURL: URL {
            return URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-\(rawValue).bin")!
        }
    }
} 