//
//  CompactVoiceView.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/16/25.
//

import SwiftUI
import AppKit

struct CompactVoiceView: View {
    @ObservedObject var viewModel: ChatViewModel
    @EnvironmentObject var whisperService: WhisperService
    @StateObject private var appConfig = AppConfig.shared
    @State private var originalStyleMask: NSWindow.StyleMask?
    @State private var showModelSelector: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            
            // Model selector button
            ModelSelectorButton(
                config: AppConfig.shared,
                showModelSelector: $showModelSelector
            )
            
            Spacer()
            
            // Activity indicator or last response preview
            VStack {
                if viewModel.isLoading {
                    SwiftUI.Image(systemName: "ellipsis")
                        .font(AppFonts.subheadline)
                        .foregroundColor(AppColors.accentBlue)
                        .symbolEffect(.pulse)
                } else if viewModel.isTranscribing {
                    SwiftUI.Image(systemName: "waveform")
                        .font(AppFonts.subheadline)
                        .foregroundColor(AppColors.accentBlue)
                        .symbolEffect(.pulse)
                } else {
                    SwiftUI.Image(systemName: "checkmark.circle.fill")
                        .font(AppFonts.subheadline)
                        .foregroundColor(AppColors.secondaryText.opacity(0.6))
                }
            }
            .frame(width: 24)
            
            // Continuous listening toggle button
            ContinuousListeningButton(
                onToggle: viewModel.toggleContinuousListening,
                isListening: viewModel.isContinuousListening,
                isVoiceActive: viewModel.isVoiceActive,
                audioLevel: viewModel.continuousAudioLevel
            )
            
            Spacer().frame(maxWidth: 8)
            
            // Central dictation button
            DictationButton(
                onDictationToggle: viewModel.toggleDictation,
                isDictating: viewModel.isDictating,
                isTranscribing: viewModel.isTranscribing,
                modelState: whisperService.modelState
            )
            
            // Pin toggle button
            Button(action: {
                appConfig.enableWindowPinning.toggle()
            }) {
                SwiftUI.Image(systemName: appConfig.enableWindowPinning ? "pin.fill" : "pin")
                    .font(AppFonts.callout)
                    .foregroundColor(appConfig.enableWindowPinning ? AppColors.accentBlue : AppColors.secondaryText)
            }
            .buttonStyle(.plain)
            .help(appConfig.enableWindowPinning ? "Unpin window" : "Pin window to top")
            
            Spacer()
            
            // Mode toggle button (expand to normal view)
            Button(action: {
                viewModel.toggleViewMode()
            }) {
                SwiftUI.Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(AppFonts.callout)
                    .foregroundColor(AppColors.secondaryText)
            }
            .buttonStyle(.plain)
            .help("Expand to full chat view")
            
        }
        .popover(isPresented: $showModelSelector, attachmentAnchor: .point(.center)) {
            ModelSelectorView(
                chatViewModel: viewModel,
                aiRouter: viewModel.aiServiceRouter,
                isPresented: $showModelSelector
            )
        }
        .withHostingWindow { window in
            if originalStyleMask == nil {
                originalStyleMask = window.styleMask
                // Defer window modifications to avoid reentrancy during layout
                DispatchQueue.main.async {
                    window.titleVisibility = .hidden
                    window.titlebarAppearsTransparent = true
                    window.styleMask.remove(.titled)
                }
            }
        }
        .onDisappear {
            if let window = NSApp.keyWindow, let original = originalStyleMask {
                // Defer window restoration to avoid reentrancy during layout
                DispatchQueue.main.async {
                    window.styleMask = original
                }
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 38)
        .background(AppColors.background)
        .cornerRadius(8)
//        .overlay(
//            Rectangle()
//                .frame(height: 1)
//                .foregroundColor(AppColors.textFieldBorder)
//                .padding(.horizontal, 20),
//            alignment: .top
//        )
    }
}

#Preview {
    CompactVoiceView(viewModel: ChatViewModel())
        .environmentObject(WhisperService())
        .frame(width: 400)
}

// MARK: - Window Accessor Helpers
private struct WindowAccessor: NSViewRepresentable {
    let callback: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                callback(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

extension View {
    /// Allows executing a callback with the hosting NSWindow when this view is inserted.
    func withHostingWindow(_ callback: @escaping (NSWindow) -> Void) -> some View {
        background(WindowAccessor(callback: callback))
    }
}
