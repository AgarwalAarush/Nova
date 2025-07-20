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
    @EnvironmentObject var whisperService: WhisperService
    @EnvironmentObject var aiServiceRouter: AIServiceRouter
    @StateObject private var chatViewModel: ChatViewModel
    @StateObject private var appConfig = AppConfig.shared
    @State private var currentHeight: CGFloat = 600
    
    init() {
        // We'll initialize chatViewModel in onAppear since we need environment objects
        _chatViewModel = StateObject(wrappedValue: ChatViewModel())
    }
    
    var body: some View {
        Group {
            switch chatViewModel.viewMode {
            case .normal:
                ChatView(viewModel: chatViewModel)
                    .frame(width: 550, height: chatViewModel.previousNormalHeight)
                    .background(GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                currentHeight = geometry.size.height
                            }
                            .onChange(of: geometry.size.height) { _, newHeight in
                                currentHeight = newHeight
                                if chatViewModel.viewMode == .normal {
                                    chatViewModel.previousNormalHeight = newHeight
                                }
                            }
                    })
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            case .compactVoice:
                CompactVoiceView(viewModel: chatViewModel)
                    .frame(width: 550, height: 38)
                    .onAppear {
                        // Store current height before compacting
                        if currentHeight > 38 {
                            chatViewModel.previousNormalHeight = currentHeight
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: chatViewModel.viewMode)
        .background(AppColors.background)
        .windowPinning(isPinned: $appConfig.enableWindowPinning)
        .onAppear {
            chatViewModel.setWhisperService(whisperService)
            chatViewModel.setAIServiceRouter(aiServiceRouter)
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(WhisperService())
        .environmentObject(AIServiceRouter())
}
