//
//  OllamaClient.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/11/25.
//

import Foundation

class OllamaClient {
    private let session: URLSession
    private let configuration: OllamaConfiguration
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder
    
    init(configuration: OllamaConfiguration = .shared) {
        self.configuration = configuration
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = configuration.timeout
        sessionConfig.timeoutIntervalForResource = configuration.timeout * 2 // Allow more time for resource loading
        self.session = URLSession(configuration: sessionConfig)
        
        self.jsonEncoder = JSONEncoder()
        self.jsonDecoder = JSONDecoder()
    }
    
    /// Check if Ollama is running and accessible
    func isOllamaRunning() async -> Bool {
        let healthCheckURL = configuration.baseURL.appendingPathComponent("api/version")
        var request = URLRequest(url: healthCheckURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 5.0 // Quick timeout for health check
        
        do {
            let (_, response) = try await session.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
            return false
        } catch {
            return false
        }
    }
    
    /// Get list of available models from Ollama
    func getAvailableModels() async throws -> [String] {
        let request = URLRequest(url: configuration.modelsEndpoint)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIServiceError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw AIServiceError.serverError(httpResponse.statusCode)
            }
            
            // Parse the models list
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let models = json["models"] as? [[String: Any]] {
                return models.compactMap { $0["name"] as? String }
            }
            
            return []
        } catch {
            throw AIServiceError.networkError(error)
        }
    }

    func chat(request: OllamaChatRequest) async throws -> OllamaChatResponse {
        var urlRequest = URLRequest(url: configuration.chatEndpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try jsonEncoder.encode(request)
        } catch {
            throw AIServiceError.decodingError(error)
        }
        
        do {
            let (data, response) = try await session.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIServiceError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                do {
                    return try jsonDecoder.decode(OllamaChatResponse.self, from: data)
                } catch {
                    throw AIServiceError.decodingError(error)
                }
            case 404:
                throw AIServiceError.modelNotFound
            case 429:
                throw AIServiceError.rateLimited
            case 500...599:
                throw AIServiceError.serverError(httpResponse.statusCode)
            default:
                if let errorResponse = try? jsonDecoder.decode(OllamaErrorResponse.self, from: data) {
                    throw AIServiceError.networkError(NSError(domain: "OllamaError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorResponse.error]))
                }
                throw AIServiceError.serverError(httpResponse.statusCode)
            }
        } catch let error as AIServiceError {
            throw error
        } catch {
            // Handle timeout errors specifically
            if let nsError = error as NSError?, nsError.code == -1001 {
                throw AIServiceError.networkError(NSError(
                    domain: "OllamaError",
                    code: -1001,
                    userInfo: [NSLocalizedDescriptionKey: "Request timed out. The model may need to be loaded first, which can take several minutes for large models."]
                ))
            }
            throw AIServiceError.networkError(error)
        }
    }
    
    func streamChat(request: OllamaChatRequest) -> AsyncThrowingStream<OllamaStreamResponse, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                var streamRequest = request
                streamRequest = OllamaChatRequest(
                    model: request.model,
                    messages: request.messages,
                    stream: true,
                    options: request.options
                )
                
                var urlRequest = URLRequest(url: configuration.chatEndpoint)
                urlRequest.httpMethod = "POST"
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                do {
                    urlRequest.httpBody = try jsonEncoder.encode(streamRequest)
                    
                    let (asyncBytes, response) = try await session.bytes(for: urlRequest)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: AIServiceError.invalidResponse)
                        return
                    }
                    
                    guard httpResponse.statusCode == 200 else {
                        continuation.finish(throwing: AIServiceError.serverError(httpResponse.statusCode))
                        return
                    }
                    
                    for try await line in asyncBytes.lines {
                        if !line.isEmpty {
                            do {
                                let data = line.data(using: .utf8) ?? Data()
                                let streamResponse = try jsonDecoder.decode(OllamaStreamResponse.self, from: data)
                                continuation.yield(streamResponse)
                                
                                if streamResponse.done {
                                    continuation.finish()
                                    return
                                }
                            } catch {
                                continuation.finish(throwing: AIServiceError.decodingError(error))
                                return
                            }
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    // Handle timeout errors specifically
                    if let nsError = error as NSError?, nsError.code == -1001 {
                        continuation.finish(throwing: AIServiceError.networkError(NSError(
                            domain: "OllamaError",
                            code: -1001,
                            userInfo: [NSLocalizedDescriptionKey: "Request timed out. The model may need to be loaded first, which can take several minutes for large models."]
                        )))
                    } else {
                        continuation.finish(throwing: AIServiceError.networkError(error))
                    }
                }
            }
        }
    }
}