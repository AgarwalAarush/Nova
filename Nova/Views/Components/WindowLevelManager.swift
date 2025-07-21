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
        guard let window = nsView.window else { 
            // If window is not available, retry after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.updateNSView(nsView, context: context)
            }
            return 
        }
        
        // Set window level based on pinning state
        let newLevel: NSWindow.Level = isPinned ? .statusBar : .normal
        
        // Only update if the level actually changed to avoid unnecessary operations
        if window.level != newLevel {
            window.level = newLevel
            
            // Force window to update its position
            if isPinned {
                window.orderFront(nil)
                print("📌 Window pinned to status bar level (always on top)")
            } else {
                window.orderFront(nil)
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