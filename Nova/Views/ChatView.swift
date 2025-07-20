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
                    if event.modifierFlags.contains(.command) {
                        // Command+Escape: Toggle view mode
                        viewModel.handleCommandEscapeKey()
                        return true
                    }
                    // Let plain Escape pass through to the text input to handle focus removal
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
        view.setupGlobalKeyMonitor()
        return view
    }
    
    func updateNSView(_ nsView: KeyEventView, context: Context) {
        nsView.onKeyEvent = onKeyEvent
    }
}

class KeyEventView: NSView {
    var onKeyEvent: ((NSEvent) -> Bool)?
    private var keyDownMonitor: Any?
    
    override var acceptsFirstResponder: Bool { true }
    override var canBecomeKeyView: Bool { true }
    
    func setupGlobalKeyMonitor() {
        // Remove existing monitor if any
        if let monitor = keyDownMonitor {
            NSEvent.removeMonitor(monitor)
        }
        
        // Set up global key monitor for this window
        keyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            guard let self = self,
                  let handler = self.onKeyEvent,
                  event.window == self.window else {
                return event
            }
            
            return handler(event) ? nil : event
        }
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            setupGlobalKeyMonitor()
        }
    }
    
    deinit {
        if let monitor = keyDownMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    override func keyDown(with event: NSEvent) {
        if let handler = onKeyEvent, handler(event) {
            return // Event was handled
        }
        super.keyDown(with: event)
    }
    
    override func flagsChanged(with event: NSEvent) {
        // Also handle flag changes for modifier keys
        if let handler = onKeyEvent, handler(event) {
            return
        }
        super.flagsChanged(with: event)
    }
}
