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
        .background(
            CompactKeyEventHandler { event in
                if event.keyCode == 53 && event.type == .keyDown { // Escape key code
                    if event.modifierFlags.contains(.command) {
                        // Command+Escape: Toggle view mode
                        viewModel.handleCommandEscapeKey()
                        return true
                    }
                    // Let plain Escape pass through normally
                }
                return false
            }
        )
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

// MARK: - Key Event Handler

private struct CompactKeyEventHandler: NSViewRepresentable {
    let onKeyEvent: (NSEvent) -> Bool
    
    func makeNSView(context: Context) -> CompactKeyEventView {
        let view = CompactKeyEventView()
        view.onKeyEvent = onKeyEvent
        view.setupGlobalKeyMonitor()
        return view
    }
    
    func updateNSView(_ nsView: CompactKeyEventView, context: Context) {
        nsView.onKeyEvent = onKeyEvent
    }
}

private class CompactKeyEventView: NSView {
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
