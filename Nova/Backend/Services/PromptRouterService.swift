//
//  PromptRouterService.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/17/25.
//

import Foundation

/// Helper for decoding heterogeneous JSON values
struct AnyCodableValue: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let arrayValue = try? container.decode([AnyCodableValue].self) {
            value = arrayValue.map { $0.value }
        } else if let dictionaryValue = try? container.decode([String: AnyCodableValue].self) {
            value = dictionaryValue.mapValues { $0.value }
        } else {
            throw DecodingError.typeMismatch(AnyCodableValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unable to decode value"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let arrayValue as [Any]:
            let codableArray = arrayValue.map { AnyCodableValue($0) }
            try container.encode(codableArray)
        case let dictionaryValue as [String: Any]:
            let codableDictionary = dictionaryValue.mapValues { AnyCodableValue($0) }
            try container.encode(codableDictionary)
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unable to encode value"))
        }
    }
}

/// Tool call representation for prompt routing
struct ToolCall: Codable {
    let name: String
    let parameters: [String: Any]
    
    enum CodingKeys: String, CodingKey {
        case name
        case parameters
    }
    
    init(name: String, parameters: [String: Any] = [:]) {
        self.name = name
        self.parameters = parameters
    }
    
    // Custom encoding for Any type
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        
        // Convert parameters to JSON data and then to string for encoding
        let jsonData = try JSONSerialization.data(withJSONObject: parameters)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
        try container.encode(jsonString, forKey: .parameters)
    }
    
    // Custom decoding for Any type
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        
        // Try to decode parameters as a dictionary object first (new format)
        if let parametersValue = try? container.decode([String: AnyCodableValue].self, forKey: .parameters) {
            // Convert AnyCodableValue dictionary to [String: Any]
            parameters = parametersValue.mapValues { $0.value }
        } else {
            // Fall back to string format (legacy format)
            let jsonString = try container.decode(String.self, forKey: .parameters)
            let jsonData = jsonString.data(using: .utf8) ?? Data()
            parameters = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] ?? [:]
        }
    }
}

/// Response structure for prompt routing
struct PromptRouterResponse: Codable {
    let toolCalls: [ToolCall]
    let reasoning: String?
    let requiresUserInput: Bool
    let estimatedExecutionTime: Double?
    
    enum CodingKeys: String, CodingKey {
        case toolCalls
        case reasoning
        case requiresUserInput
        case estimatedExecutionTime
    }
    
    init(toolCalls: [ToolCall], reasoning: String? = nil, requiresUserInput: Bool = false, estimatedExecutionTime: Double? = nil) {
        self.toolCalls = toolCalls
        self.reasoning = reasoning
        self.requiresUserInput = requiresUserInput
        self.estimatedExecutionTime = estimatedExecutionTime
    }
    
    // Custom decoding to handle missing optional fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        toolCalls = try container.decode([ToolCall].self, forKey: .toolCalls)
        reasoning = try container.decodeIfPresent(String.self, forKey: .reasoning)
        requiresUserInput = try container.decodeIfPresent(Bool.self, forKey: .requiresUserInput) ?? false
        estimatedExecutionTime = try container.decodeIfPresent(Double.self, forKey: .estimatedExecutionTime)
    }
    
    // Custom encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(toolCalls, forKey: .toolCalls)
        try container.encodeIfPresent(reasoning, forKey: .reasoning)
        try container.encode(requiresUserInput, forKey: .requiresUserInput)
        try container.encodeIfPresent(estimatedExecutionTime, forKey: .estimatedExecutionTime)
    }
}

/// Protocol for prompt routing service
protocol PromptRouter {
    func routePrompt(_ prompt: String, config: AppConfig) async throws -> PromptRouterResponse
    func getSimplestModel(for provider: AIProvider) -> AIModel?
    func formatToolsSchema(_ schema: String) -> String
}

/// Implementation of prompt routing service
class PromptRouterService: PromptRouter {
    private let config: AppConfig
    private var aiServices: [AIProvider: AIService] = [:]
    
    init(config: AppConfig = .shared) {
        self.config = config
        setupAIServices()
    }
    
    /// Setup AI services for prompt routing
    private func setupAIServices() {
        // Initialize services for each provider
        aiServices[.ollama] = OllamaService()
        
        // Only setup cloud services if API keys are available
        let openaiKey = config.getApiKey(for: .openai)
        if !openaiKey.isEmpty {
            aiServices[.openai] = OpenAIService(apiKey: openaiKey)
        }
        
        let claudeKey = config.getApiKey(for: .claude)
        if !claudeKey.isEmpty {
            aiServices[.claude] = ClaudeService(apiKey: claudeKey)
        }
        
        let mistralKey = config.getApiKey(for: .mistral)
        if !mistralKey.isEmpty {
            aiServices[.mistral] = MistralService(apiKey: mistralKey)
        }

        let deepseekKey = config.getApiKey(for: .deepseek)
        if !deepseekKey.isEmpty {
            aiServices[.deepseek] = DeepSeekService(apiKey: deepseekKey)
        }
    }
    
    /// Route a prompt to generate tool calls
    func routePrompt(_ prompt: String, config: AppConfig) async throws -> PromptRouterResponse {

        // Get the AI service for the current provider
        guard let aiService = aiServices[config.aiProvider] else {
            print("🚨 Service not available for provider \(config.aiProvider.displayName)")
            throw PromptRouterError.serviceNotAvailable
        }

        // Use current model but validate compatibility as defensive programming
        let currentModel = AppConfig.shared.getCurrentUserModel()
        let availableModels = config.aiProvider.availableModels
        
        // Defensive check: ensure current model is compatible with current provider
        guard availableModels.contains(where: { $0.id == currentModel }) else {
            print("🚨 MISMATCH: Model '\(currentModel)' not compatible with provider '\(config.aiProvider.displayName)'")
            print("Available models: \(availableModels.map { $0.id }.joined(separator: ", "))")
            print("This indicates a configuration synchronization issue that should be fixed at the source")
            throw PromptRouterError.noAvailableModel
        }

        var service = aiService
        service.currentModel = currentModel
        print("🔧 Using model \(currentModel) with provider \(config.aiProvider.displayName) for prompt routing")
        
        // Format the routing prompt
        let routingPrompt = formatRoutingPrompt(userPrompt: prompt, config: config)

        // TODO: find a better way to route calls; currently this kneecaps the purpose of @AIServiceRouter
        // AIServiceRouter routes here, which then calls back to AISerivceRouter -> probably better to have
        // a dependently rather than a circular call chain

        // Call the AI service to get tool calls
        let response = try await service.generateResponse(for: routingPrompt)

        print("Model Response: \(response)")

        // Parse the response to extract tool calls
        return try parseToolCallsResponse(response)
    }
    
    /// Get the simplest model (highest powerRank) for a provider
    func getSimplestModel(for provider: AIProvider) -> AIModel? {
        let models = provider.availableModels
        return models.max { $0.powerRank < $1.powerRank }
    }
    
    /// Format the tools schema for AI consumption
    func formatToolsSchema(_ schema: String) -> String {
        return """
        Here are the available automation tools you can use:
        
        \(schema)
        
        Important guidelines:
        - Only use tools that are explicitly defined in the schema above
        - Ensure all required parameters are provided
        - Use the exact tool names and parameter names as defined
        - Consider the execution order - some tools depend on others
        - If user preferences need to be updated, do that first
        """
    }
    
    /// Format the complete routing prompt
    private func formatRoutingPrompt(userPrompt: String, config: AppConfig) -> String {
        let toolsSchema = formatToolsSchema(AppConfig.automationToolsSchema)
        let currentPreferences = config.userPreferences.joined(separator: "\n- ")
        
        return """
        <system role>
        You are a prompt router that converts natural language requests into structured tool calls.
        
        <tools>
        \(toolsSchema)
        
        <user preferences>
        Current user preferences:
        \(currentPreferences.isEmpty ? "None" : "- " + currentPreferences)
        
        <user prompt>
        User request: "\(userPrompt)"
        
        <task>
        Your task is to analyze this request and return a JSON response with the following structure:
        {
            "toolCalls": [
                {
                    "name": "toolName",
                    "parameters": {
                        "paramName": "paramValue"
                    }
                }
            ],
        }
        
        <example request>
        Example for "context always refers to a screenshot of claude and my clipboard; retrieve context and run model" The following is what the prompt respose should look
        like; a series of tool calls:
        {
            "toolCalls": [
                {
                    "name": "updateUserPreferences",
                    "parameters": {
                        "preferences": ["context always refers to a screenshot of claude and user clipboard"]
                    }
                },
                {
                    "name": "captureScreen",
                    "parameters": {}
                },
                {
                    "name": "getClipboardContent",
                    "parameters": {}
                },
                {
                    "name": "requestModel",
                    "parameters": {
                        "prompt": "Please analyze this context: the screenshot shows the current screen state, and the clipboard contains relevant information. Help me understand what's happening and provide assistance.",
                        "maxTokens": 4000
                    }
                }
            ],
        }
        
        Return only the JSON response, no additional text.
        """
    }
    
    /// Parse the AI response to extract tool calls
    private func parseToolCallsResponse(_ response: String) throws -> PromptRouterResponse {
        // Clean the response to extract JSON
        let cleanedResponse = cleanJSONResponse(response)
        
        guard let jsonData = cleanedResponse.data(using: .utf8) else {
            throw PromptRouterError.invalidResponse
        }
        
        do {
            let parsedResponse = try JSONDecoder().decode(PromptRouterResponse.self, from: jsonData)
            return parsedResponse
        } catch {
            print("Failed to parse tool calls response: \(error)")
            print("Response was: \(cleanedResponse)")
            throw PromptRouterError.parsingFailed(error)
        }
    }
    
    /// Clean AI response to extract valid JSON
    private func cleanJSONResponse(_ response: String) -> String {
        // Remove code blocks and markdown formatting
        var cleaned = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Find JSON object boundaries
        if let startIndex = cleaned.firstIndex(of: "{"),
           let endIndex = cleaned.lastIndex(of: "}") {
            let jsonRange = startIndex...endIndex
            cleaned = String(cleaned[jsonRange])
        }
        
        return cleaned
    }
}

/// Errors that can occur during prompt routing
enum PromptRouterError: Error, LocalizedError {
    case noAvailableModel
    case serviceNotAvailable
    case invalidResponse
    case parsingFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .noAvailableModel:
            return "No available model found for prompt routing"
        case .serviceNotAvailable:
            return "AI service not available for prompt routing"
        case .invalidResponse:
            return "Invalid response from AI service"
        case .parsingFailed(let error):
            return "Failed to parse tool calls: \(error.localizedDescription)"
        }
    }
}

