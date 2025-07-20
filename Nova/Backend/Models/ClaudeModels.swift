//
//  ClaudeModels.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/15/25.
//

import Foundation

// MARK: - Anthropic Claude API Models

struct ClaudeRequest: Codable {
    let model: String
    let maxTokens: Int
    let messages: [ClaudeMessage]
    let system: String?
    let stream: Bool?
    let temperature: Double?
    let topP: Double?
    let topK: Int?
    
    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case messages, system, stream, temperature
        case topP = "top_p"
        case topK = "top_k"
    }
}

struct ClaudeMessage: Codable {
    let role: String
    let content: String
}

struct ClaudeResponse: Codable {
    let id: String
    let type: String
    let role: String
    let content: [ClaudeContent]
    let model: String
    let stopReason: String?
    let stopSequence: String?
    let usage: ClaudeUsage
    
    enum CodingKeys: String, CodingKey {
        case id, type, role, content, model
        case stopReason = "stop_reason"
        case stopSequence = "stop_sequence"
        case usage
    }
}

struct ClaudeContent: Codable {
    let type: String
    let text: String
}

struct ClaudeUsage: Codable {
    let inputTokens: Int
    let outputTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
}

// MARK: - Claude Stream Response

struct ClaudeStreamResponse: Codable {
    let type: String
    let index: Int?
    let delta: ClaudeStreamDelta?
    let message: ClaudeStreamMessage?
    let usage: ClaudeUsage?
}

struct ClaudeStreamDelta: Codable {
    let type: String?
    let text: String?
    let stopReason: String?
    
    enum CodingKeys: String, CodingKey {
        case type, text
        case stopReason = "stop_reason"
    }
}

struct ClaudeStreamMessage: Codable {
    let id: String?
    let type: String?
    let role: String?
    let model: String?
    let content: [ClaudeContent]?
    let usage: ClaudeUsage?
}

// MARK: - Claude Error Response

struct ClaudeErrorResponse: Codable {
    let type: String
    let error: ClaudeError
}

struct ClaudeError: Codable {
    let type: String
    let message: String
}

// MARK: - Claude Models

enum ClaudeModel: String, CaseIterable {
    case claude35Sonnet = "claude-3-5-sonnet-20241022"
    case claude35Haiku = "claude-3-5-haiku-20241022"
    case claude3Opus = "claude-3-opus-20240229"
    case claude3Sonnet = "claude-3-sonnet-20240229"
    case claude3Haiku = "claude-3-haiku-20240307"
    
    var displayName: String {
        switch self {
        case .claude35Sonnet: return "Claude 3.5 Sonnet"
        case .claude35Haiku: return "Claude 3.5 Haiku"
        case .claude3Opus: return "Claude 3 Opus"
        case .claude3Sonnet: return "Claude 3 Sonnet"
        case .claude3Haiku: return "Claude 3 Haiku"
        }
    }
    
    var contextWindow: Int {
        switch self {
        case .claude35Sonnet, .claude35Haiku: return 200000
        case .claude3Opus, .claude3Sonnet, .claude3Haiku: return 200000
        }
    }
    
    var maxOutputTokens: Int {
        switch self {
        case .claude35Sonnet: return 8192
        case .claude35Haiku: return 8192
        case .claude3Opus: return 4096
        case .claude3Sonnet: return 4096
        case .claude3Haiku: return 4096
        }
    }
    
    var pricing: (input: Double, output: Double) {
        // Pricing per million tokens (as of latest update)
        switch self {
        case .claude35Sonnet: return (3.0, 15.0)
        case .claude35Haiku: return (1.0, 5.0)
        case .claude3Opus: return (15.0, 75.0)
        case .claude3Sonnet: return (3.0, 15.0)
        case .claude3Haiku: return (0.25, 1.25)
        }
    }
}