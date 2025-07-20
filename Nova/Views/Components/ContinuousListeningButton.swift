//
//  ContinuousListeningButton.swift
//  Nova
//
//  Toggle button for continuous voice monitoring with silence detection
//

import SwiftUI

struct ContinuousListeningButton: View {
    let onToggle: () -> Void
    let isListening: Bool
    let isVoiceActive: Bool
    let audioLevel: Float
    
    @State private var pulseScale: Double = 1.0
    
    var body: some View {
        Button(action: onToggle) {
            ZStack {
                // Background circle
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 32, height: 32)
                    .scaleEffect(isVoiceActive ? pulseScale : 1.0)
                    .animation(
                        isVoiceActive ? 
                        .easeInOut(duration: 0.6).repeatForever(autoreverses: true) :
                        .easeInOut(duration: 0.2),
                        value: isVoiceActive
                    )
                
                // Icon
                SwiftUI.Image(systemName: iconName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(iconColor)
            }
        }
        .buttonStyle(.plain)
        .help(helpText)
        .onAppear {
            pulseScale = 1.15
        }
        .onChange(of: isVoiceActive) { _, newValue in
            if newValue {
                pulseScale = 1.15
            } else {
                pulseScale = 1.0
            }
        }
    }
    
    private var backgroundColor: Color {
        if isVoiceActive {
            return Color.blue.opacity(0.8)  // Bright blue when voice is active
        } else if isListening {
            return Color.blue.opacity(0.4)  // Light blue when listening
        } else {
            return AppColors.userMessageBackground
        }
    }
    
    private var iconColor: Color {
        if isVoiceActive {
            return .white
        } else if isListening {
            return Color.blue
        } else {
            return AppColors.secondaryText
        }
    }
    
    private var iconName: String {
        if isVoiceActive {
            return "waveform"
        } else if isListening {
            return "ear"
        } else {
            return "ear.trianglebadge.exclamationmark"
        }
    }
    
    private var helpText: String {
        if isListening {
            return isVoiceActive ? "Voice activity detected - recording..." : "Listening for voice activity - click to stop"
        } else {
            return "Enable continuous voice monitoring"
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Off state
        ContinuousListeningButton(
            onToggle: {},
            isListening: false,
            isVoiceActive: false,
            audioLevel: 0.0
        )
        
        // Listening state
        ContinuousListeningButton(
            onToggle: {},
            isListening: true,
            isVoiceActive: false,
            audioLevel: 0.2
        )
        
        // Voice active state
        ContinuousListeningButton(
            onToggle: {},
            isListening: true,
            isVoiceActive: true,
            audioLevel: 0.8
        )
    }
    .padding()
    .background(AppColors.background)
}