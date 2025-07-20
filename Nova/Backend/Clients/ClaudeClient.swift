//
//  ClaudeClient.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/15/25.
//

import Foundation

class ClaudeClient: BaseAIClient, AIClientProtocol {
    private let apiKey: String
    
    var supportedModels: [String] {
        return ClaudeModel.allCases.map(\.rawValue)
    }
    
    init(apiKey: String) {
        self.apiKey = apiKey
        super.init(baseURL: URL(string: "https://api.anthropic.com/v1")!)
    }
    
    // MARK: - AIClientProtocol
    
    func chat(request: AIChatRequest) async throws -> AIChatResponse {
        let claudeRequest = convertToClaudeRequest(request)
        let urlRequest = try createChatRequest(claudeRequest)
        
        let response = try await performRequest(request: urlRequest, responseType: ClaudeResponse.self)
        return convertFromClaudeResponse(response)
    }
    
    func streamChat(request: AIChatRequest) -> AsyncThrowingStream<AIChatResponse, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    var streamRequest = convertToClaudeRequest(request)
                    streamRequest = ClaudeRequest(
                        model: streamRequest.model,
                        maxTokens: streamRequest.maxTokens,
                        messages: streamRequest.messages,
                        system: streamRequest.system,
                        stream: true,
                        temperature: streamRequest.temperature,
                        topP: streamRequest.topP,
                        topK: streamRequest.topK
                    )
                    
                    let urlRequest = try createChatRequest(streamRequest)
                    let dataStream = performStreamingRequest(request: urlRequest)
                    
                    var buffer = ""
                    
                    for try await data in dataStream {
                        buffer += String(data: data, encoding: .utf8) ?? ""
                        
                        // Process complete lines
                        let lines = buffer.components(separatedBy: "\n")
                        buffer = lines.last ?? ""
                        
                        for line in lines.dropLast() {
                            await processStreamLine(line, continuation: continuation)
                        }
                    }
                    
                    // Process any remaining buffer
                    if !buffer.isEmpty {
                        await processStreamLine(buffer, continuation: continuation)
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func createChatRequest(_ request: ClaudeRequest) throws -> URLRequest {
        var urlRequest = createRequest(endpoint: "messages", headers: [
            "x-api-key": apiKey,
            "anthropic-version": "2023-06-01"
        ])
        
        let jsonData = try JSONEncoder().encode(request)
        urlRequest.httpBody = jsonData
        
        return urlRequest
    }
    
    private func convertToClaudeRequest(_ request: AIChatRequest) -> ClaudeRequest {
        // Separate system messages from user/assistant messages
        var systemPrompt: String?
        var chatMessages: [ClaudeMessage] = []
        
        for message in request.messages {
            if message.role == "system" {
                systemPrompt = message.content
            } else {
                chatMessages.append(ClaudeMessage(role: message.role, content: message.content))
            }
        }
        
        return ClaudeRequest(
            model: request.model,
            maxTokens: request.maxTokens ?? 4096,
            messages: chatMessages,
            system: systemPrompt,
            stream: request.stream,
            temperature: request.temperature,
            topP: nil,
            topK: nil
        )
    }
    
    private func convertFromClaudeResponse(_ response: ClaudeResponse) -> AIChatResponse {
        let content = response.content.first?.text ?? ""
        let message = AIMessage(role: .assistant, content: content)
        
        let usage = AIUsage(
            promptTokens: response.usage.inputTokens,
            completionTokens: response.usage.outputTokens,
            totalTokens: response.usage.inputTokens + response.usage.outputTokens
        )
        
        return AIChatResponse(
            message: message,
            model: response.model,
            usage: usage,
            done: true
        )
    }
    
    private func processStreamLine(_ line: String, continuation: AsyncThrowingStream<AIChatResponse, Error>.Continuation) async {
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard trimmedLine.hasPrefix("data: "), trimmedLine.count > 6 else { return }
        
        let jsonString = String(trimmedLine.dropFirst(6))
        
        if jsonString == "[DONE]" {
            return
        }
        
        guard let data = jsonString.data(using: .utf8) else { return }
        
        do {
            let streamResponse = try JSONDecoder().decode(ClaudeStreamResponse.self, from: data)
            
            if streamResponse.type == "content_block_delta",
               let delta = streamResponse.delta,
               let text = delta.text {
                
                let message = AIMessage(role: .assistant, content: text)
                let response = AIChatResponse(
                    message: message,
                    model: "", // Claude streams don't include model in every chunk
                    usage: nil,
                    done: delta.stopReason != nil
                )
                
                continuation.yield(response)
            } else if streamResponse.type == "message_stop" {
                // Stream finished
                let message = AIMessage(role: .assistant, content: "")
                let response = AIChatResponse(
                    message: message,
                    model: "",
                    usage: streamResponse.usage.map { usage in
                        AIUsage(
                            promptTokens: usage.inputTokens,
                            completionTokens: usage.outputTokens,
                            totalTokens: usage.inputTokens + usage.outputTokens
                        )
                    },
                    done: true
                )
                
                continuation.yield(response)
            }
        } catch {
            print("🔥 Failed to decode Claude stream response: \(error)")
        }
    }
}