//
//  MistralClient.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/15/25.
//

import Foundation

class MistralClient: BaseAIClient, AIClientProtocol {
    private let apiKey: String
    
    var supportedModels: [String] {
        return MistralModel.allCases.map(\.rawValue)
    }
    
    init(apiKey: String) {
        self.apiKey = apiKey
        super.init(baseURL: URL(string: "https://api.mistral.ai/v1")!)
    }
    
    // MARK: - AIClientProtocol
    
    func chat(request: AIChatRequest) async throws -> AIChatResponse {
        let mistralRequest = convertToMistralRequest(request)
        let urlRequest = try createChatRequest(mistralRequest)
        
        let response = try await performRequest(request: urlRequest, responseType: MistralChatResponse.self)
        return convertFromMistralResponse(response)
    }
    
    func streamChat(request: AIChatRequest) -> AsyncThrowingStream<AIChatResponse, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    var streamRequest = convertToMistralRequest(request)
                    streamRequest = MistralChatRequest(
                        model: streamRequest.model,
                        messages: streamRequest.messages,
                        stream: true,
                        temperature: streamRequest.temperature,
                        maxTokens: streamRequest.maxTokens,
                        topP: streamRequest.topP
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
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func createChatRequest(_ request: MistralChatRequest) throws -> URLRequest {
        var urlRequest = createRequest(endpoint: "chat/completions", headers: [
            "Authorization": "Bearer \(apiKey)"
        ])
        
        let jsonData = try JSONEncoder().encode(request)
        urlRequest.httpBody = jsonData
        
        return urlRequest
    }
    
    private func convertToMistralRequest(_ request: AIChatRequest) -> MistralChatRequest {
        let messages = request.messages.map { message in
            MistralMessage(role: message.role, content: message.content)
        }
        
        return MistralChatRequest(
            model: request.model,
            messages: messages,
            stream: request.stream,
            temperature: request.temperature,
            maxTokens: request.maxTokens,
            topP: nil
        )
    }
    
    private func convertFromMistralResponse(_ response: MistralChatResponse) -> AIChatResponse {
        let choice = response.choices.first
        let message = choice?.message.map { mistralMessage in
            AIMessage(role: AIMessageRole(rawValue: mistralMessage.role) ?? .assistant, content: mistralMessage.content)
        } ?? AIMessage(role: .assistant, content: "")
        
        let usage = response.usage.map { mistralUsage in
            AIUsage(
                promptTokens: mistralUsage.promptTokens,
                completionTokens: mistralUsage.completionTokens,
                totalTokens: mistralUsage.totalTokens
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
            let streamResponse = try JSONDecoder().decode(MistralChatResponse.self, from: data)
            
            if let choice = streamResponse.choices.first,
               let delta = choice.delta,
               !delta.content.isEmpty {
                
                let message = AIMessage(role: .assistant, content: delta.content)
                let response = AIChatResponse(
                    message: message,
                    model: streamResponse.model,
                    usage: nil,
                    done: choice.finishReason != nil
                )
                
                continuation.yield(response)
            }
        } catch {
            print("🔥 Failed to decode Mistral stream response: \(error)")
        }
    }
}