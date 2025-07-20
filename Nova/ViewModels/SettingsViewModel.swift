//
//  SettingsViewModel.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/15/25.
//

import Foundation
import SwiftUI

class SettingsViewModel: ObservableObject {
    private let appConfig = AppConfig.shared
    
    // MARK: - Published Properties
    
    // AI Provider Configuration
    @Published var aiProvider: AIProvider {
        didSet {
            appConfig.updateAIProvider(aiProvider)
        }
    }
    
    @Published var enableAIFallback: Bool {
        didSet {
            appConfig.enableAIFallback = enableAIFallback
            appConfig.saveConfiguration()
        }
    }
    
    @Published var aiProviderFallbackOrder: [AIProvider] {
        didSet {
            appConfig.aiProviderFallbackOrder = aiProviderFallbackOrder
            appConfig.saveConfiguration()
        }
    }
    
    // Whisper Configuration
    @Published var whisperModelSize: WhisperConfiguration.ModelSize {
        didSet {
            appConfig.whisperModelSize = whisperModelSize
            appConfig.whisperModelName = whisperModelSize.modelFileName
            appConfig.saveConfiguration()
        }
    }
    
    @Published var enableBackgroundLoading: Bool {
        didSet {
            appConfig.enableBackgroundLoading = enableBackgroundLoading
            appConfig.saveConfiguration()
        }
    }
    
    @Published var maxAudioDurationSeconds: Double {
        didSet {
            appConfig.maxAudioDurationSeconds = maxAudioDurationSeconds
            appConfig.saveConfiguration()
        }
    }
    
    @Published var audioSampleRate: Int {
        didSet {
            appConfig.audioSampleRate = audioSampleRate
            appConfig.saveConfiguration()
        }
    }
    
    @Published var audioChannels: Int {
        didSet {
            appConfig.audioChannels = audioChannels
            appConfig.saveConfiguration()
        }
    }
    
    // UI Configuration
    @Published var showModelLoadingProgress: Bool {
        didSet {
            appConfig.showModelLoadingProgress = showModelLoadingProgress
            appConfig.saveConfiguration()
        }
    }
    
    @Published var enableMicrophoneLoadingIndicator: Bool {
        didSet {
            appConfig.enableMicrophoneLoadingIndicator = enableMicrophoneLoadingIndicator
            appConfig.saveConfiguration()
        }
    }
    
    // MARK: - Initialization
    
    init() {
        // Initialize with current AppConfig values
        self.aiProvider = appConfig.aiProvider
        self.enableAIFallback = appConfig.enableAIFallback
        self.aiProviderFallbackOrder = appConfig.aiProviderFallbackOrder
        self.whisperModelSize = appConfig.whisperModelSize
        self.enableBackgroundLoading = appConfig.enableBackgroundLoading
        self.maxAudioDurationSeconds = appConfig.maxAudioDurationSeconds
        self.audioSampleRate = appConfig.audioSampleRate
        self.audioChannels = appConfig.audioChannels
        self.showModelLoadingProgress = appConfig.showModelLoadingProgress
        self.enableMicrophoneLoadingIndicator = appConfig.enableMicrophoneLoadingIndicator
    }
    
    // MARK: - API Key Management
    
    func getApiKey(for provider: AIProvider) -> String {
        return appConfig.getApiKey(for: provider)
    }
    
    func updateApiKey(for provider: AIProvider, key: String) {
        appConfig.updateApiKey(for: provider, key: key)
    }
    
    // MARK: - Configuration Management
    
    func resetToDefaults() {
        appConfig.resetToDefaults()
        
        // Update local properties to reflect the reset
        Task { @MainActor in
            self.aiProvider = self.appConfig.aiProvider
            self.enableAIFallback = self.appConfig.enableAIFallback
            self.aiProviderFallbackOrder = self.appConfig.aiProviderFallbackOrder
            self.whisperModelSize = self.appConfig.whisperModelSize
            self.enableBackgroundLoading = self.appConfig.enableBackgroundLoading
            self.maxAudioDurationSeconds = self.appConfig.maxAudioDurationSeconds
            self.audioSampleRate = self.appConfig.audioSampleRate
            self.audioChannels = self.appConfig.audioChannels
            self.showModelLoadingProgress = self.appConfig.showModelLoadingProgress
            self.enableMicrophoneLoadingIndicator = self.appConfig.enableMicrophoneLoadingIndicator
        }
    }
    
    var configFileLocation: String {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsPath.appendingPathComponent("AppConfig.json").path
    }
    
    // MARK: - Validation
    
    func validateApiKey(for provider: AIProvider, key: String) async -> Bool {
        // This would implement actual API validation
        // For now, just simulate a network call
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Basic validation - just check if key is not empty and has reasonable format
        switch provider {
        case .openai:
            return key.hasPrefix("sk-") && key.count > 20
        case .claude:
            return key.hasPrefix("sk-ant-") && key.count > 20
        case .mistral:
            return key.count > 10 // Mistral keys vary in format
        case .grok:
            return key.hasPrefix("xai-") && key.count > 20
        case .gemini:
            return key.count > 20 // Gemini keys vary in format
        case .ollama:
            return true // Ollama doesn't require API keys
        }
    }
    
    func isConfigurationValid() -> Bool {
        // Check if current provider has valid API key (if required)
        if aiProvider.requiresApiKey {
            let apiKey = getApiKey(for: aiProvider)
            return !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return true
    }
    
    func getConfigurationWarnings() -> [String] {
        var warnings: [String] = []
        
        // Check for missing API keys
        for provider in AIProvider.allCases where provider.requiresApiKey {
            let apiKey = getApiKey(for: provider)
            if apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                warnings.append("Missing API key for \(provider.displayName)")
            }
        }
        
        // Check for performance warnings
        if whisperModelSize == .large && enableBackgroundLoading {
            warnings.append("Large Whisper model with background loading may impact performance")
        }
        
        if maxAudioDurationSeconds > 1800 { // 30 minutes
            warnings.append("Very long audio duration may cause memory issues")
        }
        
        return warnings
    }
}