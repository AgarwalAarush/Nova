//
//  WhisperModels.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/11/25.
//

import Foundation

// MARK: - Transcription Request
struct WhisperTranscriptionRequest {
    let audioData: [Float]  // 16kHz PCM audio frames
    let language: String?   // Optional language hint (e.g., "en", "es", "fr")
    let task: WhisperTask   // transcribe or translate
    let temperature: Float  // Temperature for sampling (0.0 to 1.0)
    let wordTimestamps: Bool // Whether to return word-level timestamps
    
    init(audioData: [Float], 
         language: String? = nil, 
         task: WhisperTask = .transcribe, 
         temperature: Float = 0.0,
         wordTimestamps: Bool = false) {
        self.audioData = audioData
        self.language = language
        self.task = task
        self.temperature = temperature
        self.wordTimestamps = wordTimestamps
    }
}

// MARK: - Transcription Response
struct WhisperTranscriptionResponse {
    let segments: [WhisperSegment]
    let detectedLanguage: String?
    let duration: TimeInterval
    let processingTime: TimeInterval
    
    var fullText: String {
        segments.map { $0.text }.joined(separator: " ")
    }
}

// MARK: - Transcription Segment
struct WhisperSegment {
    let id: Int
    let text: String
    let startTime: TimeInterval
    let endTime: TimeInterval
    let confidence: Float
    let words: [WhisperWord]?
    
    var duration: TimeInterval {
        endTime - startTime
    }
}

// MARK: - Word-level Timestamps
struct WhisperWord {
    let text: String
    let startTime: TimeInterval
    let endTime: TimeInterval
    let confidence: Float
}

// MARK: - Transcription Task
enum WhisperTask: String, CaseIterable {
    case transcribe = "transcribe"  // Transcribe in original language
    case translate = "translate"    // Translate to English
    
    var displayName: String {
        switch self {
        case .transcribe: return "Transcribe"
        case .translate: return "Translate to English"
        }
    }
}

// MARK: - Audio Input Types
enum WhisperAudioInput {
    case fileURL(URL)
    case audioFrames([Float])
    case data(Data, format: AudioFormat)
}

enum AudioFormat: String, CaseIterable {
    case wav = "wav"
    case mp3 = "mp3"
    case m4a = "m4a"
    case flac = "flac"
    case aac = "aac"
    
    var fileExtension: String {
        return rawValue
    }
    
    var mimeType: String {
        switch self {
        case .wav: return "audio/wav"
        case .mp3: return "audio/mpeg"
        case .m4a: return "audio/mp4"
        case .flac: return "audio/flac"
        case .aac: return "audio/aac"
        }
    }
}

// MARK: - Model Status
enum WhisperModelStatus {
    case notDownloaded
    case downloading(progress: Float)
    case downloaded
    case loaded
    case error(Error)
}

// MARK: - Progress Updates
struct WhisperProgress {
    let type: ProgressType
    let progress: Float  // 0.0 to 1.0
    let message: String?
    
    enum ProgressType {
        case modelDownload
        case modelLoading
        case transcription
    }
}

// MARK: - Language Support
struct WhisperLanguage {
    let code: String
    let name: String
    let nativeName: String
    
    static let supported: [WhisperLanguage] = [
        WhisperLanguage(code: "en", name: "English", nativeName: "English"),
        WhisperLanguage(code: "es", name: "Spanish", nativeName: "Español"),
        WhisperLanguage(code: "fr", name: "French", nativeName: "Français"),
        WhisperLanguage(code: "de", name: "German", nativeName: "Deutsch"),
        WhisperLanguage(code: "it", name: "Italian", nativeName: "Italiano"),
        WhisperLanguage(code: "pt", name: "Portuguese", nativeName: "Português"),
        WhisperLanguage(code: "ru", name: "Russian", nativeName: "Русский"),
        WhisperLanguage(code: "ja", name: "Japanese", nativeName: "日本語"),
        WhisperLanguage(code: "ko", name: "Korean", nativeName: "한국어"),
        WhisperLanguage(code: "zh", name: "Chinese", nativeName: "中文"),
        WhisperLanguage(code: "ar", name: "Arabic", nativeName: "العربية"),
        WhisperLanguage(code: "hi", name: "Hindi", nativeName: "हिन्दी")
    ]
    
    static func language(for code: String) -> WhisperLanguage? {
        return supported.first { $0.code == code }
    }
}

// MARK: - Error Types
enum WhisperError: Error, LocalizedError {
    case modelNotFound(String)
    case modelLoadFailed(Error)
    case audioProcessingFailed(Error)
    case transcriptionFailed(Error)
    case invalidAudioFormat
    case audioTooLong(duration: TimeInterval, maxDuration: TimeInterval)
    case downloadFailed(Error)
    case fileNotFound(URL)
    
    var errorDescription: String? {
        switch self {
        case .modelNotFound(let model):
            return "Whisper model '\(model)' not found"
        case .modelLoadFailed(let error):
            return "Failed to load Whisper model: \(error.localizedDescription)"
        case .audioProcessingFailed(let error):
            return "Audio processing failed: \(error.localizedDescription)"
        case .transcriptionFailed(let error):
            return "Transcription failed: \(error.localizedDescription)"
        case .invalidAudioFormat:
            return "Invalid or unsupported audio format"
        case .audioTooLong(let duration, let maxDuration):
            return "Audio too long (\(Int(duration))s). Maximum duration is \(Int(maxDuration))s"
        case .downloadFailed(let error):
            return "Model download failed: \(error.localizedDescription)"
        case .fileNotFound(let url):
            return "Audio file not found: \(url.lastPathComponent)"
        }
    }
} 