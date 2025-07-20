//
//  OllamaModelDetectionService.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/16/25.
//

import Foundation

/// Model representing an Ollama model from system detection
struct DetectedOllamaModel: Codable {
    let name: String
    let size: String?
    let modifiedAt: String?

    enum CodingKeys: String, CodingKey {
        case name
        case size
        case modifiedAt = "modified_at"
    }
}

/// Service for detecting installed Ollama models on the system
class OllamaModelDetectionService {
    static let shared = OllamaModelDetectionService()
    
    private init() {}
    
    /// Attempts to find the Ollama executable in common installation locations
    /// - Returns: Path to Ollama executable, or nil if not found
    private func findOllamaExecutable() -> String? {
        let commonPaths = [
            "/usr/local/bin/ollama",           // Default installation path
            "/opt/homebrew/bin/ollama",        // Homebrew on Apple Silicon
            "/usr/bin/ollama",                 // System installation
            "/bin/ollama",                     // Alternative system path
            "\(NSHomeDirectory())/bin/ollama", // User local installation
            "\(NSHomeDirectory())/.local/bin/ollama" // User local bin
        ]
        
        // First try to use 'which' command to find in PATH
        if let pathFromWhich = findOllamaInPath() {
            return pathFromWhich
        }
        
        // Check common installation locations
        for path in commonPaths {
            if FileManager.default.fileExists(atPath: path) {
                // Verify it's executable
                if FileManager.default.isExecutableFile(atPath: path) {
                    return path
                }
            }
        }
        
        return nil
    }
    
    /// Uses 'which' command to find Ollama in PATH
    /// - Returns: Path to Ollama if found in PATH, nil otherwise
    private func findOllamaInPath() -> String? {
        // Check if we can access which command first
        guard FileManager.default.fileExists(atPath: "/usr/bin/which") else {
            print("⚠️ /usr/bin/which not accessible, skipping PATH search")
            return nil
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["ollama"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe() // Discard stderr
        
        do {
            try process.run()
            
            // Create a timeout mechanism to prevent hanging and SIGABRT
            let timeout: TimeInterval = 5.0 // 5 second timeout
            let startTime = Date()
            
            while process.isRunning {
                if Date().timeIntervalSince(startTime) > timeout {
                    print("⚠️ Process timeout - terminating 'which' command")
                    process.terminate()
                    return nil
                }
                Thread.sleep(forTimeInterval: 0.1)
            }
            
            guard process.terminationStatus == 0 else {
                print("⚠️ 'which ollama' command failed with status: \(process.terminationStatus)")
                return nil
            }
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            
            return output?.isEmpty == false ? output : nil
        } catch {
            print("⚠️ Failed to execute 'which' command: \(error)")
            return nil
        }
    }
    
    /// Detects installed Ollama models using the 'ollama list' command
    /// - Returns: Array of detected models, or empty array if detection fails
    func detectInstalledModels() -> [DetectedOllamaModel] {
        // Try to find Ollama executable in common locations
        guard let ollamaPath = findOllamaExecutable() else {
            print("❌ Ollama not found. Please install Ollama from https://ollama.ai")
            return []
        }
        
        print("🔍 Found Ollama at: \(ollamaPath)")
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ollamaPath)
        process.arguments = ["list"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            
            // Create a timeout mechanism to prevent hanging and SIGABRT
            let timeout: TimeInterval = 10.0 // 10 second timeout for ollama list
            let startTime = Date()
            
            while process.isRunning {
                if Date().timeIntervalSince(startTime) > timeout {
                    print("⚠️ Process timeout - terminating 'ollama list' command")
                    process.terminate()
                    return []
                }
                Thread.sleep(forTimeInterval: 0.1)
            }
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            
            guard process.terminationStatus == 0 else {
                print("❌ Ollama command failed with status: \(process.terminationStatus)")
                if let errorOutput = String(data: data, encoding: .utf8), !errorOutput.isEmpty {
                    print("❌ Error output: \(errorOutput)")
                }
                return []
            }
            
            // Parse the text output format
            if let textOutput = String(data: data, encoding: .utf8) {
                print("🔍 Ollama output: \(textOutput)")
                return parseTextOutput(textOutput)
            }
            
            print("❌ Failed to parse Ollama output")
            return []
            
        } catch {
            print("❌ Failed to run ollama command: \(error)")
            return []
        }
    }
    
    /// Parse text-based output from 'ollama list' command (fallback)
    private func parseTextOutput(_ output: String) -> [DetectedOllamaModel] {
        let lines = output.components(separatedBy: .newlines)
        var models: [DetectedOllamaModel] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip header lines and empty lines
            guard !trimmedLine.isEmpty,
                  !trimmedLine.lowercased().contains("name"),
                  !trimmedLine.lowercased().contains("id") else {
                continue
            }
            
            // Split by whitespace and take first component as model name
            let components = trimmedLine.components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }
            
            if let modelName = components.first {
                // Extract size if available (usually second column)
                let size = components.count > 1 ? components[1] : nil
                
                let model = DetectedOllamaModel(
                    name: modelName,
                    size: size,
                    modifiedAt: nil
                )
                models.append(model)
            }
        }
        
        print("✅ Parsed \(models.count) models from text output")
        return models
    }
    
    /// Convert detected models to AIModel format for configuration
    func convertToAIModels(_ detectedModels: [DetectedOllamaModel]) -> [AIModel] {
        return detectedModels.map { detected in
            let displayName = detected.name.capitalized
            let description = generateDescription(for: detected.name, size: detected.size)
            
            return AIModel(
                id: detected.name,
                name: detected.name,
                provider: .ollama,
                displayName: displayName,
                description: description,
                isRecommended: isRecommendedModel(detected.name)
            )
        }
    }
    
    /// Generate human-readable description for a model
    private func generateDescription(for modelName: String, size: String?) -> String {
        let baseName = modelName.lowercased()
        
        // Common model descriptions
        if baseName.contains("llama") {
            if baseName.contains("3.2") {
                return "Meta's latest Llama 3.2 model"
            } else if baseName.contains("3.1") {
                return "Meta's Llama 3.1 model"
            } else if baseName.contains("3") {
                return "Meta's Llama 3 model"
            }
            return "Meta's Llama model"
        }
        
        if baseName.contains("code") {
            return "Specialized for coding tasks"
        }
        
        if baseName.contains("mistral") {
            return "Mistral AI's efficient model"
        }
        
        if baseName.contains("gemma") {
            return "Google's Gemma model"
        }
        
        if baseName.contains("qwen") {
            return "Alibaba's Qwen model"
        }
        
        if baseName.contains("phi") {
            return "Microsoft's Phi model"
        }
        
        // Add size information if available
        if let size = size {
            return "Local AI model (\(size))"
        }
        
        return "Local AI model"
    }
    
    /// Determine if a model should be marked as recommended
    private func isRecommendedModel(_ modelName: String) -> Bool {
        let name = modelName.lowercased()
        
        // Prefer latest versions and commonly used models
        return name.contains("llama3.2") || 
               name.contains("mistral") ||
               (name.contains("llama") && !name.contains("code"))
    }
}