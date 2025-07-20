//
//  SettingsView.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/15/25.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var currentView: SettingsViewType = .main
    
    enum SettingsViewType {
        case main
        case aiProvider
        case speechRecognition
        case interface
        case advanced
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if currentView != .main {
                navigationHeader
            }
            
            currentContentView
        }
        .frame(width: 600, height: 700)
        .background(AppColors.background)
    }
    
    private var navigationHeader: some View {
        HStack {
            Button(action: { currentView = .main }) {
                SwiftUI.Image(systemName: "arrow.left")
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.primaryText)
            }
            .buttonStyle(.plain)
            .help("Back to Settings")
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
    private var currentContentView: some View {
        Group {
            switch currentView {
            case .main:
                mainSettingsView
            case .aiProvider:
                AIProviderSettingsView(viewModel: viewModel)
            case .speechRecognition:
                WhisperSettingsView(viewModel: viewModel)
            case .interface:
                InterfaceSettingsView(viewModel: viewModel)
            case .advanced:
                AdvancedSettingsView(viewModel: viewModel)
            }
        }
    }
    
    private var mainSettingsView: some View {
        ScrollView {
            VStack(spacing: 20) {
//                settingsHeader
                accountSection
                appSection
                chatBarSection
            }
            .padding(20)
        }
        .background(AppColors.background)
    }
    
    private var settingsHeader: some View {
        HStack {
            SwiftUI.Text("Settings")
                .font(AppFonts.title2)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.primaryText)
            
            Spacer()
        }
        .padding(.bottom, 8)
    }
    
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SwiftUI.Text("Account")
                .font(AppFonts.callout)
                .foregroundColor(AppColors.primaryText)
            
            VStack(spacing: 0) {
                settingsRow(
                    icon: "envelope",
                    title: "Email",
                    value: "user@example.com",
                    showChevron: false
                )
                
                settingsRow(
                    icon: "phone",
                    title: "Phone number",
                    value: "+1234567890",
                    showChevron: false
                )
                
                settingsRow(
                    icon: "plus.square",
                    title: "Subscription",
                    value: "Nova Pro",
                    showChevron: false
                )
                
                settingsRow(
                    icon: "star.circle",
                    title: "Upgrade to Nova Pro",
                    value: nil,
                    showChevron: false
                )
                
                settingsRow(
                    icon: "person",
                    title: "AI Provider",
                    value: nil,
                    showChevron: true,
                    action: { currentView = .aiProvider }
                )
                
                settingsRow(
                    icon: "bell",
                    title: "Speech Recognition",
                    value: nil,
                    showChevron: true,
                    action: { currentView = .speechRecognition }
                )
                
                settingsRow(
                    icon: "shield",
                    title: "Interface",
                    value: nil,
                    showChevron: true,
                    action: { currentView = .interface }
                )
                
                settingsRow(
                    icon: "folder",
                    title: "Advanced",
                    value: nil,
                    showChevron: true,
                    action: { currentView = .advanced },
                    isLast: true
                )
            }
            .background(AppColors.textFieldBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.border, lineWidth: 1)
            )
        }
    }
    
    private var appSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SwiftUI.Text("App")
                .font(AppFonts.callout)
                .foregroundColor(AppColors.primaryText)
            
            VStack(spacing: 0) {
                settingsRow(
                    icon: "globe",
                    title: "App Language",
                    value: "English",
                    showChevron: true,
                    action: { }
                )
                
                settingsRow(
                    icon: "menubar.rectangle",
                    title: "Show in Menu Bar",
                    value: "Always",
                    showChevron: true,
                    action: { }
                )
                
                settingsRowWithToggle(
                    icon: "textformat.abc",
                    title: "Correct Spelling Automatically",
                    isOn: .constant(true)
                )
                
                settingsRowWithToggle(
                    icon: "link",
                    title: "Open Nova Links in Desktop App",
                    isOn: .constant(true)
                )
                
                settingsRow(
                    icon: "arrow.clockwise.circle",
                    title: "Check for Updates...",
                    value: nil,
                    showChevron: true,
                    action: { },
                    isLast: true
                )
            }
            .background(AppColors.textFieldBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.border, lineWidth: 1)
            )
        }
    }
    
    private var chatBarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SwiftUI.Text("Chat Bar")
                .font(AppFonts.callout)
                .foregroundColor(AppColors.primaryText)
            
            VStack(spacing: 0) {
                settingsRow(
                    icon: "rectangle.on.rectangle",
                    title: "Position on Screen",
                    value: "Remember Last Position",
                    showChevron: true,
                    action: { }
                )
                
                settingsRow(
                    icon: "arrow.clockwise",
                    title: "Reset to New Chat",
                    value: "After 10 minutes",
                    showChevron: true,
                    action: { },
                    isLast: true
                )
            }
            .background(AppColors.textFieldBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.border, lineWidth: 1)
            )
        }
    }
    
    private func settingsRow(
        icon: String,
        title: String,
        value: String? = nil,
        showChevron: Bool = false,
        action: (() -> Void)? = nil,
        isLast: Bool = false
    ) -> some View {
        Button(action: action ?? {}) {
            HStack(spacing: 12) {
                SwiftUI.Image(systemName: icon)
                    .frame(width: 20)
                    .foregroundColor(AppColors.secondaryText)
                
                SwiftUI.Text(title)
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.primaryText)
                
                Spacer()
                
                if let value = value {
                    SwiftUI.Text(value)
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.secondaryText)
                }
                
                if showChevron {
                    SwiftUI.Image(systemName: "chevron.right")
                        .font(AppFonts.footnote)
                        .foregroundColor(AppColors.secondaryText)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.clear)
            .overlay(
                Group {
                    if !isLast {
                        Rectangle()
                            .fill(AppColors.border)
                            .frame(height: 1)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                            .padding(.leading, 48)
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }
    
    private func settingsRowWithToggle(
        icon: String,
        title: String,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: 12) {
            SwiftUI.Image(systemName: icon)
                .frame(width: 20)
                .foregroundColor(AppColors.secondaryText)
            
            SwiftUI.Text(title)
                .font(AppFonts.body)
                .foregroundColor(AppColors.primaryText)
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .toggleStyle(SwitchToggleStyle())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.clear)
        .overlay(
            Rectangle()
                .fill(AppColors.border)
                .frame(height: 1)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.leading, 48)
        )
    }
}

// MARK: - AI Provider Settings

struct AIProviderSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var selectedModels: Set<String> = []
    @State private var defaultModel: String = ""
    @State private var isRefreshingOllamaModels: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
//                headerSection
                apiKeysSection
                modelSelectionSection
                fallbackSection
                Spacer()
            }
            .padding(20)
        }
        .background(AppColors.background)
        .onAppear {
            loadCurrentSettings()
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SwiftUI.Text("AI Provider Configuration")
                .font(AppFonts.title2)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.primaryText)
            
            SwiftUI.Text("Configure API keys and select which AI models you want to use")
                .font(AppFonts.body)
                .foregroundColor(AppColors.secondaryText)
        }
    }
    
    private var apiKeysSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SwiftUI.Text("API Keys")
                .font(AppFonts.subheadline)
                .foregroundColor(AppColors.primaryText)
            
            VStack(spacing: 0) {
                ForEach(Array(AIProvider.allCases.filter(\.requiresApiKey).enumerated()), id: \.element) { index, provider in
                    VStack(spacing: 0) {
                        APIKeyInputView(
                            provider: provider,
                            apiKey: viewModel.getApiKey(for: provider),
                            onUpdate: { key in
                                viewModel.updateApiKey(for: provider, key: key)
                            }
                        )
                        
                        // Add horizontal line between providers (but not after the last one)
                        if index < AIProvider.allCases.filter(\.requiresApiKey).count - 1 {
                            Rectangle()
                                .fill(AppColors.border)
                                .frame(height: 1)
                                .padding(.horizontal, 10)
                        }
                    }
                }
            }
            .padding(16)
            .background(AppColors.textFieldBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.border, lineWidth: 1)
            )
        }
    }
    
    private var modelSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                SwiftUI.Text("Available Models")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.primaryText)
                
                Spacer()
                
                Button("Select All Available") {
                    selectedModels = Set(AppConfig.shared.getAccessibleModels().map(\.id))
                }
                .buttonStyle(.bordered)
                .disabled(AppConfig.shared.getAccessibleModels().isEmpty)
            }
            
            SwiftUI.Text("Select which models you want to use. Models are only available if you have valid API keys.")
                .font(AppFonts.caption1)
                .foregroundColor(AppColors.secondaryText)
            
            LazyVStack(spacing: 12) {
                ForEach(AIProvider.allCases, id: \.self) { provider in
                    providerModelSection(for: provider)
                }
            }
        }
    }
    
    private func providerModelSection(for provider: AIProvider) -> some View {
        let models = provider.availableModels
        let hasApiKey = !provider.requiresApiKey || !viewModel.getApiKey(for: provider).isEmpty
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                SwiftUI.Text(provider.displayName)
                    .font(AppFonts.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.primaryText)
                
                if provider.requiresApiKey && !hasApiKey {
                    SwiftUI.Text("API Key Required")
                        .font(AppFonts.caption1)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.orange.opacity(0.2))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                // Add refresh button for Ollama
                if provider == .ollama {
                    ollamaRefreshButton
                }
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 8) {
                ForEach(models, id: \.id) { model in
                    ModelSelectionRow(
                        model: model,
                        isSelected: selectedModels.contains(model.id),
                        isAccessible: hasApiKey,
                        isDefault: defaultModel == model.id,
                        onToggle: { isSelected in
                            if isSelected {
                                selectedModels.insert(model.id)
                            } else {
                                selectedModels.remove(model.id)
                                if defaultModel == model.id {
                                    defaultModel = selectedModels.first ?? ""
                                }
                            }
                            saveChanges()
                        },
                        onSetDefault: {
                            if selectedModels.contains(model.id) {
                                defaultModel = model.id
                                saveChanges()
                            }
                        }
                    )
                }
            }
        }
        .padding(12)
        .background(hasApiKey ? AppColors.textFieldBackground : AppColors.background)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(hasApiKey ? AppColors.border : AppColors.border.opacity(0.5), lineWidth: 1)
        )
        .opacity(hasApiKey ? 1.0 : 0.6)
    }
    
    private var fallbackSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Enable Fallback Providers", isOn: $viewModel.enableAIFallback)
                .foregroundColor(AppColors.primaryText)
            
            if viewModel.enableAIFallback {
                SwiftUI.Text("If a model fails, Nova will try other selected models.")
                    .font(AppFonts.caption1)
                    .foregroundColor(AppColors.secondaryText)
            }
        }
        .padding(16)
        .background(AppColors.textFieldBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }
    
    private func loadCurrentSettings() {
        selectedModels = AppConfig.shared.selectedModels
        defaultModel = AppConfig.shared.defaultModel
    }
    
    private func saveChanges() {
        AppConfig.shared.updateModelSelection(selectedModels)
        AppConfig.shared.updateDefaultModel(defaultModel)
    }
    
    private var ollamaRefreshButton: some View {
        Button(action: {
            refreshOllamaModels()
        }) {
            HStack(spacing: 4) {
                if isRefreshingOllamaModels {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 12, height: 12)
                } else {
                    SwiftUI.Image(systemName: "arrow.clockwise")
                        .font(AppFonts.footnote)
                        .frame(width: 12, height: 12)
                }
                SwiftUI.Text(isRefreshingOllamaModels ? "Refreshing..." : "Refresh")
                    .font(AppFonts.caption1)
            }
            .fixedSize()
        }
        .buttonStyle(.bordered)
        .disabled(isRefreshingOllamaModels)
        .help("Refresh installed Ollama models")
    }
    
    private func refreshOllamaModels() {
        isRefreshingOllamaModels = true
        
        // Run refresh in background to avoid blocking UI
        Task {
            // Force refresh the models
            AppConfig.shared.refreshOllamaModels()
            
            // Update UI on main thread
            Task { @MainActor in
                isRefreshingOllamaModels = false
                // Reload settings to reflect new models
                loadCurrentSettings()
            }
        }
    }
}

struct ModelSelectionRow: View {
    let model: AIModel
    let isSelected: Bool
    let isAccessible: Bool
    let isDefault: Bool
    let onToggle: (Bool) -> Void
    let onSetDefault: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button(action: { onToggle(!isSelected) }) {
                    HStack(spacing: 8) {
                        SwiftUI.Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                            .foregroundColor(isSelected ? .blue : AppColors.secondaryText)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                SwiftUI.Text(model.displayName)
                                    .font(AppFonts.callout)
                                    .foregroundColor(AppColors.primaryText)
                                
                                if model.isRecommended {
                                    SwiftUI.Text("★")
                                        .font(AppFonts.caption2)
                                        .foregroundColor(.yellow)
                                }
                                
                                Spacer()
                            }
                            
                            SwiftUI.Text(model.description)
                                .font(AppFonts.caption2)
                                .foregroundColor(AppColors.secondaryText)
                                .lineLimit(2)
                        }
                        
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                .disabled(!isAccessible)
            }
            
            if isSelected {
                HStack {
                    Button(action: onSetDefault) {
                        HStack(spacing: 4) {
                            SwiftUI.Image(systemName: isDefault ? "star.fill" : "star")
                                .font(AppFonts.caption2)
                                .foregroundColor(isDefault ? .yellow : AppColors.secondaryText)
                            SwiftUI.Text(isDefault ? "Default" : "Set as Default")
                                .font(AppFonts.caption2)
                                .foregroundColor(isDefault ? .yellow : AppColors.secondaryText)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
            }
        }
        .padding(8)
        .background(isSelected ? AppColors.accentBlue.opacity(0.1) : Color.clear)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? AppColors.accentBlue.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

struct APIKeyInputView: View {
    let provider: AIProvider
    @State var apiKey: String
    let onUpdate: (String) -> Void
    
    @State private var isEditing = false
    @State private var editingKey = ""
    @State private var isValidating = false
    @State private var validationResult: ValidationResult?
    
    enum ValidationResult {
        case valid
        case invalid(String)
    }
    
    private var hasApiKey: Bool {
        !apiKey.isEmpty
    }
    
    init(provider: AIProvider, apiKey: String, onUpdate: @escaping (String) -> Void) {
        self.provider = provider
        self._apiKey = State(initialValue: apiKey)
        self.onUpdate = onUpdate
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with provider name, status, and validation controls
            HStack {
                SwiftUI.Text(provider.displayName)
                    .font(AppFonts.bodyMedium)
                    .foregroundColor(AppColors.primaryText)
                
                Spacer()
                
                // Status and validation controls in consistent layout
                HStack(spacing: 8) {
                    if hasApiKey && !isEditing {
                        HStack(spacing: 6) {
                            SwiftUI.Image(systemName: "checkmark.shield.fill")
                                .font(AppFonts.caption2)
                                .foregroundColor(.green)
                            
                            SwiftUI.Text("Secure")
                                .font(AppFonts.caption2)
                                .foregroundColor(.green)
                        }
                    }
                    
                    // Validation indicator and test button
                    if isValidating {
                        HStack(spacing: 4) {
                            ProgressView()
                                .scaleEffect(0.6)
                                .frame(width: 12, height: 12)
                            SwiftUI.Text("Validating...")
                                .font(AppFonts.caption2)
                                .foregroundColor(AppColors.secondaryText)
                        }
                        .frame(minWidth: 80) // Fixed width to prevent layout shifting
                    } else if let result = validationResult {
                        HStack(spacing: 4) {
                            switch result {
                            case .valid:
                                SwiftUI.Image(systemName: "checkmark.circle.fill")
                                    .font(AppFonts.caption2)
                                    .foregroundColor(.green)
                                SwiftUI.Text("Valid")
                                    .font(AppFonts.caption2)
                                    .foregroundColor(.green)
                            case .invalid(_):
                                SwiftUI.Image(systemName: "xmark.circle.fill")
                                    .font(AppFonts.caption2)
                                    .foregroundColor(.red)
                                SwiftUI.Text("Invalid")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.red)
                            }
                        }
                        .frame(minWidth: 80) // Fixed width to prevent layout shifting
                    } else if hasApiKey {
                        Button("Test") {
                            testApiKey()
                        }
                        .buttonStyle(SecondaryButtonStyle(backgroundColor: AppColors.inputBarBackground))
                        .font(.system(size: 10, weight: .medium))
                        .frame(minWidth: 50)
                        .frame(maxHeight: 10)
                    } else {
                        // Empty spacer to maintain consistent layout
                        Spacer()
                            .frame(minWidth: 80)
                    }
                }
            }
            
            // Main content area
            VStack(spacing: 8) {
                if !hasApiKey || isEditing {
                    // Input mode
                    apiKeyInputSection
                } else {
                    // Display mode (key is set)
                    apiKeyDisplaySection
                }
            }
        }
        .padding(.horizontal, 0)
        .padding(.vertical, 8)
        .animation(.easeInOut(duration: 0.2), value: isEditing)
        .animation(.easeInOut(duration: 0.2), value: hasApiKey)
    }
    
    private var apiKeyInputSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                SecureField("Enter your \(provider.displayName) API key", text: $editingKey)
                    .textFieldStyle(.plain)
                    .font(AppFonts.codeBlock)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(AppColors.inputBarBackground)
                    .cornerRadius(8)
                    .frame(height: 44)
                    .frame(maxWidth: .infinity)

                if isEditing {
                    Button("Cancel", action: cancelEditing)
                        .buttonStyle(SecondaryButtonStyle())
                }

                Button(isEditing ? "Save" : "Add API Key", action: saveApiKey)
                    .buttonStyle(PrimaryButtonStyle(height: 44))
                    .disabled(editingKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            // Error message
            if case .invalid(let error) = validationResult {
                SwiftUI.Text(error)
                    .font(AppFonts.footnote)
                    .foregroundColor(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            if editingKey.isEmpty {
                editingKey = apiKey
            }
        }
    }
    
    private var apiKeyDisplaySection: some View {
        HStack(spacing: 8) {
            // Masked key display in larger area similar to text input
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    SwiftUI.Image(systemName: "key.fill")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.accentBlue)
                    
                    SwiftUI.Text("••••••••••••\(apiKey.suffix(4))")
                        .font(AppFonts.inlineCode)
                        .foregroundColor(AppColors.secondaryText)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .background(AppColors.textFieldBackground)
            .cornerRadius(8)
            .frame(minHeight: 44)
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 8) {
                Button("Change") {
                    startEditing()
                }
                .buttonStyle(SecondaryButtonStyle(backgroundColor: AppColors.inputBarBackground))
                
                Button("Remove") {
                    removeApiKey()
                }
                .buttonStyle(DestructiveButtonStyle())
            }
        }
    }
    
    // MARK: - Actions
    
    private func startEditing() {
        editingKey = apiKey
        isEditing = true
        validationResult = nil
    }
    
    private func cancelEditing() {
        editingKey = apiKey
        isEditing = false
        validationResult = nil
    }
    
    private func saveApiKey() {
        let trimmedKey = editingKey.trimmingCharacters(in: .whitespacesAndNewlines)
        apiKey = trimmedKey
        onUpdate(trimmedKey)
        isEditing = false
        validationResult = nil
    }
    
    private func removeApiKey() {
        apiKey = ""
        editingKey = ""
        onUpdate("")
        validationResult = nil
    }
    
    private func testApiKey() {
        isValidating = true
        validationResult = nil
        
        Task {
            let keyToTest = isEditing ? editingKey : apiKey
            let isValid = await validateApiKey(keyToTest)
            
            await MainActor.run {
                isValidating = false
                if isValid {
                    validationResult = .valid
                } else {
                    validationResult = .invalid("Invalid API key format or unauthorized")
                }
            }
        }
    }
    
    private func validateApiKey(_ key: String) async -> Bool {
        // Simulate network validation
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        // Basic format validation
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch provider {
        case .openai:
            return trimmedKey.hasPrefix("sk-") && trimmedKey.count > 20
        case .claude:
            return trimmedKey.hasPrefix("sk-ant-") && trimmedKey.count > 20
        case .mistral:
            return trimmedKey.count > 10
        case .grok:
            return trimmedKey.hasPrefix("xai-") && trimmedKey.count > 20
        case .gemini:
            return trimmedKey.count > 20
        case .ollama:
            return true
        }
    }
}

// MARK: - Custom Button Styles

struct PrimaryButtonStyle: ButtonStyle {

    let height: CGFloat

    init(height: CGFloat = 44) {
        self.height = height
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFonts.messageTimestamp)
            .frame(minHeight: height)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(AppColors.accentBlue)
            .cornerRadius(6)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    let backgroundColor: Color
    
    init(backgroundColor: Color = AppColors.background) {
        self.backgroundColor = backgroundColor
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFonts.messageTimestamp)
            .foregroundColor(AppColors.primaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(backgroundColor)
            .cornerRadius(6)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFonts.messageTimestamp)
            .foregroundColor(Color.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.red)
            .cornerRadius(6)
//            .overlay(
//                RoundedRectangle(cornerRadius: 6)
//                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
//            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(AppColors.textFieldBackground)
            .cornerRadius(6)
    }
}

// MARK: - Whisper Settings

struct WhisperSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var availableModels: [WhisperModel] = []
    @State private var selectedModelId: String = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                modelSelectionSection
                audioConfigurationSection
                performanceSection
                Spacer()
            }
            .padding(20)
        }
        .background(AppColors.background)
        .onAppear {
            loadAvailableModels()
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SwiftUI.Text("Speech Recognition Configuration")
                .font(AppFonts.title2)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.primaryText)
            
            SwiftUI.Text("Configure Whisper models and audio processing settings")
                .font(AppFonts.body)
                .foregroundColor(AppColors.secondaryText)
        }
    }
    
    private var modelSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SwiftUI.Text("Available Models")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.primaryText)
            
            SwiftUI.Text("Select which Whisper model to use for speech recognition. Larger models provide better accuracy but use more memory.")
                .font(AppFonts.caption1)
                .foregroundColor(AppColors.secondaryText)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(availableModels, id: \.id) { model in
                    WhisperModelRow(
                        model: model,
                        isSelected: selectedModelId == model.id,
                        onSelect: {
                            selectedModelId = model.id
                            AppConfig.shared.updateWhisperModelSelection(model.name)
                        }
                    )
                }
            }
            .padding(16)
            .background(AppColors.textFieldBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.border, lineWidth: 1)
            )
        }
    }
    
    private var audioConfigurationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SwiftUI.Text("Audio Configuration")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.primaryText)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    SwiftUI.Text("Max Recording Duration:")
                        .foregroundColor(AppColors.primaryText)
                    Spacer()
                    SwiftUI.Text("\(Int(viewModel.maxAudioDurationSeconds / 60)) minutes")
                        .foregroundColor(AppColors.secondaryText)
                }
                
                Slider(
                    value: $viewModel.maxAudioDurationSeconds,
                    in: 60...3600,
                    step: 60
                ) {
                    SwiftUI.Text("Duration")
                }
            }
            .padding(16)
            .background(AppColors.textFieldBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.border, lineWidth: 1)
            )
        }
    }
    
    private var performanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SwiftUI.Text("Performance Options")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.primaryText)
            
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Enable Background Loading", isOn: $viewModel.enableBackgroundLoading)
                    .foregroundColor(AppColors.primaryText)
                
                Toggle("Show Model Loading Progress", isOn: $viewModel.showModelLoadingProgress)
                    .foregroundColor(AppColors.primaryText)
            }
            .padding(16)
            .background(AppColors.textFieldBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.border, lineWidth: 1)
            )
        }
    }
    
    private func loadAvailableModels() {
        availableModels = AppConfig.shared.getAvailableWhisperModels()
        selectedModelId = AppConfig.shared.whisperModelName
    }
}

struct WhisperModelRow: View {
    let model: WhisperModel
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                SwiftUI.Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : AppColors.secondaryText)
                    .font(.system(size: 16))
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        SwiftUI.Text(model.displayName)
                            .font(AppFonts.bodyMedium)
                            .foregroundColor(AppColors.primaryText)
                        
                        Spacer()
                        
                        SwiftUI.Text(model.size)
                            .font(AppFonts.footnote)
                            .foregroundColor(AppColors.secondaryText)
                    }
                    
                    SwiftUI.Text(model.description)
                        .font(AppFonts.footnote)
                        .foregroundColor(AppColors.secondaryText)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            .padding(12)
            .background(isSelected ? AppColors.accentBlue.opacity(0.1) : Color.clear)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? AppColors.accentBlue.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Interface Settings

struct InterfaceSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    SwiftUI.Text("Interface Configuration")
                        .font(AppFonts.title2)
                        .foregroundColor(AppColors.primaryText)
                    
                    SwiftUI.Text("Customize the Nova interface appearance and behavior")
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.secondaryText)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    SwiftUI.Text("Microphone Indicators")
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.primaryText)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Show Microphone Loading Indicator", isOn: $viewModel.enableMicrophoneLoadingIndicator)
                            .font(AppFonts.body)
                            .foregroundColor(AppColors.primaryText)
                    }
                    .padding(16)
                    .background(AppColors.textFieldBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
                }
                
                Spacer()
            }
            .padding(20)
        }
        .background(AppColors.background)
    }
}

// MARK: - Advanced Settings

struct AdvancedSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    SwiftUI.Text("Advanced Configuration")
                        .font(AppFonts.title2)
                        .foregroundColor(AppColors.primaryText)
                    
                    SwiftUI.Text("Advanced settings and configuration options")
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.secondaryText)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    SwiftUI.Text("Reset Options")
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.primaryText)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Button("Reset to Defaults") {
                                viewModel.resetToDefaults()
                            }
                            .buttonStyle(.bordered)
                            
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            SwiftUI.Text("Configuration File Location")
                                .font(AppFonts.bodyMedium)
                                .foregroundColor(AppColors.primaryText)
                            
                            SwiftUI.Text(viewModel.configFileLocation)
                                .font(AppFonts.caption1)
                                .foregroundColor(AppColors.secondaryText)
                                .textSelection(.enabled)
                        }
                    }
                    .padding(16)
                    .background(AppColors.textFieldBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
                }
                
                Spacer()
            }
            .padding(20)
        }
        .background(AppColors.background)
    }
}

#Preview {
    SettingsView()
}
