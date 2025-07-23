//
//  AIServiceRouter.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/15/25.
//

import Foundation
import SwiftUI
import Combine

/// Main router for AI services with provider switching and fallback logic
@MainActor
class AIServiceRouter: AIService, ObservableObject {
    @Published var currentProvider: AIProvider
    @Published var isConnected: Bool = false
    @Published var lastError: Error?
    
    private var isSwitchingProvider: Bool = false
    
    private var services: [AIProvider: AIService] = [:]
    private let config: AppConfig
    private let promptRouter: PromptRouter
    private let toolCallExecutor: ToolCallExecutor
    private var automationService: MacOSAutomationService?
    
    var currentModel: String {
        get { 
            // Get the current user model from AppConfig
            return config.getCurrentUserModel()
        }
        set { 
            // Validate that the model is compatible with the current provider
            let availableModels = currentProvider.availableModels
            guard availableModels.contains(where: { $0.id == newValue }) else {
                print("⚠️ Model \(newValue) not available for provider \(currentProvider.displayName)")
                return
            }
            
            // Update the current user model in AppConfig
            config.updateCurrentUserModel(newValue)
            
            // Update the underlying service directly in the services dictionary
            if let service = services[currentProvider] {
                var updatedService = service
                updatedService.currentModel = newValue
                services[currentProvider] = updatedService
                print("📝 Updated \(currentProvider.displayName) service model to \(newValue)")
            }
        }
    }
    
    var supportedModels: [String] {
        return getCurrentService()?.supportedModels ?? []
    }
    
    init(config: AppConfig = .shared, promptRouter: PromptRouter? = nil) {
        self.config = config
        self.currentProvider = config.aiProvider
        self.promptRouter = promptRouter ?? PromptRouterService(config: config)
        
        // Initialize automation service directly since we're now @MainActor
        self.automationService = MacOSAutomationService()
        self.toolCallExecutor = ToolCallExecutor(automationService: self.automationService!)
        
        setupServices()
        
        // Set self-reference for AI calls in tool executor after initialization
        toolCallExecutor.setAIServiceRouter(self)
        
        // Listen for config changes
        config.$aiProvider
            .sink { [weak self] newProvider in
                guard let self = self else { return }
                
                // When provider changes, ensure model compatibility
                let currentModel = self.config.getCurrentUserModel()
                let newProviderModels = newProvider.availableModels
                
                if newProviderModels.contains(where: { $0.id == currentModel }) {
                    // Current model is compatible with new provider
                    self.switchProvider(to: newProvider, withModel: currentModel)
                } else {
                    // Current model not compatible, let switchProvider choose appropriate model
                    print("🔄 Provider change: Model \(currentModel) not compatible with \(newProvider.displayName)")
                    self.switchProvider(to: newProvider)
                }
            }
            .store(in: &cancellables)
        
        config.$currentUserModel
            .sink { [weak self] newModel in
                guard let self = self else { return }
                
                // Skip compatibility check if we're in the middle of a provider switch
                if self.isSwitchingProvider {
                    print("📝 🔄 Skipping compatibility check during provider switch for model \(newModel)")
                    return
                }
                
                // Only update the service if the model is compatible with the current provider
                let availableModels = self.currentProvider.availableModels
                guard availableModels.contains(where: { $0.id == newModel }) else {
                    print("⚠️ Config observer: Model \(newModel) not compatible with \(self.currentProvider.displayName), skipping service update")
                    return
                }
                
                // Update the underlying service directly in the services dictionary
                if let service = self.services[self.currentProvider] {
                    var updatedService = service
                    updatedService.currentModel = newModel
                    self.services[self.currentProvider] = updatedService
                    print("📝 🔄 Config change: Updated \(self.currentProvider.displayName) service model to \(newModel)")
                }
            }
            .store(in: &cancellables)
    }
    
    private var cancellables: Set<AnyCancellable> = []
    
    // MARK: - AIService Implementation
    
    func generateResponse(for message: String) async throws -> String {
        return try await executeWithFallback { service in
            try await service.generateResponse(for: message)
        }
    }
    
    /// Generate response with prompt routing - analyzes the prompt first to determine if tool calls are needed
    func generateResponseWithRouting(for message: String) async throws -> String {
        // First, use the prompt router to analyze the message
        do {
            let routerResponse = try await promptRouter.routePrompt(message, config: config)
            
            // Execute identified tool calls
            if !routerResponse.toolCalls.isEmpty {
                let executionResult = try await toolCallExecutor.executeToolCalls(routerResponse.toolCalls)
                return executionResult.summary
            }
            
            // If no tool calls needed, proceed with normal AI response
            return try await generateResponse(for: message)
            
        } catch {
            print("🤖 Prompt routing failed, falling back to normal response: \(error)")
            return try await generateResponse(for: message)
        }
    }
    
    func generateStreamingResponse(for message: String) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let service = try getCurrentServiceOrThrow()
                    let stream = service.generateStreamingResponse(for: message)
                    
                    for try await chunk in stream {
                        continuation.yield(chunk)
                    }
                    
                    Task { @MainActor in
                        self.isConnected = true
                        self.lastError = nil
                    }
                    
                    continuation.finish()
                } catch {
                    Task { @MainActor in
                        self.isConnected = false
                        self.lastError = error
                    }
                    
                    // Try fallback for streaming
                    if config.enableAIFallback {
                        await tryFallbackStreaming(for: message, continuation: continuation, excludingProvider: currentProvider)
                    } else {
                        continuation.finish(throwing: error)
                    }
                }
            }
        }
    }
    
    // MARK: - Provider Management
    
    func switchProvider(to provider: AIProvider, withModel modelId: String? = nil) {
        guard provider != currentProvider else { return }
        
        print("🔄 Switching AI provider from \(currentProvider.displayName) to \(provider.displayName)")
        
        Task { @MainActor in
            // Set flag to prevent config observer interference
            self.isSwitchingProvider = true
            
            // Store the old provider for logging
            let oldProvider = self.currentProvider
            
            // Atomically update both provider and model
            self.currentProvider = provider
            self.isConnected = false
            self.lastError = nil
            
            // Select the first available model for the new provider if current model is not compatible
            let providerModels = provider.availableModels
            let currentUserModel = config.getCurrentUserModel()
            
            let newModel: String
            if let requestedModel = modelId {
                // Use the specifically requested model if provided and valid
                if providerModels.contains(where: { $0.id == requestedModel }) {
                    newModel = requestedModel
                    print("📝 Using requested model \(newModel) for \(provider.displayName)")
                } else {
                    newModel = providerModels.first?.id ?? ""
                    print("📝 Requested model \(requestedModel) not available for \(provider.displayName), using \(newModel)")
                }
            } else if !providerModels.contains(where: { $0.id == currentUserModel }) {
                // Current model not compatible, select first available
                newModel = providerModels.first?.id ?? ""
                print("📝 Model \(currentUserModel) not available for \(provider.displayName), switching to \(newModel)")
            } else {
                // Keep current model
                newModel = currentUserModel
                print("📝 Keeping current model \(newModel) for \(provider.displayName)")
            }
            
            // Update the config
            config.updateCurrentUserModel(newModel)
            
            // Immediately update the service model to ensure consistency
            if let service = services[provider], !newModel.isEmpty {
                var updatedService = service
                updatedService.currentModel = newModel
                services[provider] = updatedService
                print("📝 ✅ Updated \(provider.displayName) service model to \(newModel)")
            }
            
            // Clear the switching flag after all updates are complete
            self.isSwitchingProvider = false
        }
        
        // Test connection
        Task {
            await testConnection()
        }
    }
    
    func testConnection() async {
        do {
            _ = try await generateResponse(for: "Hi")
            Task { @MainActor in
                self.isConnected = true
                self.lastError = nil
            }
        } catch {
            Task { @MainActor in
                self.isConnected = false
                self.lastError = error
            }
        }
    }
    
    func getProviderStatus(_ provider: AIProvider) -> AIProviderStatus {
        guard services[provider] != nil else {
            return .notConfigured
        }
        
        // Check if API key is available for cloud providers
        if provider.requiresApiKey {
            let apiKey = config.getApiKey(for: provider)
            if apiKey.isEmpty {
                return .missingApiKey
            }
        }
        
        return isConnected && currentProvider == provider ? .connected : .available
    }
    
    /// Get information about the current model
    func getCurrentModelInfo() -> AIModel? {
        let allModels = currentProvider.availableModels
        return allModels.first { $0.id == currentModel }
    }
    
    // MARK: - Private Methods
    
    private func setupServices() {
        // Always setup Ollama service
        services[.ollama] = OllamaService()
        
        // Setup cloud services if API keys are available
        updateCloudServices()
        
        // Listen for API key changes
        setupConfigObservers()
    }
    
    private func updateCloudServices() {
        // OpenAI
        let openaiKey = config.getApiKey(for: .openai)
        if !openaiKey.isEmpty {
            services[.openai] = OpenAIService(apiKey: openaiKey)
        } else {
            services.removeValue(forKey: .openai)
        }
        
        // Claude
        let claudeKey = config.getApiKey(for: .claude)
        if !claudeKey.isEmpty {
            services[.claude] = ClaudeService(apiKey: claudeKey)
        } else {
            services.removeValue(forKey: .claude)
        }
        
        // Mistral
        let mistralKey = config.getApiKey(for: .mistral)
        if !mistralKey.isEmpty {
            services[.mistral] = MistralService(apiKey: mistralKey)
        } else {
            services.removeValue(forKey: .mistral)
        }
        
        // Grok
        let grokKey = config.getApiKey(for: .grok)
        if !grokKey.isEmpty {
            // services[.grok] = GrokService(apiKey: grokKey) // When GrokService is implemented
        } else {
            services.removeValue(forKey: .grok)
        }
        
        // Gemini
        let geminiKey = config.getApiKey(for: .gemini)
        if !geminiKey.isEmpty {
            // services[.gemini] = GeminiService(apiKey: geminiKey) // When GeminiService is implemented
        } else {
            services.removeValue(forKey: .gemini)
        }
        
        // DeepSeek
        let deepSeekKey = config.getApiKey(for: .deepseek)
        if !deepSeekKey.isEmpty {
            services[.deepseek] = DeepSeekService(apiKey: deepSeekKey)
        } else {
            services.removeValue(forKey: .deepseek)
        }
    }
    
    private func setupConfigObservers() {
        // Observe AppConfig changes (API keys are now stored in Keychain)
        // We listen to AppConfig's objectWillChange since updateApiKey triggers it
        config.objectWillChange
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in 
                Task { @MainActor in
                    self?.updateCloudServices()
                }
            }
            .store(in: &cancellables)
    }
    
    public func getCurrentService() -> AIService? {
        return services[currentProvider]
    }
    
    private func getCurrentServiceOrThrow() throws -> AIService {
        guard let service = getCurrentService() else {
            throw AIServiceError.modelNotFound
        }
        return service
    }
    
    private func executeWithFallback<T>(_ operation: (AIService) async throws -> T) async throws -> T {
        do {
            let service = try getCurrentServiceOrThrow()
            let result = try await operation(service)
            
            Task { @MainActor in
                self.isConnected = true
                self.lastError = nil
            }
            
            return result
        } catch {
            Task { @MainActor in
                self.isConnected = false
                self.lastError = error
            }
            
            print("🔥 AI request failed with \(currentProvider.displayName): \(error)")
            
            // Try fallback if enabled
            if config.enableAIFallback {
                return try await tryFallback(operation, excludingProvider: currentProvider)
            } else {
                throw error
            }
        }
    }
    
    private func tryFallback<T>(_ operation: (AIService) async throws -> T, excludingProvider: AIProvider) async throws -> T {
        let fallbackProviders = config.aiProviderFallbackOrder.filter { $0 != excludingProvider }
        
        for provider in fallbackProviders {
            guard var service = services[provider] else {
                print("⚠️ Fallback provider \(provider.displayName) not available")
                continue
            }
            
            do {
                print("🔄 Trying fallback provider: \(provider.displayName)")
                
                // Set an appropriate model for this provider before making the request
                let availableModels = provider.availableModels
                if let firstModel = availableModels.first {
                    service.currentModel = firstModel.id
                    print("📝 Using model \(firstModel.id) for fallback provider \(provider.displayName)")
                }
                
                let result = try await operation(service)
                
                print("✅ Fallback successful with \(provider.displayName)")
                Task { @MainActor in
                    self.currentProvider = provider
                    // Update our current model to match the fallback provider's model
                    if let firstModel = availableModels.first {
                        self.config.updateCurrentUserModel(firstModel.id)
                    }
                    self.isConnected = true
                    self.lastError = nil
                }
                
                return result
            } catch {
                print("🔥 Fallback failed with \(provider.displayName): \(error)")
                continue
            }
        }
        
        throw AIServiceError.modelNotFound
    }
    
    private func tryFallbackStreaming(for message: String, continuation: AsyncThrowingStream<String, Error>.Continuation, excludingProvider: AIProvider) async {
        let fallbackProviders = config.aiProviderFallbackOrder.filter { $0 != excludingProvider }
        
        for provider in fallbackProviders {
            guard var service = services[provider] else {
                continue
            }
            
            do {
                print("🔄 Trying streaming fallback with \(provider.displayName)")
                
                // Set an appropriate model for this provider before making the request
                let availableModels = provider.availableModels
                if let firstModel = availableModels.first {
                    service.currentModel = firstModel.id
                    print("📝 Using model \(firstModel.id) for streaming fallback provider \(provider.displayName)")
                }
                
                let stream = service.generateStreamingResponse(for: message)
                
                for try await chunk in stream {
                    continuation.yield(chunk)
                }
                
                Task { @MainActor in
                    self.currentProvider = provider
                    // Update our current model to match the fallback provider's model
                    if let firstModel = availableModels.first {
                        self.config.updateCurrentUserModel(firstModel.id)
                    }
                    self.isConnected = true
                    self.lastError = nil
                }
                
                continuation.finish()
                return
            } catch {
                print("🔥 Streaming fallback failed with \(provider.displayName): \(error)")
                continue
            }
        }
        
        continuation.finish(throwing: AIServiceError.modelNotFound)
    }
    
    // MARK: - Tool Call Execution
    
    /// Get the automation service for external access
    func getAutomationService() -> MacOSAutomationService? {
        return automationService
    }
}

// MARK: - Supporting Types

enum AIProviderStatus {
    case notConfigured
    case missingApiKey
    case available
    case connected
    case error(Error)
    
    var displayText: String {
        switch self {
        case .notConfigured: return "Not Configured"
        case .missingApiKey: return "Missing API Key"
        case .available: return "Available"
        case .connected: return "Connected"
        case .error: return "Error"
        }
    }
    
    var isUsable: Bool {
        switch self {
        case .available, .connected: return true
        default: return false
        }
    }
}

// MARK: - Extensions

import Combine

extension AIServiceRouter {
    /// Convenience method to clear conversation history across all services
    func clearAllConversationHistory() {
        for (_, service) in services {
            if let ollamaService = service as? OllamaService {
                ollamaService.clearConversationHistory()
            } else if let openaiService = service as? OpenAIService {
                openaiService.clearConversationHistory()
            } else if let claudeService = service as? ClaudeService {
                claudeService.clearConversationHistory()
            } else if let mistralService = service as? MistralService {
                mistralService.clearConversationHistory()
            } else if let deepseekService = service as? DeepSeekService {
                deepseekService.clearConversationHistory()
            }
        }
    }
    
    /// Set system prompt across all services
    func setSystemPrompt(_ prompt: String) {
        for (_, service) in services {
            if let ollamaService = service as? OllamaService {
                ollamaService.setSystemPrompt(prompt)
            } else if let openaiService = service as? OpenAIService {
                openaiService.setSystemPrompt(prompt)
            } else if let claudeService = service as? ClaudeService {
                claudeService.setSystemPrompt(prompt)
            } else if let mistralService = service as? MistralService {
                mistralService.setSystemPrompt(prompt)
            } else if let deepseekService = service as? DeepSeekService {
                deepseekService.setSystemPrompt(prompt)
            }
        }
    }
}
