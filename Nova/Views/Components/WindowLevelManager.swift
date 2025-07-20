//
//  WindowLevelManager.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/20/25.
//

import SwiftUI
import AppKit

/// NSViewRepresentable that manages the window level for pinning functionality
struct WindowLevelManager: NSViewRepresentable {
    @Binding var isPinned: Bool
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            guard let window = nsView.window else { return }
            
            // Set window level based on pinning state
            window.level = isPinned ? .statusBar : .normal
            
            if isPinned {
                print("📌 Window pinned to status bar level")
            } else {
                print("📌 Window unpinned to normal level")
            }
        }
    }
}

// MARK: - View Extension

extension View {
    /// Apply window pinning functionality to this view
    func windowPinning(isPinned: Binding<Bool>) -> some View {
        self.background(WindowLevelManager(isPinned: isPinned))
    }
}