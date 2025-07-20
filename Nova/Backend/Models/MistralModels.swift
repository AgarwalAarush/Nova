//
//  MistralModels.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/15/25.
//

import Foundation

// MARK: - Mistral API Models (Similar to OpenAI format)

struct MistralChatRequest: Codable {
    let model: String
    let messages: [MistralMessage]
    let stream: Bool?
    let temperature: Double?
    let maxTokens: Int?
    let topP: Double?
    
    enum CodingKeys: String, CodingKey {
        case model, messages, stream, temperature
        case maxTokens = "max_tokens"
        case topP = "top_p"
    }
}

struct MistralMessage: Codable {
    let role: String
    let content: String
}

struct MistralChatResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [MistralChoice]
    let usage: MistralUsage?
}

struct MistralChoice: Codable {
    let index: Int
    let message: MistralMessage?
    let delta: MistralMessage?
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case index, message, delta
        case finishReason = "finish_reason"
    }
}

struct MistralUsage: Codable {
    let promptTokens: Int
    let completionTokens: Int?
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

// MARK: - Mistral Models

enum MistralModel: String, CaseIterable {
    case mistralLarge = "mistral-large-latest"
    case mistralSmall = "mistral-small-latest"
    case codestral = "codestral-latest"
    case mixtral8x7b = "open-mixtral-8x7b"
    case mixtral8x22b = "open-mixtral-8x22b"
    
    var displayName: String {
        switch self {
        case .mistralLarge: return "Mistral Large"
        case .mistralSmall: return "Mistral Small"
        case .codestral: return "Codestral"
        case .mixtral8x7b: return "Mixtral 8x7B"
        case .mixtral8x22b: return "Mixtral 8x22B"
        }
    }
    
    var contextWindow: Int {
        switch self {
        case .mistralLarge: return 128000
        case .mistralSmall: return 32000
        case .codestral: return 32000
        case .mixtral8x7b: return 32000
        case .mixtral8x22b: return 64000
        }
    }
}