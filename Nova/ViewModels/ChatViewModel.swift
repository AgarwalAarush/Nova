//
//  ChatViewModel.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/11/25.
//

import Foundation
import SwiftUI

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var currentInput: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let aiService: AIService
    
    init(aiService: AIService = OllamaService()) {
        self.aiService = aiService
        addMessage("Welcome to Nova! How can I assist you today?", isUser: false)
    }
    
    func sendMessage() {
        guard !currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard !isLoading else { return }
        
        let userMessage = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
        addMessage(userMessage, isUser: true)
        currentInput = ""
        
        Task {
            await generateAIResponse(for: userMessage)
        }
    }
    
    private func addMessage(_ content: String, isUser: Bool) {
        let message = ChatMessage(content: content, isUser: isUser)
        messages.append(message)
    }
    
    @MainActor
    private func generateAIResponse(for userMessage: String) async {
        isLoading = true
        errorMessage = nil
        
        // Create placeholder message for streaming
        let placeholderMessage = ChatMessage(content: "", isUser: false)
        messages.append(placeholderMessage)
        let messageIndex = messages.count - 1
        
        do {
            let stream = aiService.generateStreamingResponse(for: userMessage)
            var fullResponse = ""
            
            for try await chunk in stream {
                fullResponse += chunk
                // Update the placeholder message with accumulated response
                messages[messageIndex] = ChatMessage(content: fullResponse, isUser: false)
            }
        } catch {
            let errorMsg = error.localizedDescription
            errorMessage = errorMsg
            // Replace placeholder with error message
            messages[messageIndex] = ChatMessage(content: "Sorry, I encountered an error: \(errorMsg)", isUser: false)
        }
        
        isLoading = false
    }
    
    func retryLastMessage() {
        guard let lastUserMessage = messages.last(where: { $0.isUser }) else { return }
        
        Task {
            await generateAIResponse(for: lastUserMessage.content)
        }
    }
    
    func clearConversation() {
        messages.removeAll()
        if let ollamaService = aiService as? OllamaService {
            ollamaService.clearConversationHistory()
        }
        addMessage("Welcome to Nova! How can I assist you today?", isUser: false)
    }
}