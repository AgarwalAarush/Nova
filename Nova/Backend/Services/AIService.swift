//
//  AIService.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/11/25.
//

import Foundation

protocol AIService {
    func generateResponse(for message: String) async throws -> String
    func generateStreamingResponse(for message: String) -> AsyncThrowingStream<String, Error>
    var supportedModels: [String] { get }
    var currentModel: String { get set }
}

protocol AudioTranscriptionService {
    func transcribeAudio(input: WhisperAudioInput, request: WhisperTranscriptionRequest) async throws -> WhisperTranscriptionResponse
    func downloadModel(_ modelSize: WhisperConfiguration.ModelSize) async throws
    func isModelAvailable(_ modelSize: WhisperConfiguration.ModelSize) -> Bool
    func getModelStatus(_ modelSize: WhisperConfiguration.ModelSize) -> WhisperModelStatus
    var availableModels: [WhisperConfiguration.ModelSize] { get }
    var currentModel: WhisperConfiguration.ModelSize { get set }
}

enum AIServiceError: Error, LocalizedError {
    case networkError(Error)
    case invalidResponse
    case invalidRequest(String)
    case modelNotFound
    case rateLimited
    case serverError(Int)
    case decodingError(Error)
    // Audio transcription specific errors
    case audioProcessingFailed(Error)
    case modelDownloadFailed(Error)
    case audioFormatUnsupported
    case audioTooLong
    // Ollama specific errors
    case ollamaNotRunning
    case ollamaModelNotInstalled(String)
    case ollamaModelLoading(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from AI service"
        case .invalidRequest(let message):
            return "Invalid request: \(message)"
        case .modelNotFound:
            return "AI model not found or unavailable"
        case .rateLimited:
            return "Rate limit exceeded. Please try again later"
        case .serverError(let code):
            return "Server error with code: \(code)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .audioProcessingFailed(let error):
            return "Audio processing failed: \(error.localizedDescription)"
        case .modelDownloadFailed(let error):
            return "Model download failed: \(error.localizedDescription)"
        case .audioFormatUnsupported:
            return "Audio format is not supported"
        case .audioTooLong:
            return "Audio duration exceeds maximum limit"
        case .ollamaNotRunning:
            return "Ollama is not running. Please start Ollama first by running 'ollama serve' in your terminal."
        case .ollamaModelNotInstalled(let model):
            return "Model '\(model)' is not installed. Please install it by running 'ollama pull \(model)' in your terminal."
        case .ollamaModelLoading(let model):
            return "Model '\(model)' is loading. Large models can take several minutes to load on first use."
        }
    }
}