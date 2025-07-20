//
//  ChatView.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/11/25.
//

import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @EnvironmentObject var whisperService: WhisperService
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
    }
}
