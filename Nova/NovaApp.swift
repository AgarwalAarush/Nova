//
//  NovaApp.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/10/25.
//

import SwiftUI

@main
struct NovaApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var whisperService = WhisperService()
    @StateObject private var aiServiceRouter = AIServiceRouter()
    @StateObject private var automationService = MacOSAutomationService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(whisperService)
                .environmentObject(aiServiceRouter)
                .environmentObject(automationService)
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unifiedCompact)
        .defaultSize(width: 550, height: 900)
        
        // Settings Window - Using WindowGroup instead of Settings to ensure hiddenTitleBar works
        WindowGroup("Settings", id: "settings") {
            SettingsView()
                .environmentObject(automationService)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 600, height: 700)
        .commands {
            SettingsCommands()
        }
    }
}

struct SettingsCommands: Commands {
    @Environment(\.openWindow) private var openWindow
    
    var body: some Commands {
        CommandGroup(replacing: .appSettings) {
            Button("Nova Settings...") {
                openWindow(id: "settings")
            }
            .keyboardShortcut(",", modifiers: .command)
        }
    }
}
