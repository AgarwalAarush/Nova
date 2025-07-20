//
//  InputBarView.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/11/25.
//

import SwiftUI

struct InputBarView: View {
    @Binding var currentInput: String
    @State private var textHeight: CGFloat = GrowingTextView.initialHeight
    @State private var showModelSelector: Bool = false
    @State private var isPlaceholderVisible: Bool = true
    let onSend: () -> Void
    let onDictationToggle: () -> Void
    let isDictating: Bool
    let isTranscribing: Bool
    let modelState: WhisperModelState
    @ObservedObject var chatViewModel: ChatViewModel
    @ObservedObject var config: AppConfig = AppConfig.shared
    
    var currentModel: AIModel? {
        config.getModel(byId: config.getCurrentUserModel())
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Compact rounded rectangle with VStack layout
            VStack(spacing: 6) {
                // Text input area
                ZStack(alignment: .topLeading) {
                    GrowingTextView(
                        text: $currentInput,
                        height: $textHeight,
                        isPlaceholderVisible: $isPlaceholderVisible,
                        onSend: onSend
                    )
                    .focusable()
                    .frame(height: textHeight)
                    .background(Color.clear)
                    
                    if isPlaceholderVisible {
                        HStack {
                            SwiftUI.Text("Ask Nova anything...")
                                .foregroundColor(AppColors.secondaryText)
                                .font(AppFonts.inputField)
                                .allowsHitTesting(false)
                            Spacer()
                        }
                        .padding(.top, 4) // Match model selector button padding
                        .padding(.leading, 0) // Align with model selector button
                    }
                }
                
                // Buttons below text
                HStack(spacing: 8) {
                    DictationButton(
                        onDictationToggle: onDictationToggle,
                        isDictating: isDictating,
                        isTranscribing: isTranscribing,
                        modelState: modelState
                    )
                    
                    // Model selector button
                    ModelSelectorButton(
                        config: AppConfig.shared,
                        showModelSelector: $showModelSelector
                    )
                    
                    Spacer()
                    
                    Button(action: onSend) {
                        SwiftUI.Image(systemName: "arrow.up.circle.fill")
                            .font(AppFonts.title3)
                            .foregroundColor(currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AppColors.secondaryText : AppColors.accentBlue)
                    }
                    .disabled(currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AppColors.inputBarBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.textFieldBorder.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(AppColors.background)
        .onChange(of: currentInput) { _, newValue in
            isPlaceholderVisible = newValue.isEmpty
        }
        .popover(isPresented: $showModelSelector, attachmentAnchor: .point(.center)) {
            ModelSelectorView(
                chatViewModel: chatViewModel,
                aiRouter: chatViewModel.aiServiceRouter,
                isPresented: $showModelSelector
            )
        }
    }
}

struct DictationButton: View {
    let onDictationToggle: () -> Void
    let isDictating: Bool
    let isTranscribing: Bool
    let modelState: WhisperModelState
    
    @State private var pulseAnimation = false
    @State private var loadingRotation = 0.0
    
    var body: some View {
        Button(action: onDictationToggle) {
            ZStack {
                // Background circle for recording state
                if isDictating {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 14, height: 14)
                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                        .opacity(pulseAnimation ? 0.3 : 0.6)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulseAnimation)
                        .onAppear {
                            pulseAnimation = true
                        }
                        .onDisappear {
                            pulseAnimation = false
                        }
                }
                
                // Loading indicator for model loading
                if case .loading = modelState, AppConfig.shared.enableMicrophoneLoadingIndicator {
                    Circle()
                        .stroke(AppColors.accentBlue.opacity(0.3), lineWidth: 2)
                        .frame(width: 18, height: 18)
                    
                    Circle()
                        .trim(from: 0, to: 0.25)
                        .stroke(AppColors.accentBlue, lineWidth: 2)
                        .frame(width: 18, height: 18)
                        .rotationEffect(.degrees(loadingRotation))
                        .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: loadingRotation)
                        .onAppear {
                            loadingRotation = 360
                        }
                        .onDisappear {
                            loadingRotation = 0
                        }
                }
                
                SwiftUI.Image(systemName: microphoneIcon)
                    .font(AppFonts.subheadline)
                    .foregroundColor(microphoneColor)
            }
        }
        .disabled(isTranscribing || !modelState.isReady)
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isDictating)
        .animation(.easeInOut(duration: 0.2), value: isTranscribing)
        .animation(.easeInOut(duration: 0.2), value: modelState.isReady)
    }
    
    private var microphoneIcon: String {
        if isTranscribing {
            return "waveform.circle"
        } else if isDictating {
            return "mic.fill"
        } else {
            return "mic"
        }
    }
    
    private var microphoneColor: Color {
        if isTranscribing {
            return AppColors.accentBlue
        } else if isDictating {
            return .red
        } else if case .loading = modelState {
            return AppColors.accentBlue.opacity(0.6)
        } else if case .failed = modelState {
            return .red.opacity(0.7)
        } else if modelState.isReady {
            return AppColors.secondaryText
        } else {
            return AppColors.secondaryText.opacity(0.5)
        }
    }
}

struct ModelSelectorButton: View {
    @ObservedObject var config: AppConfig
    @Binding var showModelSelector: Bool
    @State private var isHovering = false
    
    private var currentModel: AIModel? {
        config.getModel(byId: config.getCurrentUserModel())
    }
    
    var body: some View {
        Button(action: { showModelSelector.toggle() }) {
            HStack(spacing: 4) {
                SwiftUI.Text(currentModel?.displayName ?? "Select Model")
                    .font(AppFonts.modelNameSmall)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .foregroundColor(AppColors.secondaryText)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(minWidth: 80)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovering ? AppColors.secondaryText.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}



