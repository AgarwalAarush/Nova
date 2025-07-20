//
//  ToolCallExecutor.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/17/25.
//

import Foundation
import AppKit

/// Context for storing tool call execution results and passing data between calls
class ToolCallContext {
    private var storage: [String: Any] = [:]
    private var executionResults: [ToolCallResult] = []
    
    /// Store a value with a key
    func store<T>(_ value: T, forKey key: String) {
        storage[key] = value
    }
    
    /// Retrieve a value by key and type
    func retrieve<T>(_ type: T.Type, forKey key: String) -> T? {
        return storage[key] as? T
    }
    
    /// Add an execution result
    func addResult(_ result: ToolCallResult) {
        executionResults.append(result)
    }
    
    /// Get all execution results
    var results: [ToolCallResult] { executionResults }
    
    /// Get the last execution result
    var lastResult: ToolCallResult? { executionResults.last }
    
    /// Check if a key exists
    func hasValue(forKey key: String) -> Bool {
        return storage[key] != nil
    }
    
    /// Clear all stored data
    func clear() {
        storage.removeAll()
        executionResults.removeAll()
    }
}

/// Result of a tool call execution
struct ToolCallResult {
    let toolName: String
    let success: Bool
    let output: Any?
    let error: Error?
    let timestamp: Date
    
    init(toolName: String, success: Bool, output: Any? = nil, error: Error? = nil) {
        self.toolName = toolName
        self.success = success
        self.output = output
        self.error = error
        self.timestamp = Date()
    }
}


/// Service responsible for executing tool calls by dispatching to appropriate automation services
@MainActor
class ToolCallExecutor: ObservableObject {
    private var automationService: SystemAutomationService
    private var aiServiceRouter: AIServiceRouter?
    
    init(automationService: SystemAutomationService, aiServiceRouter: AIServiceRouter? = nil) {
        self.automationService = automationService
        self.aiServiceRouter = aiServiceRouter
    }
    
    /// Set the AI service router reference (used to avoid circular dependency in initialization)
    func setAIServiceRouter(_ router: AIServiceRouter) {
        self.aiServiceRouter = router
    }
    
    /// Update the automation service reference
    func updateAutomationService(_ service: SystemAutomationService) {
        self.automationService = service
    }
    
    /// Execute a sequence of tool calls with context sharing
    func executeToolCalls(_ toolCalls: [ToolCall]) async throws -> ToolCallExecutionResult {
        let context = ToolCallContext()
        var successCount = 0
        var errorMessages: [String] = []
        
        for toolCall in toolCalls {
            do {
                let result = try await executeToolCall(toolCall, context: context)
                context.addResult(result)
                
                if result.success {
                    successCount += 1
                } else if let error = result.error {
                    errorMessages.append("❌ \(toolCall.name): \(error.localizedDescription)")
                }
            } catch {
                let errorResult = ToolCallResult(toolName: toolCall.name, success: false, error: error)
                context.addResult(errorResult)
                errorMessages.append("❌ \(toolCall.name): \(error.localizedDescription)")
            }
        }
        
        // Generate summary response
        let summary = generateExecutionSummary(context: context, successCount: successCount, totalCount: toolCalls.count)
        
        return ToolCallExecutionResult(
            success: successCount == toolCalls.count,
            summary: summary,
            context: context,
            toolCallResults: context.results
        )
    }
    
    /// Execute a single tool call
    private func executeToolCall(_ toolCall: ToolCall, context: ToolCallContext) async throws -> ToolCallResult {
        switch toolCall.name {
        // Screenshot tools
        case "captureScreen":
            let screenshot = try await automationService.captureScreen()
            context.store(screenshot, forKey: "lastScreenshot")
            context.store(screenshot.image, forKey: "screenshot")
            return ToolCallResult(toolName: toolCall.name, success: true, output: "Screenshot captured successfully")
            
        case "captureWindow":
            guard let windowID = toolCall.parameters["windowID"] as? UInt32 else {
                throw ToolCallError.invalidParameters("captureWindow requires windowID parameter")
            }
            let screenshot = try await automationService.captureWindow(windowID)
            context.store(screenshot, forKey: "lastScreenshot")
            context.store(screenshot.image, forKey: "screenshot")
            return ToolCallResult(toolName: toolCall.name, success: true, output: "Window screenshot captured successfully")
            
        case "getLastScreenshot":
            if let screenshot = try await automationService.getLastScreenshot() {
                context.store(screenshot, forKey: "lastScreenshot")
                context.store(screenshot.image, forKey: "screenshot")
                return ToolCallResult(toolName: toolCall.name, success: true, output: screenshot)
            } else {
                return ToolCallResult(toolName: toolCall.name, success: false, output: "No previous screenshot available")
            }
            
        // Clipboard tools
        case "getClipboardContent":
            let clipboardContent = try await automationService.getClipboardContent()
            context.store(clipboardContent.content, forKey: "clipboard")
            context.store(clipboardContent, forKey: "clipboardContent")
            return ToolCallResult(toolName: toolCall.name, success: true, output: clipboardContent.content)
            
        case "getClipboardContentWithMetadata":
            let clipboardContent = try await automationService.getClipboardContentWithMetadata()
            context.store(clipboardContent.content, forKey: "clipboard")
            context.store(clipboardContent, forKey: "clipboardContent")
            return ToolCallResult(toolName: toolCall.name, success: true, output: clipboardContent)
            
        case "getClipboardImage":
            if let clipboardImage = try await automationService.getClipboardImage() {
                context.store(clipboardImage.image, forKey: "clipboardImage")
                return ToolCallResult(toolName: toolCall.name, success: true, output: clipboardImage)
            } else {
                return ToolCallResult(toolName: toolCall.name, success: false, output: "No image in clipboard")
            }
            
        case "setClipboardContent":
            guard let content = toolCall.parameters["content"] as? String else {
                throw ToolCallError.invalidParameters("setClipboardContent requires content parameter")
            }
            try await automationService.setClipboardContent(content)
            return ToolCallResult(toolName: toolCall.name, success: true, output: "Clipboard content set")
            
        case "clearClipboard":
            try await automationService.clearClipboard()
            return ToolCallResult(toolName: toolCall.name, success: true, output: "Clipboard cleared")
            
        // Application management
        case "launchApplication":
            guard let bundleIdentifier = toolCall.parameters["bundleIdentifier"] as? String else {
                throw ToolCallError.invalidParameters("launchApplication requires bundleIdentifier parameter")
            }
            try await automationService.launchApplication(bundleIdentifier)
            return ToolCallResult(toolName: toolCall.name, success: true, output: "Launched application: \(bundleIdentifier)")
            
        case "quitApplication":
            guard let bundleIdentifier = toolCall.parameters["bundleIdentifier"] as? String else {
                throw ToolCallError.invalidParameters("quitApplication requires bundleIdentifier parameter")
            }
            let force = toolCall.parameters["force"] as? Bool ?? false
            try await automationService.quitApplication(bundleIdentifier, force: force)
            return ToolCallResult(toolName: toolCall.name, success: true, output: "Quit application: \(bundleIdentifier)")
            
        case "activateApplication":
            guard let bundleIdentifier = toolCall.parameters["bundleIdentifier"] as? String else {
                throw ToolCallError.invalidParameters("activateApplication requires bundleIdentifier parameter")
            }
            try await automationService.activateApplication(bundleIdentifier)
            return ToolCallResult(toolName: toolCall.name, success: true, output: "Activated application: \(bundleIdentifier)")
            
        case "getRunningApplications":
            let apps = try await automationService.getRunningApplications()
            context.store(apps, forKey: "runningApplications")
            return ToolCallResult(toolName: toolCall.name, success: true, output: apps)
            
        // User preferences
        case "updateUserPreferences":
            guard let preferences = toolCall.parameters["preferences"] as? [String] else {
                throw ToolCallError.invalidParameters("updateUserPreferences requires preferences parameter")
            }
            try await automationService.updateUserPreferences(preferences)
            return ToolCallResult(toolName: toolCall.name, success: true, output: "Updated user preferences with \(preferences.count) items")
            
        case "getUserPreferences":
            let preferences = try await automationService.getUserPreferences()
            context.store(preferences, forKey: "userPreferences")
            return ToolCallResult(toolName: toolCall.name, success: true, output: preferences)
            
        // System control
        case "sleepSystem":
            try await automationService.sleepSystem()
            return ToolCallResult(toolName: toolCall.name, success: true, output: "System sleep initiated")
            
        case "lockScreen":
            try await automationService.lockScreen()
            return ToolCallResult(toolName: toolCall.name, success: true, output: "Screen locked")
            
        // AI model requests
        case "requestModel":
            guard let prompt = toolCall.parameters["prompt"] as? String else {
                throw ToolCallError.invalidParameters("requestModel requires prompt parameter")
            }
            guard let aiRouter = aiServiceRouter else {
                throw ToolCallError.serviceNotAvailable("AI service router not available")
            }
            
            // Enhance prompt with context data if available
            let enhancedPrompt = enhancePromptWithContext(prompt, context: context)
            
            // Make the AI request
            let response = try await aiRouter.generateResponse(for: enhancedPrompt)
            context.store(response, forKey: "lastModelResponse")
            return ToolCallResult(toolName: toolCall.name, success: true, output: response)
            
        default:
            throw ToolCallError.unknownTool("Unknown tool: \(toolCall.name)")
        }
    }
    
    /// Enhance a prompt with available context data
    private func enhancePromptWithContext(_ prompt: String, context: ToolCallContext) -> String {
        var enhancedPrompt = prompt
        
        // Add clipboard content if available
        if let clipboardContent = context.retrieve(String.self, forKey: "clipboard") {
            enhancedPrompt += "\n\nClipboard content: \(clipboardContent)"
        }
        
        // Add screenshot info if available
        if context.hasValue(forKey: "screenshot") {
            enhancedPrompt += "\n\nScreenshot: [Screenshot data available for analysis]"
        }
        
        // Add user preferences if available
        if let preferences = context.retrieve([String].self, forKey: "userPreferences") {
            enhancedPrompt += "\n\nUser preferences: \(preferences.joined(separator: ", "))"
        }
        
        return enhancedPrompt
    }
    
    /// Generate a summary of tool call execution results
    private func generateExecutionSummary(context: ToolCallContext, successCount: Int, totalCount: Int) -> String {
        let results = context.results
        
        if successCount == totalCount {
            // All successful - check if final tool call was requestModel
            if let lastResult = results.last, lastResult.toolName == "requestModel" {
                if let modelResponse = context.retrieve(String.self, forKey: "lastModelResponse") {
                    return modelResponse
                }
            }
            
            // Generate success summary
            let successMessages = results.compactMap { result in
                result.success ? "✅ \(result.toolName)" : nil
            }
            return "Successfully completed tasks:\n" + successMessages.joined(separator: "\n")
        } else {
            // Mixed results
            var summaryLines: [String] = []
            for result in results {
                if result.success {
                    summaryLines.append("✅ \(result.toolName)")
                } else {
                    let errorMsg = result.error?.localizedDescription ?? "Unknown error"
                    summaryLines.append("❌ \(result.toolName): \(errorMsg)")
                }
            }
            return summaryLines.joined(separator: "\n")
        }
    }
}

/// Result of tool call execution
struct ToolCallExecutionResult {
    let success: Bool
    let summary: String
    let context: ToolCallContext
    let toolCallResults: [ToolCallResult]
}

/// Errors that can occur during tool call execution
enum ToolCallError: Error, LocalizedError {
    case unknownTool(String)
    case invalidParameters(String)
    case serviceNotAvailable(String)
    case executionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .unknownTool(let tool):
            return "Unknown tool: \(tool)"
        case .invalidParameters(let message):
            return "Invalid parameters: \(message)"
        case .serviceNotAvailable(let service):
            return "Service not available: \(service)"
        case .executionFailed(let message):
            return "Execution failed: \(message)"
        }
    }
}