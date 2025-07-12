//
//  ChatMessage.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/11/25.
//

import Foundation

struct ChatMessage: Identifiable, Codable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
    let isStreaming: Bool
    
    init(content: String, isUser: Bool, isStreaming: Bool = false) {
        self.content = content
        self.isUser = isUser
        self.timestamp = Date()
        self.isStreaming = isStreaming
    }
}