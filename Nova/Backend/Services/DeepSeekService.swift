//
//  DeepSeekService.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/21/25.
//

import Foundation

class DeepSeekService: AIService {
    private let client: DeepSeekClient
    private var conversationHistory: [AIMessage] = []
    
    var currentModel: String
    var supportedModels: [String] {
        return client.supportedModels
    }
    
    init(apiKey: String, model: String = DeepSeekModel.deepseekV3.rawValue) {
        self.client = DeepSeekClient(apiKey: apiKey)
        self.currentModel = model
    }
    
    func generateResponse(for message: String) async throws -> String {
        let userMessage = AIMessage(role: .user, content: message)
        conversationHistory.append(userMessage)

        let request = AIChatRequest(
            messages: conversationHistory,
            model: currentModel,
            stream: false,
        )

        print("Request: \(request)")
        
        do {
            let response = try await client.chat(request: request)
            let assistantMessage = response.message
            conversationHistory.append(assistantMessage)
            
            return assistantMessage.content
        } catch {
            conversationHistory.removeLast() // Remove the user message if failed
            throw error
        }
    }
    
    func generateStreamingResponse(for message: String) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                let userMessage = AIMessage(role: .user, content: message)
                self.conversationHistory.append(userMessage)
                
                let request = AIChatRequest(
                    messages: self.conversationHistory,
                    model: currentModel,
                    stream: true,
                )
                
                var fullResponse = ""
                
                do {
                    let stream = self.client.streamChat(request: request)
                    
                    for try await chunk in stream {
                        let content = chunk.message.content
                        fullResponse += content
                        continuation.yield(content)
                        
                        if chunk.done {
                            let assistantMessage = AIMessage(role: .assistant, content: fullResponse)
                            self.conversationHistory.append(assistantMessage)
                            continuation.finish()
                            return
                        }
                    }
                    
                    // Fallback completion
                    if !fullResponse.isEmpty {
                        let assistantMessage = AIMessage(role: .assistant, content: fullResponse)
                        self.conversationHistory.append(assistantMessage)
                    }
                    
                    continuation.finish()
                } catch {
                    self.conversationHistory.removeLast() // Remove the user message if failed
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Conversation Management
    
    func clearConversationHistory() {
        conversationHistory.removeAll()
    }
    
    func setSystemPrompt(_ prompt: String) {
        conversationHistory.removeAll { $0.role == "system" }
        let systemMessage = AIMessage(role: .system, content: prompt)
        conversationHistory.insert(systemMessage, at: 0)
    }
    
    func setModel(_ model: String) {
        guard supportedModels.contains(model) else {
            print("⚠️ Model \(model) not supported by DeepSeek service")
            return
        }
        currentModel = model
    }
}
