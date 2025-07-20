//
//  ChatView.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/11/25.
//

import SwiftUI
import AppKit

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @EnvironmentObject var whisperService: WhisperService
    @StateObject private var appConfig = AppConfig.shared
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            MessageListView(messages: viewModel.messages)
            InputBarView(
                currentInput: $viewModel.currentInput,
                onSend: viewModel.sendMessage,
                onDictationToggle: viewModel.toggleDictation,
                isDictating: viewModel.isDictating,
                isTranscribing: viewModel.isTranscribing,
                modelState: whisperService.modelState,
                chatViewModel: viewModel
            )
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .toolbar {
            ToolbarItem(id: "flex") {
                Spacer()
            }
            
            ToolbarItem {
                Button(action: {
                    appConfig.enableWindowPinning.toggle()
                }) {
                    SwiftUI.Image(systemName: appConfig.enableWindowPinning ? "pin.fill" : "pin")
                        .font(AppFonts.callout)
                        .foregroundColor(appConfig.enableWindowPinning ? AppColors.accentBlue : AppColors.secondaryText)
                }
                .buttonStyle(.plain)
                .help(appConfig.enableWindowPinning ? "Unpin window" : "Pin window to top")
            }
            
            ToolbarItem {
                Button(action: {
                    viewModel.toggleViewMode()
                }) {
                    SwiftUI.Image(systemName: "arrow.down.right.and.arrow.up.left")
                        .font(AppFonts.callout)
                        .foregroundColor(AppColors.secondaryText)
                }
                .buttonStyle(.plain)
                .help("Switch to compact voice mode")
            }
            
            ToolbarItem {
                Button(action: {
                    showingSettings = true
                }) {
                    SwiftUI.Image(systemName: "gear")
                        .font(AppFonts.callout)
                        .foregroundColor(AppColors.secondaryText)
                }
                .buttonStyle(.plain)
                .help("Settings")
            }
        }
        .background(
            KeyEventHandler { event in
                if event.keyCode == 53 && event.type == .keyDown { // Escape key code
                    // Only handle escape globally when input is not focused
                    if !viewModel.isInputFocused {
                        viewModel.handleEscapeKey()
                        return true
                    }
                }
                return false
            }
        )
    }
}

// MARK: - Key Event Handler

struct KeyEventHandler: NSViewRepresentable {
    let onKeyEvent: (NSEvent) -> Bool
    
    func makeNSView(context: Context) -> KeyEventView {
        let view = KeyEventView()
        view.onKeyEvent = onKeyEvent
        return view
    }
    
    func updateNSView(_ nsView: KeyEventView, context: Context) {
        nsView.onKeyEvent = onKeyEvent
    }
}

class KeyEventView: NSView {
    var onKeyEvent: ((NSEvent) -> Bool)?
    
    override var acceptsFirstResponder: Bool { true }
    
    override func keyDown(with event: NSEvent) {
        if let handler = onKeyEvent, handler(event) {
            return // Event was handled
        }
        super.keyDown(with: event)
    }
}
