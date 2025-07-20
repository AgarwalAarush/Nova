//
//  ModelSelectorView.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/16/25.
//

import SwiftUI

struct ModelSelectorView: View {
    @ObservedObject var chatViewModel: ChatViewModel
    @ObservedObject var aiRouter: AIServiceRouter
    @ObservedObject var config: AppConfig = .shared
    @Binding var isPresented: Bool
    
    @State private var hoveredModel: String? = nil
    
    var body: some View { VStack(spacing: 0) {
            // Model list grouped by provider
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(getGroupedModels(), id: \.key) { provider, models in
                        VStack(alignment: .leading, spacing: 8) {
                            // Provider header
                            HStack {
                                SwiftUI.Text(provider.displayName)
                                .font(AppFonts.caption1)
                                .foregroundColor(AppColors.secondaryText)
                                
                                if provider.requiresApiKey && config.getApiKey(for: provider).isEmpty {
                                    SwiftUI.Text("(API Key Required)")
                                        .font(AppFonts.caption1)
                                        .foregroundColor(.orange)
                                }
                                
                                Spacer()
                            }
                            
                            // Model buttons
                            VStack(spacing: 4) {
                                ForEach(models, id: \.id) { model in
                                    ModelRowView(
                                        model: model,
                                        isSelected: isModelSelected(model),
                                        isHovered: hoveredModel == model.id,
                                        isAccessible: isModelAccessible(model),
                                        onSelect: { selectModel(model) }
                                    )
                                    .onHover { isHovered in
                                        hoveredModel = isHovered ? model.id : nil
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)
            }
            .frame(maxHeight: 300)
        }
        .frame(width: 300)
        .background(AppColors.background)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
    
    private func getGroupedModels() -> [(key: AIProvider, value: [AIModel])] {
        let allModels = config.getAccessibleModels()
        let grouped = Dictionary(grouping: allModels, by: { $0.provider })
        return grouped.sorted { $0.key.displayName < $1.key.displayName }
    }
    
    private func isModelSelected(_ model: AIModel) -> Bool {
        return aiRouter.currentModel == model.id
    }
    
    private func isModelAccessible(_ model: AIModel) -> Bool {
        if model.provider.requiresApiKey {
            return !config.getApiKey(for: model.provider).isEmpty
        }
        return true
    }
    
    private func selectModel(_ model: AIModel) {
        guard isModelAccessible(model) else { return }

        print("-------------- MODEL SWITCH --------------")
        
        print("Current Provider: \(aiRouter.currentProvider)")
        print("Current Model: \(AppConfig.shared.currentUserModel)")
        print("Model Provider: \(aiRouter.currentProvider)")
        // Atomically switch provider and model together
        if aiRouter.currentProvider != model.provider {
            print("Changing Provider and Model")
            aiRouter.switchProvider(to: model.provider, withModel: model.id)
        } else {
            print("Changing Model, Keeping Provider")
            // Same provider, just update the model
            config.updateCurrentUserModel(model.id)
        }

        print("Current Provider: \(aiRouter.currentProvider)")
        print("Current Model: \(AppConfig.shared.currentUserModel)")

        print("-------------- MODEL SWITCHED --------------")
        
        print(config.getCurrentUserModel())
        
        // Close the popup
        isPresented = false
    }
}

struct ModelRowView: View {
    let model: AIModel
    let isSelected: Bool
    let isHovered: Bool
    let isAccessible: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Model info
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        SwiftUI.Text(model.displayName)
                            .font(AppFonts.body)
                            .foregroundColor(isAccessible ? AppColors.primaryText : AppColors.secondaryText.opacity(0.6))
                        
                    }
                    
                    SwiftUI.Text(model.description)
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.secondaryText)
                        .lineLimit(1)
                }
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColorForState)
            )
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isAccessible)
    }
    
    private var backgroundColorForState: Color {
        if isHovered && isSelected {
            return Color.clear
        } else if isHovered && isAccessible {
            return Color.gray.opacity(0.15)
        } else {
            return Color.clear
        }
    }
}
