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
        ScrollViewReader { proxy in
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
            .onChange(of: messages.count) { _ in
                if let lastMessage = messages.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
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
        Text(message.content)
            .font(.system(size: 15, weight: .regular))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                AppColors.userMessageBackground
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            )
            .frame(maxWidth: 300, alignment: .trailing)
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
                Text(LocalizedStringKey(message.content))
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
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