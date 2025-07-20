//
//  OpenAIModels.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/15/25.
//

import Foundation

// MARK: - OpenAI Chat Completions API Models

struct OpenAIChatRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    var stream: Bool?
    let temperature: Double?
    let maxTokens: Int?
    let topP: Double?
    let frequencyPenalty: Double?
    let presencePenalty: Double?
    
    enum CodingKeys: String, CodingKey {
        case model, messages, stream, temperature
        case maxTokens = "max_tokens"
        case topP = "top_p"
        case frequencyPenalty = "frequency_penalty"
        case presencePenalty = "presence_penalty"
    }
}

struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

struct OpenAIChatResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [OpenAIChoice]
    let usage: OpenAIUsage?
}

struct OpenAIChoice: Codable {
    let index: Int
    let message: OpenAIMessage?
    let delta: OpenAIMessage?
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case index, message, delta
        case finishReason = "finish_reason"
    }
}

struct OpenAIUsage: Codable {
    let promptTokens: Int
    let completionTokens: Int?
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

// MARK: - OpenAI Stream Response

struct OpenAIStreamResponse: Codable {
    let id: String?
    let object: String?
    let created: Int?
    let model: String?
    let choices: [OpenAIStreamChoice]?
}

struct OpenAIStreamChoice: Codable {
    let index: Int?
    let delta: OpenAIStreamDelta?
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case index, delta
        case finishReason = "finish_reason"
    }
}

struct OpenAIStreamDelta: Codable {
    let role: String?
    let content: String?
}

// MARK: - OpenAI Error Response

struct OpenAIErrorResponse: Codable {
    let error: OpenAIError
}

struct OpenAIError: Codable {
    let message: String
    let type: String?
    let param: String?
    let code: String?
}

// MARK: - OpenAI Models

enum OpenAIModel: String, CaseIterable {
    case gpt4o = "gpt-4o"
    case gpt4oMini = "gpt-4o-mini"
    case gpt4Turbo = "gpt-4-turbo"
    case gpt4 = "gpt-4"
    case gpt35Turbo = "gpt-3.5-turbo"
    
    var displayName: String {
        switch self {
        case .gpt4o: return "GPT-4o"
        case .gpt4oMini: return "GPT-4o Mini"
        case .gpt4Turbo: return "GPT-4 Turbo"
        case .gpt4: return "GPT-4"
        case .gpt35Turbo: return "GPT-3.5 Turbo"
        }
    }
    
    var contextWindow: Int {
        switch self {
        case .gpt4o, .gpt4Turbo: return 128000
        case .gpt4oMini: return 128000
        case .gpt35Turbo: return 16385
        case .gpt4: return 8192
        }
    }
    
    var maxOutputTokens: Int {
        switch self {
        case .gpt4o, .gpt4oMini: return 16384
        case .gpt4Turbo: return 4096
        case .gpt35Turbo: return 4096
        case .gpt4: return 8192
        }
    }
}