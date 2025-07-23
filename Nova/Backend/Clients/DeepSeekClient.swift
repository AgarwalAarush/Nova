//
//  DeepSeekClient.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/21/25.
//

import Foundation

class DeepSeekClient: BaseAIClient, AIClientProtocol {
    private let apiKey: String
    
    var supportedModels: [String] {
        return DeepSeekModel.allCases.map(\.rawValue)
    }
    
    init(apiKey: String) {
        self.apiKey = apiKey
        super.init(baseURL: URL(string: "https://api.deepseek.com")!)
    }
    
    // MARK: - AIClientProtocol
    
    func chat(request: AIChatRequest) async throws -> AIChatResponse {
        let deepSeekRequest = convertToDeepSeekRequest(request)
        let urlRequest = try createChatRequest(deepSeekRequest)
        
        let response = try await performRequest(request: urlRequest, responseType: DeepSeekChatResponse.self)
        return convertFromDeepSeekResponse(response)
    }
    
    func streamChat(request: AIChatRequest) -> AsyncThrowingStream<AIChatResponse, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    var streamRequest = convertToDeepSeekRequest(request)
                    streamRequest.stream = true
                    
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
    
    private func createChatRequest(_ request: DeepSeekChatRequest) throws -> URLRequest {
        var urlRequest = createRequest(endpoint: "chat/completions", headers: [
            "Authorization": "Bearer \(apiKey)"
        ])
        
        let jsonData = try JSONEncoder().encode(request)
        urlRequest.httpBody = jsonData
        
        return urlRequest
    }
    
    private func convertToDeepSeekRequest(_ request: AIChatRequest) -> DeepSeekChatRequest {
        let messages = request.messages.map { message in
            DeepSeekMessage(role: message.role, content: message.content)
        }
        
        return DeepSeekChatRequest(
            model: request.model,
            messages: messages,
            stream: request.stream,
            temperature: request.temperature,
            maxTokens: request.maxTokens,
            topP: nil,
            frequencyPenalty: nil,
            presencePenalty: nil
        )
    }
    
    private func convertFromDeepSeekResponse(_ response: DeepSeekChatResponse) -> AIChatResponse {
        let choice = response.choices.first
        let message = choice?.message.map { deepSeekMessage in
            AIMessage(role: AIMessageRole(rawValue: deepSeekMessage.role) ?? .assistant, content: deepSeekMessage.content)
        } ?? AIMessage(role: .assistant, content: "")
        
        let usage = response.usage.map { deepSeekUsage in
            AIUsage(
                promptTokens: deepSeekUsage.promptTokens,
                completionTokens: deepSeekUsage.completionTokens,
                totalTokens: deepSeekUsage.totalTokens
            )
        }
        
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
            let streamResponse = try JSONDecoder().decode(DeepSeekStreamResponse.self, from: data)
            
            if let choice = streamResponse.choices?.first,
               let delta = choice.delta,
               let content = delta.content {
                
                let message = AIMessage(role: .assistant, content: content)
                let response = AIChatResponse(
                    message: message,
                    model: streamResponse.model ?? "",
                    usage: nil,
                    done: choice.finishReason != nil
                )
                
                continuation.yield(response)
            }
        } catch {
            print("🔥 Failed to decode DeepSeek stream response: \(error)")
        }
    }
}