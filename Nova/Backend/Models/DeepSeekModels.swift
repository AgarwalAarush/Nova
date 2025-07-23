//
//  DeepSeekModels.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/21/25.
//

import Foundation

// MARK: - DeepSeek Chat Completions API Models

struct DeepSeekChatRequest: Codable {
    let model: String
    let messages: [DeepSeekMessage]
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

struct DeepSeekMessage: Codable {
    let role: String
    let content: String
}

struct DeepSeekChatResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [DeepSeekChoice]
    let usage: DeepSeekUsage?
}

struct DeepSeekChoice: Codable {
    let index: Int
    let message: DeepSeekMessage?
    let delta: DeepSeekMessage?
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case index, message, delta
        case finishReason = "finish_reason"
    }
}

struct DeepSeekUsage: Codable {
    let promptTokens: Int
    let completionTokens: Int?
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

// MARK: - DeepSeek Stream Response

struct DeepSeekStreamResponse: Codable {
    let id: String?
    let object: String?
    let created: Int?
    let model: String?
    let choices: [DeepSeekStreamChoice]?
}

struct DeepSeekStreamChoice: Codable {
    let index: Int?
    let delta: DeepSeekStreamDelta?
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case index, delta
        case finishReason = "finish_reason"
    }
}

struct DeepSeekStreamDelta: Codable {
    let role: String?
    let content: String?
}

// MARK: - DeepSeek Error Response

struct DeepSeekErrorResponse: Codable {
    let error: DeepSeekError
}

struct DeepSeekError: Codable {
    let message: String
    let type: String?
    let param: String?
    let code: String?
}

// MARK: - DeepSeek Models

enum DeepSeekModel: String, CaseIterable {
    case deepseekV3 = "deepseek-chat"
    case deepseekR1 = "deepseek-reasoner"
    
    var displayName: String {
        switch self {
        case .deepseekV3: return "DeepSeek V3"
        case .deepseekR1: return "DeepSeek R1"
        }
    }
    
    var contextWindow: Int {
        switch self {
        case .deepseekV3: return 128000
        case .deepseekR1: return 128000
        }
    }
    
    var maxOutputTokens: Int {
        switch self {
        case .deepseekV3: return 8192
        case .deepseekR1: return 8192
        }
    }
}