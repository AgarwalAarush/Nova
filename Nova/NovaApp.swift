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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
