//
//  OllamaConfiguration.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/11/25.
//

import Foundation

struct OllamaConfiguration {
    static let shared = OllamaConfiguration()
    
    let baseURL: URL
    let defaultModel: String
    let timeout: TimeInterval
    let defaultOptions: OllamaOptions
    
    private init() {
        self.baseURL = URL(string: "http://localhost:11434")!
        self.defaultModel = "gemma3:4b"
        self.timeout = 60.0
        self.defaultOptions = OllamaOptions.default
    }
    
    var chatEndpoint: URL {
        baseURL.appendingPathComponent("api/chat")
    }
    
    var generateEndpoint: URL {
        baseURL.appendingPathComponent("api/generate")
    }
    
    var modelsEndpoint: URL {
        baseURL.appendingPathComponent("api/tags")
    }
}