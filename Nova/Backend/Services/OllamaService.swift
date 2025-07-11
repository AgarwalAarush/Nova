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
            throw error
        }
    }
    
    func generateStreamingResponse(for message: String) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                let userMessage = OllamaMessage(role: .user, content: message)
                self.conversationHistory.append(userMessage)
                
                let request = OllamaChatRequest(
                    model: self.currentModel,
                    messages: self.conversationHistory,
                    stream: true,
                    options: self.configuration.defaultOptions
                )
                
                var fullResponse = ""
                
                do {
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
                    continuation.finish(throwing: error)
                }
            }
        }
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