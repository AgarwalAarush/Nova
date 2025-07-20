//
//  OllamaModels.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/11/25.
//

import Foundation

struct OllamaChatRequest: Codable {
    let model: String
    let messages: [OllamaMessage]
    let stream: Bool
    let options: OllamaOptions?
    
    init(model: String, messages: [OllamaMessage], stream: Bool = false, options: OllamaOptions? = nil) {
        self.model = model
        self.messages = messages
        self.stream = stream
        self.options = options
    }
}

struct OllamaMessage: Codable {
    let role: String
    let content: String
    
    init(role: OllamaRole, content: String) {
        self.role = role.rawValue
        self.content = content
    }
}

enum OllamaRole: String, Codable {
    case system = "system"
    case user = "user"
    case assistant = "assistant"
}

struct OllamaOptions: Codable {
    let temperature: Double?
    let topP: Double?
    let topK: Int?
    let repeatPenalty: Double?
    let seed: Int?
    let numCtx: Int?
    
    enum CodingKeys: String, CodingKey {
        case temperature
        case topP = "top_p"
        case topK = "top_k"
        case repeatPenalty = "repeat_penalty"
        case seed
        case numCtx = "num_ctx"
    }
    
    static let `default` = OllamaOptions(
        temperature: 0.7,
        topP: 0.9,
        topK: 40,
        repeatPenalty: 1.1,
        seed: nil,
        numCtx: 4096
    )
}

struct OllamaChatResponse: Codable {
    let model: String
    let createdAt: String
    let message: OllamaMessage
    let done: Bool
    let totalDuration: Int?
    let loadDuration: Int?
    let promptEvalCount: Int?
    let promptEvalDuration: Int?
    let evalCount: Int?
    let evalDuration: Int?
    
    enum CodingKeys: String, CodingKey {
        case model
        case createdAt = "created_at"
        case message
        case done
        case totalDuration = "total_duration"
        case loadDuration = "load_duration"
        case promptEvalCount = "prompt_eval_count"
        case promptEvalDuration = "prompt_eval_duration"
        case evalCount = "eval_count"
        case evalDuration = "eval_duration"
    }
}

struct OllamaStreamResponse: Codable {
    let model: String
    let createdAt: String
    let message: OllamaMessage
    let done: Bool
    
    enum CodingKeys: String, CodingKey {
        case model
        case createdAt = "created_at"
        case message
        case done
    }
}

struct OllamaErrorResponse: Codable {
    let error: String
}