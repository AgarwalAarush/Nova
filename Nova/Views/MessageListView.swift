//
//  MessageListView.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/11/25.
//

import SwiftUI

struct MessageListView: View {
    let messages: [ChatMessage]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(messages) { message in
                    MessageRowView(message: message)
                        .id(message.id)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
}

struct MessageRowView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                UserMessageView(message: message)
            } else {
                AIMessageView(message: message)
                Spacer()
            }
        }
    }
}

struct UserMessageView: View {
    let message: ChatMessage
    
    var body: some View {
        SwiftUI.Text(message.content)
            .foregroundColor(Color.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                AppColors.userMessageBackground
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            )
            .frame(maxWidth: 300, alignment: .trailing)
            .font(AppFonts.messageBody)
    }
}

struct AIMessageView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.content.isEmpty {
                // Typing indicator for empty/streaming messages
                TypingIndicator()
            } else {
                NovaMarkdownView.chat(message.content)
                    .frame(maxWidth: .infinity, alignment: Alignment.leading)
            }
        }
    }
}

struct TypingIndicator: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.gray)
                    .frame(width: 6, height: 6)
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
