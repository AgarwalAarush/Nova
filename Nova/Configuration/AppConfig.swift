//
//  AppConfig.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/14/25.
//

import Foundation

/// AI Model definition
struct AIModel: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let provider: AIProvider
    let displayName: String
    let description: String
    let isRecommended: Bool
    let supportsImageInput: Bool
    let powerRank: Int
    
    init(id: String, name: String, provider: AIProvider, displayName: String, description: String, isRecommended: Bool = false, supportsImageInput: Bool = false, powerRank: Int = 50) {
        self.id = id
        self.name = name
        self.provider = provider
        self.displayName = displayName
        self.description = description
        self.isRecommended = isRecommended
        self.supportsImageInput = supportsImageInput
        self.powerRank = powerRank
    }
}

/// Whisper Model definition
struct WhisperModel: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let displayName: String
    let description: String
    let filePath: String
    let size: String
    let isSelected: Bool
    
    init(id: String, name: String, displayName: String, description: String, filePath: String, size: String, isSelected: Bool = false) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.description = description
        self.filePath = filePath
        self.size = size
        self.isSelected = isSelected
    }
}

/// Available AI service providers
enum AIProvider: String, CaseIterable, Codable {
    case ollama = "ollama"
    case openai = "openai" 
    case claude = "claude"
    case mistral = "mistral"
    case grok = "grok"
    case gemini = "gemini"
    case deepseek = "deepseek"
    
    var displayName: String {
        switch self {
        case .ollama: return "Ollama (Local)"
        case .openai: return "OpenAI"
        case .claude: return "Anthropic Claude"
        case .mistral: return "Mistral AI"
        case .grok: return "xAI Grok"
        case .gemini: return "Google Gemini"
        case .deepseek: return "DeepSeek"
        }
    }
    
    var requiresApiKey: Bool {
        switch self {
        case .ollama: return false
        case .openai, .claude, .mistral, .grok, .gemini, .deepseek: return true
        }
    }
    
    /// Get available models for this provider
    var availableModels: [AIModel] {
        switch self {
            case .openai:
                return [
                    AIModel(id: "gpt-4.1", name: "gpt-4.1", provider: .openai, displayName: "GPT-4.1", description: "Daily driver for coding tasks", isRecommended: true, supportsImageInput: true, powerRank: 8),
                    AIModel(id: "o3", name: "o3", provider: .openai, displayName: "o3", description: "Powerful, slow model for reasoning tasks", supportsImageInput: true, powerRank: 1),
                    AIModel(id: "gpt-4o", name: "gpt-4o", provider: .openai, displayName: "GPT-4o", description: "Fast, intelligent, multimodal daily-driver model", supportsImageInput: true, powerRank: 3),
                    AIModel(id: "o4-mini", name: "o4-mini", provider: .openai, displayName: "o4 Mini", description: "Multimodal quick reasoning model", supportsImageInput: true, powerRank: 16),
                ]
            case .claude:
                return [
                    AIModel(id: "claude-4-opus", name: "claude-4-opus", provider: .claude, displayName: "Claude 4 Opus", description: "Most powerful model for advanced coding", isRecommended: true, supportsImageInput: true, powerRank: 2),
                    AIModel(id: "claude-4-sonnet", name: "claude-4-sonnet", provider: .claude, displayName: "Claude 4 Sonnet", description: "Great for coding, reasoning, general use", supportsImageInput: true, powerRank: 11),
                    AIModel(id: "claude-3.5-sonnet-20240620", name: "claude-3.5-sonnet-20240620", provider: .claude, displayName: "Claude 3.5 Sonnet", description: "Previous generation's most intelligent model", supportsImageInput: true, powerRank: 6),
                    AIModel(id: "claude-3-opus-20240229", name: "claude-3-opus-20240229", provider: .claude, displayName: "Claude 3 Opus", description: "Most powerful Claude 3 family model", supportsImageInput: true, powerRank: 7),
                    AIModel(id: "claude-3-haiku-20240307", name: "claude-3-haiku-20240307", provider: .claude, displayName: "Claude 3 Haiku", description: "Fastest, most compact for instant response", supportsImageInput: true, powerRank: 17)
                ]
            case .grok:
                return [
                    AIModel(id: "grok-4", name: "grok-4", provider: .grok, displayName: "Grok 4", description: "Latest flagship model with large context", isRecommended: true, supportsImageInput: true, powerRank: 9),
                    AIModel(id: "grok-3", name: "grok-3", provider: .grok, displayName: "Grok 3", description: "Previous generation model, large context window", supportsImageInput: false, powerRank: 15),
                    AIModel(id: "grok-2", name: "grok-2", provider: .grok, displayName: "Grok 2", description: "Strong performance and reasoning capabilities", supportsImageInput: false, powerRank: 20)
                ]
            case .gemini:
                return [
                    AIModel(id: "gemini-2.5-pro", name: "gemini-2.5-pro", provider: .gemini, displayName: "Gemini 2.5 Pro", description: "Most advanced model for complex reasoning", isRecommended: true, supportsImageInput: true, powerRank: 4),
                    AIModel(id: "gemini-2.5-flash", name: "gemini-2.5-flash", provider: .gemini, displayName: "Gemini 2.5 Flash", description: "Best price-performance for well-rounded capabilities", supportsImageInput: true, powerRank: 12),
                    AIModel(id: "gemini-2.5-flash-lite", name: "gemini-2.5-flash-lite", provider: .gemini, displayName: "Gemini 2.5 Flash-Lite", description: "Most cost-effective and fastest 2.5 model", supportsImageInput: true, powerRank: 18)
                ]
            case .mistral:
                return [
                    AIModel(id: "mistral-large-2", name: "mistral-large-2", provider: .mistral, displayName: "Mistral Large 2", description: "Top-tier model for high-complexity tasks", isRecommended: true, supportsImageInput: false, powerRank: 5),
                    AIModel(id: "codestral-2", name: "codestral-2", provider: .mistral, displayName: "Codestral 2", description: "Cutting-edge language model for coding", supportsImageInput: false, powerRank: 14),
                    AIModel(id: "magistral-medium", name: "magistral-medium", provider: .mistral, displayName: "Magistral Medium", description: "Frontier-class model for advanced reasoning", supportsImageInput: false, powerRank: 10),
                    AIModel(id: "mistral-medium-3", name: "mistral-medium-3", provider: .mistral, displayName: "Mistral Medium 3", description: "Frontier-class model with multimodal capabilities", supportsImageInput: true, powerRank: 13),
                    AIModel(id: "mistral-small-3.2", name: "mistral-small-3.2", provider: .mistral, displayName: "Mistral Small 3.2", description: "Small, updated model with image understanding", supportsImageInput: true, powerRank: 19),
                    AIModel(id: "voxtral-small", name: "voxtral-small", provider: .mistral, displayName: "Voxtral Small", description: "Audio input for instruction-based use cases", supportsImageInput: false, powerRank: 21)
                ]
            case .deepseek:
                return [
                    AIModel(id: "deepseek-chat", name: "deepseek-v3", provider: .deepseek, displayName: "DeepSeek V3", description: "Latest and most capable DeepSeek model (V3-0324)", isRecommended: true, supportsImageInput: false, powerRank: 22),
                    AIModel(id: "deepseek-reasoner", name: "deepseek-r1", provider: .deepseek, displayName: "DeepSeek R1", description: "Reasoning-focused model with strong analytical capabilities (R1-0528)", supportsImageInput: false, powerRank: 23)
                ]
            case .ollama:
                return AppConfig.shared.getOllamaModels()
            }
    }
}

/// Centralized application configuration
class AppConfig: ObservableObject {
    static let shared = AppConfig()
    
    // MARK: - Ollama Model Cache
    
    /// Cache for detected Ollama models
    private var _cachedOllamaModels: [AIModel] = []
    private var _ollamaModelsCacheTimestamp: Date?
    private let ollamaModelsCacheTimeout: TimeInterval = 300 // 5 minutes
    
    // MARK: - Configuration Properties
    
    /// AI Provider Configuration
    @Published var aiProvider: AIProvider = .ollama
    @Published var enableAIFallback: Bool = true
    @Published var aiProviderFallbackOrder: [AIProvider] = [.ollama, .openai, .claude]
    
    /// API Keys are now stored securely in Keychain via KeychainService
    // Removed: API keys are no longer stored in AppConfig for security
    
    /// Model Selection Configuration
    @Published var selectedModels: Set<String> = ["gpt-4o", "claude-3-5-sonnet-20241022", "llama3.2"]
    @Published var defaultModel: String = "llama3.2"
    @Published var currentUserModel: String = "llama3.2"
    
    /// Whisper model configuration
    @Published var whisperModelName: String = "ggml-tiny.en"
    @Published var whisperModelSize: WhisperConfiguration.ModelSize = .tinyEn
    @Published var enableBackgroundLoading: Bool = true
    @Published var maxAudioDurationSeconds: Double = 30.0 * 60.0 // 30 minutes
    
    /// UI Configuration
    @Published var showModelLoadingProgress: Bool = true
    @Published var enableMicrophoneLoadingIndicator: Bool = true
    
    /// Performance Configuration
    @Published var audioSampleRate: Int = 16000
    @Published var audioChannels: Int = 1
    
    /// Automation Configuration
    @Published var enableSystemAutomation: Bool = false
    @Published var automationPermissionsGranted: Bool = false
    @Published var allowBrightnessControl: Bool = true
    @Published var allowApplicationControl: Bool = true
    @Published var allowWindowManagement: Bool = false
    @Published var allowSystemControl: Bool = false
    @Published var automationTimeoutSeconds: Double = 10.0
    
    /// User Preferences (Memory) Configuration
    @Published var userPreferences: [String] = []
    
    /// Window Management Configuration
    @Published var enableWindowPinning: Bool = false
    
    // MARK: - Private Properties
    
    private let configFileName = "AppConfig.json"
    private var configFileURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsPath.appendingPathComponent(configFileName)
    }
    
    private init() {
        loadConfiguration()
    }
    
    // MARK: - API Key Migration
    
    /// Migrate API keys from old JSON config to Keychain (one-time operation)
    private func migrateAPIKeysToKeychainIfNeeded(from config: ConfigData) {
        // Check if we have any old-style API keys in the config
        // This handles backwards compatibility with older config files
        let hasLegacyKeys = false // Will be true if we find keys in old config
        
        if hasLegacyKeys {
            print("🔐 Found legacy API keys, migrating to Keychain...")
            // Migration logic would go here if needed
        }
    }
    
    // MARK: - Configuration Management
    
    /// Load configuration from file or create default
    func loadConfiguration() {
        guard FileManager.default.fileExists(atPath: configFileURL.path) else {
            print("📝 No config file found, using defaults")
            saveConfiguration() // Create default config file
            return
        }
        
        do {
            let data = try Data(contentsOf: configFileURL)
            let config = try JSONDecoder().decode(ConfigData.self, from: data)
            
            // Apply loaded configuration
            aiProvider = AIProvider(rawValue: config.aiProvider) ?? .ollama
            enableAIFallback = config.enableAIFallback
            aiProviderFallbackOrder = config.aiProviderFallbackOrder.compactMap(AIProvider.init(rawValue:))
            // API keys are now handled by KeychainService - migrate if needed
            migrateAPIKeysToKeychainIfNeeded(from: config)
            selectedModels = Set(config.selectedModels)
            defaultModel = config.defaultModel
            currentUserModel = config.currentUserModel
            whisperModelName = config.whisperModelName
            whisperModelSize = WhisperConfiguration.ModelSize(rawValue: config.whisperModelSize) ?? .tinyEn
            enableBackgroundLoading = config.enableBackgroundLoading
            maxAudioDurationSeconds = config.maxAudioDurationSeconds
            showModelLoadingProgress = config.showModelLoadingProgress
            enableMicrophoneLoadingIndicator = config.enableMicrophoneLoadingIndicator
            audioSampleRate = config.audioSampleRate
            audioChannels = config.audioChannels
            enableSystemAutomation = config.enableSystemAutomation
            automationPermissionsGranted = config.automationPermissionsGranted
            allowBrightnessControl = config.allowBrightnessControl
            allowApplicationControl = config.allowApplicationControl
            allowWindowManagement = config.allowWindowManagement
            allowSystemControl = config.allowSystemControl
            automationTimeoutSeconds = config.automationTimeoutSeconds
            userPreferences = config.userPreferences
            enableWindowPinning = config.enableWindowPinning
            
            print("📝 ✅ Configuration loaded from: \(configFileURL.path)")
            
        } catch {
            print("📝 ❌ Failed to load configuration: \(error)")
            print("📝 Using default configuration")
        }
    }
    
    /// Save current configuration to file
    func saveConfiguration() {
        let config = ConfigData(
            aiProvider: aiProvider.rawValue,
            enableAIFallback: enableAIFallback,
            aiProviderFallbackOrder: aiProviderFallbackOrder.map(\.rawValue),
            selectedModels: Array(selectedModels),
            defaultModel: defaultModel,
            currentUserModel: currentUserModel,
            whisperModelName: whisperModelName,
            whisperModelSize: whisperModelSize.rawValue,
            enableBackgroundLoading: enableBackgroundLoading,
            maxAudioDurationSeconds: maxAudioDurationSeconds,
            showModelLoadingProgress: showModelLoadingProgress,
            enableMicrophoneLoadingIndicator: enableMicrophoneLoadingIndicator,
            audioSampleRate: audioSampleRate,
            audioChannels: audioChannels,
            enableSystemAutomation: enableSystemAutomation,
            automationPermissionsGranted: automationPermissionsGranted,
            allowBrightnessControl: allowBrightnessControl,
            allowApplicationControl: allowApplicationControl,
            allowWindowManagement: allowWindowManagement,
            allowSystemControl: allowSystemControl,
            automationTimeoutSeconds: automationTimeoutSeconds,
            userPreferences: userPreferences,
            enableWindowPinning: enableWindowPinning
        )
        
        do {
            let data = try JSONEncoder().encode(config)
            try data.write(to: configFileURL)
            print("📝 ✅ Configuration saved to: \(configFileURL.path)")
        } catch {
            print("📝 ❌ Failed to save configuration: \(error)")
        }
    }
    
    /// Reset to default configuration
    func resetToDefaults() {
        aiProvider = .ollama
        enableAIFallback = true
        aiProviderFallbackOrder = [.ollama, .openai, .claude]
        // Clear API keys from Keychain
        _ = KeychainService.shared.clearAllAPIKeys()
        selectedModels = ["gpt-4o", "claude-3-5-sonnet-20241022", "llama3.2"]
        defaultModel = "llama3.2"
        currentUserModel = "llama3.2"
        whisperModelName = "ggml-tiny.en"
        whisperModelSize = .tinyEn
        enableBackgroundLoading = true
        maxAudioDurationSeconds = 30.0 * 60.0
        showModelLoadingProgress = true
        enableMicrophoneLoadingIndicator = true
        audioSampleRate = 16000
        audioChannels = 1
        enableSystemAutomation = false
        automationPermissionsGranted = false
        allowBrightnessControl = true
        allowApplicationControl = true
        allowWindowManagement = false
        allowSystemControl = false
        automationTimeoutSeconds = 10.0
        userPreferences = []
        enableWindowPinning = false
        
        saveConfiguration()
    }
    
    /// Update whisper model and save
    func updateWhisperModel(name: String, size: WhisperConfiguration.ModelSize) {
        whisperModelName = name
        whisperModelSize = size
        saveConfiguration()
    }
    
    /// Update AI provider and save
    func updateAIProvider(_ provider: AIProvider) {
        aiProvider = provider
        saveConfiguration()
    }
    
    /// Update API key for specific provider and save
    func updateApiKey(for provider: AIProvider, key: String) {
        guard provider.requiresApiKey else { return }
        
        if key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // Delete the key if empty
            _ = KeychainService.shared.deleteAPIKey(for: provider)
        } else {
            // Store the key securely
            _ = KeychainService.shared.storeAPIKey(key, for: provider)
        }
        
        // Notify observers that API key status may have changed
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    /// Get API key for specific provider
    func getApiKey(for provider: AIProvider) -> String {
        guard provider.requiresApiKey else { return "" }
        return KeychainService.shared.getAPIKey(for: provider)
    }
    
    /// Get model by its ID
    func getModel(byId modelId: String) -> AIModel? {
        return getAllAvailableModels().first { $0.id == modelId }
    }
    
    // MARK: - Model Management
    
    /// Get all available models across all providers
    func getAllAvailableModels() -> [AIModel] {
        return AIProvider.allCases.flatMap { $0.availableModels }
    }
    
    /// Get available models based on current API key configuration
    func getAccessibleModels() -> [AIModel] {
        return AIProvider.allCases.flatMap { provider in
            if provider.requiresApiKey {
                let apiKey = getApiKey(for: provider)
                return apiKey.isEmpty ? [] : provider.availableModels
            } else {
                return provider.availableModels
            }
        }
    }
    
    /// Get currently selected models that are accessible
    func getSelectedAccessibleModels() -> [AIModel] {
        let accessibleModels = getAccessibleModels()
        return accessibleModels.filter { selectedModels.contains($0.id) }
    }
    
    /// Update model selection
    func updateModelSelection(_ models: Set<String>) {
        selectedModels = models
        saveConfiguration()
    }
    
    /// Update default model
    func updateDefaultModel(_ modelId: String) {
        defaultModel = modelId
        saveConfiguration()
    }
    
    /// Find which provider owns a given model
    func findProviderForModel(_ modelId: String) -> AIProvider? {
        for provider in AIProvider.allCases {
            if provider.availableModels.contains(where: { $0.id == modelId }) {
                return provider
            }
        }
        return nil
    }
    
    /// Update current user model (the model currently being used)
    func updateCurrentUserModel(_ modelId: String) {
        // Find the provider that owns this model
        if let modelProvider = findProviderForModel(modelId) {
            // Update provider if it's different from current
            if modelProvider != aiProvider {
                print("📝 🔄 Auto-switching provider from \(aiProvider.displayName) to \(modelProvider.displayName) for model \(modelId)")
                aiProvider = modelProvider
            }
        } else {
            print("⚠️ Warning: Model \(modelId) not found in any provider's available models")
        }
        
        currentUserModel = modelId
        saveConfiguration()
    }
    
    /// Get current user model - the model that should be used for AI requests
    func getCurrentUserModel() -> String {
        return currentUserModel
    }
    
    /// Check if a specific model is accessible
    func isModelAccessible(_ modelId: String) -> Bool {
        return getAccessibleModels().contains { $0.id == modelId }
    }
    
    // MARK: - Ollama Model Management
    
    /// Get Ollama models with caching
    internal func getOllamaModels() -> [AIModel] {
        // Check if cache is valid
        if let cacheTimestamp = _ollamaModelsCacheTimestamp,
           Date().timeIntervalSince(cacheTimestamp) < ollamaModelsCacheTimeout,
           !_cachedOllamaModels.isEmpty {
            return _cachedOllamaModels
        }
        
        // Refresh cache
        refreshOllamaModelsCache()
        
        // Return cached models or fallback
        return _cachedOllamaModels.isEmpty ? getDefaultOllamaModels() : _cachedOllamaModels
    }
    
    /// Refresh the Ollama models cache
    private func refreshOllamaModelsCache() {
        let detectedModels = OllamaModelDetectionService.shared.detectInstalledModels()
        let aiModels = OllamaModelDetectionService.shared.convertToAIModels(detectedModels)
        
        _cachedOllamaModels = aiModels
        _ollamaModelsCacheTimestamp = Date()
        
        print("🔄 Refreshed Ollama models cache: \(aiModels.count) models detected")
    }
    
    /// Get default Ollama models as fallback
    private func getDefaultOllamaModels() -> [AIModel] {
        return [
            AIModel(id: "llama3.2", name: "llama3.2", provider: .ollama, displayName: "Llama 3.2", description: "Meta's latest local model", isRecommended: true),
            AIModel(id: "codellama", name: "codellama", provider: .ollama, displayName: "Code Llama", description: "Specialized for coding tasks"),
            AIModel(id: "mistral", name: "mistral", provider: .ollama, displayName: "Mistral 7B", description: "Efficient local model")
        ]
    }
    
    /// Force refresh of Ollama models
    func refreshOllamaModels() {
        refreshOllamaModelsCache()
        
        // Notify observers of the change
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    /// Check if Ollama models cache is stale
    func isOllamaModelsCacheStale() -> Bool {
        guard let cacheTimestamp = _ollamaModelsCacheTimestamp else {
            return true
        }
        return Date().timeIntervalSince(cacheTimestamp) >= ollamaModelsCacheTimeout
    }
    
    // MARK: - Whisper Model Management
    
    /// Get available Whisper models from Resources/Models directory
    func getAvailableWhisperModels() -> [WhisperModel] {
        // First, try to get models from the project directory (for development)
        if let projectPath = Bundle.main.resourcePath?.replacingOccurrences(of: "/Nova.app/Contents/Resources", with: "") {
            let devModelsPath = "\(projectPath)/Nova/Resources/Models"
            print("Checking development models path: \(devModelsPath)")
            
            if FileManager.default.fileExists(atPath: devModelsPath) {
                do {
                    let contents = try FileManager.default.contentsOfDirectory(atPath: devModelsPath)
                    let binFiles = contents.filter { $0.hasSuffix(".bin") }
                    print("Found .bin files in development: \(binFiles)")
                    
                    if !binFiles.isEmpty {
                        return binFiles.compactMap { fileName in
                            let modelName = String(fileName.dropLast(4)) // Remove .bin extension
                            let displayName = modelName.hasPrefix("ggml-") ? String(modelName.dropFirst(5)) : modelName
                            
                            let size = getModelSize(for: modelName)
                            let description = getModelDescription(for: displayName)
                            
                            return WhisperModel(
                                id: modelName,
                                name: modelName,
                                displayName: displayName.capitalized,
                                description: description,
                                filePath: "\(devModelsPath)/\(fileName)",
                                size: size,
                                isSelected: modelName == whisperModelName
                            )
                        }.sorted { $0.displayName < $1.displayName }
                    }
                } catch {
                    print("Failed to read development models directory: \(error)")
                }
            }
        }
        
        // Try multiple possible bundle paths for the models
        let possiblePaths = [
            Bundle.main.path(forResource: "Resources/Models", ofType: nil),
            Bundle.main.resourcePath.map { "\($0)/Resources/Models" },
            Bundle.main.resourcePath.map { "\($0)/Models" }
        ].compactMap { $0 }
        
        for modelsDirectoryPath in possiblePaths {
            print("Checking bundle models path: \(modelsDirectoryPath)")
            
            guard FileManager.default.fileExists(atPath: modelsDirectoryPath) else {
                print("Bundle path does not exist: \(modelsDirectoryPath)")
                continue
            }
            
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: modelsDirectoryPath)
                print("Found files in bundle directory: \(contents)")
                let binFiles = contents.filter { $0.hasSuffix(".bin") }
                print("Found .bin files in bundle: \(binFiles)")
                
                if !binFiles.isEmpty {
                    return binFiles.compactMap { fileName in
                        let modelName = String(fileName.dropLast(4)) // Remove .bin extension
                        let displayName = modelName.hasPrefix("ggml-") ? String(modelName.dropFirst(5)) : modelName
                        
                        let size = getModelSize(for: modelName)
                        let description = getModelDescription(for: displayName)
                        
                        return WhisperModel(
                            id: modelName,
                            name: modelName,
                            displayName: displayName.capitalized,
                            description: description,
                            filePath: "\(modelsDirectoryPath)/\(fileName)",
                            size: size,
                            isSelected: modelName == whisperModelName
                        )
                    }.sorted { $0.displayName < $1.displayName }
                }
            } catch {
                print("Failed to read bundle models directory \(modelsDirectoryPath): \(error)")
                continue
            }
        }
        
        print("No models found in any directory")
        return []
    }
    
    /// Update selected Whisper model
    func updateWhisperModelSelection(_ modelName: String) {
        whisperModelName = modelName
        // Update the model size enum to match
        if let modelSize = WhisperConfiguration.ModelSize.allCases.first(where: { $0.modelFileName == modelName }) {
            whisperModelSize = modelSize
        }
        saveConfiguration()
    }
    
    private func getModelSize(for modelName: String) -> String {
        let sizeMap: [String: String] = [
            "ggml-tiny": "~39 MB",
            "ggml-tiny.en": "~39 MB", 
            "ggml-base": "~142 MB",
            "ggml-base.en": "~142 MB",
            "ggml-small": "~488 MB",
            "ggml-small.en": "~488 MB",
            "ggml-medium": "~1.5 GB",
            "ggml-medium.en": "~1.5 GB",
            "ggml-large": "~2.9 GB"
        ]
        return sizeMap[modelName] ?? "Unknown size"
    }
    
    private func getModelDescription(for displayName: String) -> String {
        let descriptions: [String: String] = [
            "tiny": "Fastest, lowest accuracy",
            "tiny.en": "Fastest, English only",
            "base": "Good balance of speed and accuracy",
            "base.en": "Good balance, English only",
            "small": "Better accuracy, moderate speed",
            "small.en": "Better accuracy, English only",
            "medium": "High accuracy, slower processing",
            "medium.en": "High accuracy, English only",
            "large": "Best accuracy, slowest processing"
        ]
        return descriptions[displayName.lowercased()] ?? "Whisper speech recognition model"
    }
}

// MARK: - Configuration Data Structure

private struct ConfigData: Codable {
    let aiProvider: String
    let enableAIFallback: Bool
    let aiProviderFallbackOrder: [String]
    // API keys removed for security - now stored in Keychain
    let selectedModels: [String]
    let defaultModel: String
    let currentUserModel: String
    let whisperModelName: String
    let whisperModelSize: String
    let enableBackgroundLoading: Bool
    let maxAudioDurationSeconds: Double
    let showModelLoadingProgress: Bool
    let enableMicrophoneLoadingIndicator: Bool
    let audioSampleRate: Int
    let audioChannels: Int
    let enableSystemAutomation: Bool
    let automationPermissionsGranted: Bool
    let allowBrightnessControl: Bool
    let allowApplicationControl: Bool
    let allowWindowManagement: Bool
    let allowSystemControl: Bool
    let automationTimeoutSeconds: Double
    let userPreferences: [String]
    let enableWindowPinning: Bool
}

// MARK: - Extensions

extension WhisperConfiguration.ModelSize {
    init?(rawValue: String) {
        switch rawValue.lowercased() {
        case "tiny": self = .tiny
        case "tiny.en": self = .tinyEn
        case "base": self = .base
        case "base.en": self = .baseEn
        case "small": self = .small
        case "small.en": self = .smallEn
        case "medium": self = .medium
        case "medium.en": self = .mediumEn
        case "large": self = .large
        default: return nil
        }
    }
}

// MARK: - Automation Tools JSON Schema

extension AppConfig {
    
    /// Get JSON schema for all available automation tools
    static var automationToolsSchema: String {
        guard let url = Bundle.main.url(forResource: "tools", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let jsonString = String(data: data, encoding: .utf8) else {
            print("⚠️ Failed to load tools.json from bundle, using fallback")
            return "{}"
        }
        return jsonString
    }
    
    /// Get parsed automation tools schema as dictionary
    var automationToolsDict: [String: Any] {
        guard let data = Self.automationToolsSchema.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return json
    }
    
    /// Get automation tools for a specific category
    func getAutomationTools(for category: String) -> [[String: Any]] {
        guard let categories = automationToolsDict["categories"] as? [String: Any],
              let categoryData = categories[category] as? [String: Any],
              let tools = categoryData["tools"] as? [[String: Any]] else {
            return []
        }
        return tools
    }
    
    /// Get all automation tool names
    var allAutomationToolNames: [String] {
        guard let categories = automationToolsDict["categories"] as? [String: Any] else {
            return []
        }
        
        var toolNames: [String] = []
        for (_, categoryData) in categories {
            if let categoryDict = categoryData as? [String: Any],
               let tools = categoryDict["tools"] as? [[String: Any]] {
                for tool in tools {
                    if let name = tool["name"] as? String {
                        toolNames.append(name)
                    }
                }
            }
        }
        return toolNames
    }
    
    /// Check if a tool is available based on current permissions
    func isAutomationToolAvailable(_ toolName: String) -> Bool {
        // This would need to be implemented based on current permission status
        // For now, return true if automation is enabled
        return enableSystemAutomation && automationPermissionsGranted
    }
    
    // MARK: - User Preferences (Memory) Management
    
    /// Add a new user preference to memory
    func addUserPreference(_ preference: String) {
        guard !preference.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let trimmedPreference = preference.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Avoid duplicates
        if !userPreferences.contains(trimmedPreference) {
            userPreferences.append(trimmedPreference)
            saveConfiguration()
        }
    }
    
    /// Update user preferences list
    func updateUserPreferences(_ preferences: [String]) {
        let cleanedPreferences = preferences
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        userPreferences = cleanedPreferences
        saveConfiguration()
    }
    
    /// Remove a specific user preference
    func removeUserPreference(_ preference: String) {
        userPreferences.removeAll { $0 == preference }
        saveConfiguration()
    }
    
    /// Clear all user preferences
    func clearUserPreferences() {
        userPreferences.removeAll()
        saveConfiguration()
    }
    
    /// Get current user preferences
    func getUserPreferences() -> [String] {
        return userPreferences
    }
}
