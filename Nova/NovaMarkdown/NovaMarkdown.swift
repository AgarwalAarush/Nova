//
//  NovaMarkdown.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/11/25.
//

import Foundation
import SwiftUI

// MARK: - Public API Exports

// Core Types
public typealias NovaDocument = Document
public typealias NovaMarkupParser = MarkdownParser

// SwiftUI Integration
public typealias NovaMarkdown = NovaMarkdownView

// Configuration
public typealias NovaRenderConfiguration = RenderConfiguration

// Parse Options
public typealias NovaParseOptions = ParseOptions

// MARK: - Convenience Extensions

extension NovaMarkdownView {
    /// Create markdown view with AppFonts integration
    public static func withAppFonts(_ content: String) -> NovaMarkdownView {
        let configuration = RenderConfiguration(
            bodyFont: AppFonts.messageBody,
            codeBlockBackground: AppColors.codeBlockBackground,
            codeBlockBorder: AppColors.codeBlockBorder,
            inlineCodeBackground: AppColors.inlineCodeBackground,
            blockQuoteAccent: AppColors.blockQuoteAccent,
            blockQuoteBackground: AppColors.blockQuoteBackground,
            blockSpacing: 6,
            paragraphSpacing: 1,
            headingSpacing: 2,
            codeBlockSpacing: 2,
            blockQuoteSpacing: 2,
            listSpacing: 2
        )
        return NovaMarkdownView(content, configuration: configuration)
    }
}

// MARK: - Version Information

public struct NovaMarkdownVersion {
    public static let current = "1.0.0"
    public static let buildDate = "2025-01-11"
    
    public static var info: String {
        return "NovaMarkdown v\(current) (Built: \(buildDate))"
    }
}

// MARK: - Module Documentation

/**
 # NovaMarkdown
 
 A SwiftUI-native markdown rendering library optimized for chat applications.
 
 ## Features
 
 - **SwiftUI Native**: Built specifically for SwiftUI with native view integration
 - **Chat Optimized**: Tailored for chat message rendering with appropriate spacing and styling
 - **Performant**: Efficient parsing and rendering with minimal overhead
 - **Extensible**: Configurable styling and parsing options
 - **Type Safe**: Strongly typed AST prevents invalid document structures
 
 ## Usage
 
 ### Basic Usage
 
 ```swift
 import SwiftUI
 
 struct ContentView: View {
     var body: some View {
         NovaMarkdownView.chat("Hello **world**!")
     }
 }
 ```
 
 ### With Custom Configuration
 
 ```swift
 let config = RenderConfiguration(
     bodyFont: .body,
     textColor: .primary,
     blockSpacing: 8
 )
 
 NovaMarkdownView("# Hello", configuration: config)
 ```
 
 ### Supported Markdown Elements
 
 - **Headings**: `# H1` through `###### H6`
 - **Paragraphs**: Regular text paragraphs
 - **Emphasis**: `*italic*` and `**bold**` text
 - **Strikethrough**: `~~strikethrough~~` text
 - **Inline Code**: `code` with backticks
 - **Code Blocks**: Fenced code blocks with optional language
 - **Links**: `[text](url)` format
 - **Images**: `![alt](url)` format
 - **Lists**: Ordered and unordered lists
 - **Task Lists**: `- [x]` and `- [ ]` checkboxes
 - **Blockquotes**: `> quoted text`
 - **Thematic Breaks**: `---` horizontal rules
 - **Tables**: GitHub-flavored markdown tables
 - **Autolinks**: Automatic URL detection
 
 ## Architecture
 
 NovaMarkdown follows a clean architecture with three main components:
 
 1. **Parser**: Converts markdown text to AST
 2. **AST**: Immutable tree structure representing the document
 3. **Renderer**: Visitor pattern for converting AST to SwiftUI views
 
 ## Performance
 
 - Efficient regex-based parsing optimized for chat messages
 - Lazy evaluation where possible
 - Minimal memory allocation during rendering
 - Thread-safe immutable data structures
 */ 