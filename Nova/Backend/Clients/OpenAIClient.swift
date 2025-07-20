//
//  OpenAIClient.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/15/25.
//

import Foundation

class OpenAIClient: BaseAIClient, AIClientProtocol {
    private let apiKey: String
    
    var supportedModels: [String] {
        return OpenAIModel.allCases.map(\.rawValue)
    }
    
    init(apiKey: String) {
        self.apiKey = apiKey
        super.init(baseURL: URL(string: "https://api.openai.com/v1")!)
    }
    
    // MARK: - AIClientProtocol
    
    func chat(request: AIChatRequest) async throws -> AIChatResponse {
        let openAIRequest = convertToOpenAIRequest(request)
        let urlRequest = try createChatRequest(openAIRequest)
        
        let response = try await performRequest(request: urlRequest, responseType: OpenAIChatResponse.self)
        return convertFromOpenAIResponse(response)
    }
    
    func streamChat(request: AIChatRequest) -> AsyncThrowingStream<AIChatResponse, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    var streamRequest = convertToOpenAIRequest(request)
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
    
    private func createChatRequest(_ request: OpenAIChatRequest) throws -> URLRequest {
        var urlRequest = createRequest(endpoint: "chat/completions", headers: [
            "Authorization": "Bearer \(apiKey)",
            "OpenAI-Beta": "assistants=v2"
        ])
        
        let jsonData = try JSONEncoder().encode(request)
        urlRequest.httpBody = jsonData
        
        return urlRequest
    }
    
    private func convertToOpenAIRequest(_ request: AIChatRequest) -> OpenAIChatRequest {
        let messages = request.messages.map { message in
            OpenAIMessage(role: message.role, content: message.content)
        }
        
        return OpenAIChatRequest(
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
    
    private func convertFromOpenAIResponse(_ response: OpenAIChatResponse) -> AIChatResponse {
        let choice = response.choices.first
        let message = choice?.message.map { openAIMessage in
            AIMessage(role: AIMessageRole(rawValue: openAIMessage.role) ?? .assistant, content: openAIMessage.content)
        } ?? AIMessage(role: .assistant, content: "")
        
        let usage = response.usage.map { openAIUsage in
            AIUsage(
                promptTokens: openAIUsage.promptTokens,
                completionTokens: openAIUsage.completionTokens,
                totalTokens: openAIUsage.totalTokens
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
            let streamResponse = try JSONDecoder().decode(OpenAIStreamResponse.self, from: data)
            
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
            print("🔥 Failed to decode OpenAI stream response: \(error)")
        }
    }
}