//
//  OllamaService.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/11/25.
//

import Foundation

class OllamaService: AIService {
    private let client: OllamaClient
    private let configuration: OllamaConfiguration
    private var conversationHistory: [OllamaMessage] = []
    
    var currentModel: String
    let supportedModels: [String] = [
        "gemma3:4b",
        "gemma3:12b", 
        "llama2-uncensored:7b",
        "phi4:latest",
        "llama3.2:1b",
        "llama3.2:3b",
        "qwen2.5:1.5b",
        "phi3:mini"
    ]
    
    init(client: OllamaClient = OllamaClient(), configuration: OllamaConfiguration = .shared) {
        self.client = client
        self.configuration = configuration
        self.currentModel = configuration.defaultModel
    }
    
    /// Check if Ollama is running and the current model is available
    func checkAvailability() async throws {
        let isRunning = await client.isOllamaRunning()
        guard isRunning else {
            throw AIServiceError.ollamaNotRunning
        }
        
        // Check if the current model is available
        do {
            let availableModels = try await client.getAvailableModels()
            if !availableModels.contains(currentModel) {
                throw AIServiceError.ollamaModelNotInstalled(currentModel)
            }
        } catch {
            // If we can't get the model list, assume it's a connectivity issue
            throw AIServiceError.networkError(error)
        }
    }
    
    func generateResponse(for message: String) async throws -> String {
        let userMessage = OllamaMessage(role: .user, content: message)
        conversationHistory.append(userMessage)
        
        let request = OllamaChatRequest(
            model: currentModel,
            messages: conversationHistory,
            stream: false,
            options: configuration.defaultOptions
        )
        
        do {
            let response = try await client.chat(request: request)
            let assistantMessage = response.message
            conversationHistory.append(assistantMessage)
            
            return assistantMessage.content
        } catch {
            conversationHistory.removeLast()
            throw mapOllamaError(error)
        }
    }
    
    func generateStreamingResponse(for message: String) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let userMessage = OllamaMessage(role: .user, content: message)
                    self.conversationHistory.append(userMessage)
                    
                    let request = OllamaChatRequest(
                        model: self.currentModel,
                        messages: self.conversationHistory,
                        stream: true,
                        options: self.configuration.defaultOptions
                    )
                    
                    var fullResponse = ""
                    
                    let stream = self.client.streamChat(request: request)
                    
                    for try await chunk in stream {
                        let content = chunk.message.content
                        fullResponse += content
                        continuation.yield(content)
                        
                        if chunk.done {
                            let assistantMessage = OllamaMessage(role: .assistant, content: fullResponse)
                            self.conversationHistory.append(assistantMessage)
                            continuation.finish()
                            return
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    self.conversationHistory.removeLast()
                    continuation.finish(throwing: self.mapOllamaError(error))
                }
            }
        }
    }
    
    /// Map Ollama-specific errors to more user-friendly error messages
    private func mapOllamaError(_ error: Error) -> Error {
        if let nsError = error as NSError? {
            // Timeout errors usually indicate model loading
            if nsError.code == -1001 {
                return AIServiceError.ollamaModelLoading(currentModel)
            }
            
            // Connection refused errors indicate Ollama is not running
            if nsError.code == -1004 || nsError.code == -1009 || nsError.code == -1003 {
                return AIServiceError.ollamaNotRunning
            }
            
            if nsError.domain == "OllamaError" {
                let message = nsError.userInfo[NSLocalizedDescriptionKey] as? String ?? ""
                if message.contains("not running") {
                    return AIServiceError.ollamaNotRunning
                }
                if message.contains("model not found") || message.contains("404") {
                    return AIServiceError.ollamaModelNotInstalled(currentModel)
                }
            }
        }
        
        // Check for AIServiceError cases that should be mapped
        if let aiError = error as? AIServiceError {
            switch aiError {
            case .modelNotFound:
                return AIServiceError.ollamaModelNotInstalled(currentModel)
            case .serverError(404):
                return AIServiceError.ollamaModelNotInstalled(currentModel)
            case .networkError(let networkError):
                if let nsError = networkError as NSError?, nsError.code == -1004 || nsError.code == -1009 {
                    return AIServiceError.ollamaNotRunning
                }
                return aiError
            default:
                return aiError
            }
        }
        
        return error
    }
    
    func clearConversationHistory() {
        conversationHistory.removeAll()
    }
    
    func setSystemPrompt(_ prompt: String) {
        conversationHistory.removeAll { $0.role == "system" }
        let systemMessage = OllamaMessage(role: .system, content: prompt)
        conversationHistory.insert(systemMessage, at: 0)
    }
}