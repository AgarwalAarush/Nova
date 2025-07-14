//
//  InputBarView.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/11/25.
//

import SwiftUI

struct InputBarView: View {
    @Binding var currentInput: String
    @State private var textHeight: CGFloat = 22
    let onSend: () -> Void
    let onDictationToggle: () -> Void
    let isDictating: Bool
    let isTranscribing: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .topLeading) {
                if currentInput.isEmpty {
                    SwiftUI.Text("Ask Nova anything...")
                        .foregroundColor(AppColors.secondaryText)
                        .font(AppFonts.inputField)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                }
                
                GrowingTextView(
                    text: $currentInput,
                    height: $textHeight,
                    onSend: onSend
                )
                .focusable()
                .frame(height: textHeight)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppColors.textFieldBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(AppColors.textFieldBorder, lineWidth: 1)
                    )
            )
            
            DictationButton(
                onDictationToggle: onDictationToggle,
                isDictating: isDictating,
                isTranscribing: isTranscribing
            )
            
            Button(action: onSend) {
                SwiftUI.Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AppColors.secondaryText : AppColors.accentBlue)
            }
            .disabled(currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(AppColors.background)
    }
}

struct DictationButton: View {
    let onDictationToggle: () -> Void
    let isDictating: Bool
    let isTranscribing: Bool
    
    @State private var pulseAnimation = false
    
    var body: some View {
        Button(action: onDictationToggle) {
            ZStack {
                if isDictating {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 40, height: 40)
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
                
                SwiftUI.Image(systemName: microphoneIcon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(microphoneColor)
            }
        }
        .disabled(isTranscribing)
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isDictating)
        .animation(.easeInOut(duration: 0.2), value: isTranscribing)
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
        } else {
            return AppColors.secondaryText
        }
    }
}



