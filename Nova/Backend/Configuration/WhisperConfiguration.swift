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
        self.defaultModelName = "base"
        
        // Store models in Documents/WhisperModels directory
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
        modelsDirectory.appendingPathComponent("\(defaultModelName).bin")
    }
    
    func modelURL(for modelName: String) -> URL {
        modelsDirectory.appendingPathComponent("\(modelName).bin")
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