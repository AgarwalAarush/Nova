//
//  NovaMarkdownView.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/11/25.
//

import SwiftUI

/// Main SwiftUI view for rendering markdown content
public struct NovaMarkdownView: View {
    private let content: String
    private let configuration: RenderConfiguration
    private let options: ParseOptions
    
    /// Initialize with markdown content
    public init(
        _ content: String,
        configuration: RenderConfiguration = .chat,
        options: ParseOptions = .chatDefault
    ) {
        self.content = content
        self.configuration = configuration
        self.options = options
    }
    
    public var body: some View {
        Group {
            if content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                EmptyView()
            } else {
                let document = Document(parsing: content, options: options)
                let renderer = SwiftUIRenderer(configuration: configuration)
                renderer.visit(document)
            }
        }
    }
}

// MARK: - View Builders and Convenience Initializers

extension NovaMarkdownView {
    /// Create with custom configuration
    public static func custom(
        _ content: String,
        configuration: RenderConfiguration
    ) -> NovaMarkdownView {
        return NovaMarkdownView(content, configuration: configuration)
    }
    
    /// Create with chat-optimized configuration
    public static func chat(_ content: String) -> NovaMarkdownView {
        return NovaMarkdownView(content, configuration: .chat)
    }
    
    /// Create with compact configuration
    public static func compact(_ content: String) -> NovaMarkdownView {
        return NovaMarkdownView(content, configuration: .compact)
    }
    
    /// Create with default configuration
    public static func `default`(_ content: String) -> NovaMarkdownView {
        return NovaMarkdownView(content, configuration: .default)
    }
}

// MARK: - SwiftUI Integration

extension NovaMarkdownView {
    /// Apply custom configuration
    public func configuration(_ configuration: RenderConfiguration) -> NovaMarkdownView {
        return NovaMarkdownView(content, configuration: configuration, options: options)
    }
    
    /// Apply custom parse options
    public func parseOptions(_ options: ParseOptions) -> NovaMarkdownView {
        return NovaMarkdownView(content, configuration: configuration, options: options)
    }
    
    /// Apply custom body font
    public func bodyFont(_ font: Font) -> NovaMarkdownView {
        var newConfig = configuration
        let updatedConfig = RenderConfiguration(
            bodyFont: font,
            inlineCodeFont: newConfig.inlineCodeFont,
            codeFont: newConfig.codeFont,
            codeLanguageFont: newConfig.codeLanguageFont,
            headingFont: newConfig.headingFont,
            textColor: newConfig.textColor,
            secondaryTextColor: newConfig.secondaryTextColor,
            linkColor: newConfig.linkColor,
            codeBlockBackground: newConfig.codeBlockBackground,
            codeBlockBorder: newConfig.codeBlockBorder,
            inlineCodeBackground: newConfig.inlineCodeBackground,
            blockQuoteAccent: newConfig.blockQuoteAccent,
            blockQuoteBackground: newConfig.blockQuoteBackground,
            tableBackground: newConfig.tableBackground,
            tableBorder: newConfig.tableBorder,
            thematicBreakColor: newConfig.thematicBreakColor,
            blockSpacing: newConfig.blockSpacing,
            paragraphSpacing: newConfig.paragraphSpacing,
            headingSpacing: newConfig.headingSpacing,
            codeBlockSpacing: newConfig.codeBlockSpacing,
            blockQuoteSpacing: newConfig.blockQuoteSpacing,
            listSpacing: newConfig.listSpacing,
            tableSpacing: newConfig.tableSpacing,
            thematicBreakSpacing: newConfig.thematicBreakSpacing
        )
        return NovaMarkdownView(content, configuration: updatedConfig, options: options)
    }
    
    /// Apply custom text color
    public func textColor(_ color: Color) -> NovaMarkdownView {
        var newConfig = configuration
        let updatedConfig = RenderConfiguration(
            bodyFont: newConfig.bodyFont,
            inlineCodeFont: newConfig.inlineCodeFont,
            codeFont: newConfig.codeFont,
            codeLanguageFont: newConfig.codeLanguageFont,
            headingFont: newConfig.headingFont,
            textColor: color,
            secondaryTextColor: newConfig.secondaryTextColor,
            linkColor: newConfig.linkColor,
            codeBlockBackground: newConfig.codeBlockBackground,
            codeBlockBorder: newConfig.codeBlockBorder,
            inlineCodeBackground: newConfig.inlineCodeBackground,
            blockQuoteAccent: newConfig.blockQuoteAccent,
            blockQuoteBackground: newConfig.blockQuoteBackground,
            tableBackground: newConfig.tableBackground,
            tableBorder: newConfig.tableBorder,
            thematicBreakColor: newConfig.thematicBreakColor,
            blockSpacing: newConfig.blockSpacing,
            paragraphSpacing: newConfig.paragraphSpacing,
            headingSpacing: newConfig.headingSpacing,
            codeBlockSpacing: newConfig.codeBlockSpacing,
            blockQuoteSpacing: newConfig.blockQuoteSpacing,
            listSpacing: newConfig.listSpacing,
            tableSpacing: newConfig.tableSpacing,
            thematicBreakSpacing: newConfig.thematicBreakSpacing
        )
        return NovaMarkdownView(content, configuration: updatedConfig, options: options)
    }
}

// MARK: - Previews

#if DEBUG
struct NovaMarkdownView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                NovaMarkdownView.chat("""
                # Hello, World!
                
                This is a **bold** and *italic* text with some `inline code`.
                
                ## Code Block
                
                ```swift
                func hello() {
                    print("Hello, World!")
                }
                ```
                
                ## Lists
                
                ### Unordered List
                - Item 1
                - Item 2
                - Item 3
                
                ### Ordered List
                1. First item
                2. Second item
                3. Third item
                
                ### Task List
                - [x] Completed task
                - [ ] Pending task
                
                ## Blockquote
                
                > This is a blockquote with some **bold** text.
                > It can span multiple lines.
                
                ## Link
                
                Check out [Swift](https://swift.org) for more information.
                
                ## Thematic Break
                
                ---
                
                That's all for now!
                """)
                .padding()
            }
        }
        .background(Color.black)
        .previewDisplayName("Chat Configuration")
        
        ScrollView {
            VStack(spacing: 20) {
                NovaMarkdownView.compact("""
                # Compact Layout
                
                This uses the compact configuration with tighter spacing.
                
                - Item 1
                - Item 2
                
                ```swift
                let code = "example"
                ```
                """)
                .padding()
            }
        }
        .background(Color.black)
        .previewDisplayName("Compact Configuration")
    }
}
#endif 