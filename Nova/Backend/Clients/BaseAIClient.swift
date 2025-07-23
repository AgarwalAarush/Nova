//
//  BaseAIClient.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/15/25.
//

import Foundation

/// Common request/response structures for AI services
struct AIMessage: Codable {
    let role: String
    let content: String
    
    init(role: AIMessageRole, content: String) {
        self.role = role.rawValue
        self.content = content
    }
}

enum AIMessageRole: String, Codable {
    case system = "system"
    case user = "user"
    case assistant = "assistant"
}

struct AIChatRequest: Encodable {
    let messages: [AIMessage]
    let model: String
    let stream: Bool
    let temperature: Double?
    let maxTokens: Int?

    enum CodingKeys: String, CodingKey {
        case messages
        case model
        case stream
        case temperature
        case maxTokens
    }
    
    init(messages: [AIMessage], model: String, stream: Bool = false, temperature: Double? = nil, maxTokens: Int? = nil) {
        self.messages = messages
        self.model = model
        self.stream = stream
        self.temperature = temperature
        self.maxTokens = maxTokens
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(messages, forKey: .messages)
        try container.encode(model, forKey: .model)
        try container.encode(stream, forKey: .stream)
        if let temperature = temperature {
            try container.encode(temperature, forKey: .temperature)
        }
        if let maxTokens = maxTokens {
            try container.encode(maxTokens, forKey: .maxTokens)
        }
    }
}

struct AIChatResponse {
    let message: AIMessage
    let model: String
    let usage: AIUsage?
    let done: Bool
    
    init(message: AIMessage, model: String, usage: AIUsage? = nil, done: Bool = true) {
        self.message = message
        self.model = model
        self.usage = usage
        self.done = done
    }
}

struct AIUsage: Codable {
    let promptTokens: Int?
    let completionTokens: Int?
    let totalTokens: Int?
    
    init(promptTokens: Int? = nil, completionTokens: Int? = nil, totalTokens: Int? = nil) {
        self.promptTokens = promptTokens
        self.completionTokens = completionTokens
        self.totalTokens = totalTokens
    }
}

/// Base class for AI service clients
class BaseAIClient {
    let session: URLSession
    let baseURL: URL
    
    init(baseURL: URL, timeout: TimeInterval = 60.0) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout * 2
        self.session = URLSession(configuration: config)
        self.baseURL = baseURL
    }
    
    // MARK: - Common HTTP Methods
    
    func createRequest(endpoint: String, method: HTTPMethod = .POST, headers: [String: String] = [:]) -> URLRequest {
        let url = baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add custom headers
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return request
    }
    
    func performRequest<T: Decodable>(request: URLRequest, responseType: T.Type) async throws -> T {
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            if httpResponse.statusCode == 429 {
                throw AIServiceError.rateLimited
            } else {
                throw AIServiceError.serverError(httpResponse.statusCode)
            }
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("🔥 Decoding error: \(error)")
            print("🔥 Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
            throw AIServiceError.decodingError(error)
        }
    }
    
    func performStreamingRequest(request: URLRequest) -> AsyncThrowingStream<Data, Error> {
        return AsyncThrowingStream { continuation in
            let task = session.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.finish(throwing: AIServiceError.networkError(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    continuation.finish(throwing: AIServiceError.invalidResponse)
                    return
                }
                
                guard 200...299 ~= httpResponse.statusCode else {
                    if httpResponse.statusCode == 429 {
                        continuation.finish(throwing: AIServiceError.rateLimited)
                    } else {
                        continuation.finish(throwing: AIServiceError.serverError(httpResponse.statusCode))
                    }
                    return
                }
                
                if let data = data {
                    continuation.yield(data)
                }
                
                continuation.finish()
            }
            
            task.resume()
            
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

/// Protocol for AI clients
protocol AIClientProtocol {
    func chat(request: AIChatRequest) async throws -> AIChatResponse
    func streamChat(request: AIChatRequest) -> AsyncThrowingStream<AIChatResponse, Error>
    var supportedModels: [String] { get }
}