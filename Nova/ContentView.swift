//
//  ContentView.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/10/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var chatViewModel = ChatViewModel()
    
    var body: some View {
        ChatView(viewModel: chatViewModel)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.background)
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
