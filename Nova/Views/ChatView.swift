//
//  ChatView.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/11/25.
//

import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            MessageListView(messages: viewModel.messages)
            InputBarView(
                currentInput: $viewModel.currentInput,
                onSend: viewModel.sendMessage
            )
        }
    }
}