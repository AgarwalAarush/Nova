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

enum AIServiceError: Error, LocalizedError {
    case networkError(Error)
    case invalidResponse
    case modelNotFound
    case rateLimited
    case serverError(Int)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from AI service"
        case .modelNotFound:
            return "AI model not found or unavailable"
        case .rateLimited:
            return "Rate limit exceeded. Please try again later"
        case .serverError(let code):
            return "Server error with code: \(code)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}