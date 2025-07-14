//
//  RenderConfiguration.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/11/25.
//

import SwiftUI

/// Default heading font function for markdown rendering
public func defaultHeadingFont(for level: Int) -> Font {
    switch level {
    case 1:
        return .system(size: 22, weight: .bold)
    case 2:
        return .system(size: 20, weight: .bold)
    case 3:
        return .system(size: 18, weight: .bold)
    case 4:
        return .system(size: 16, weight: .bold)
    case 5:
        return .system(size: 14, weight: .bold)
    case 6:
        return .system(size: 13, weight: .bold)
    default:
        return .system(size: 15, weight: .bold)
    }
}

/// Configuration for SwiftUI markdown rendering
public struct RenderConfiguration {
    
    // MARK: - Typography
    
    /// Font for body text
    public let bodyFont: Font
    
    /// Font for inline code
    public let inlineCodeFont: Font
    
    /// Font for code blocks
    public let codeFont: Font
    
    /// Font for code language labels
    public let codeLanguageFont: Font
    
    /// Function to get font for heading levels
    public let headingFont: (Int) -> Font
    
    // MARK: - Colors
    
    /// Primary text color
    public let textColor: Color
    
    /// Secondary text color
    public let secondaryTextColor: Color
    
    /// Link color
    public let linkColor: Color
    
    /// Code block background color
    public let codeBlockBackground: Color
    
    /// Code block border color
    public let codeBlockBorder: Color
    
    /// Inline code background color
    public let inlineCodeBackground: Color
    
    /// Blockquote accent color
    public let blockQuoteAccent: Color
    
    /// Blockquote background color
    public let blockQuoteBackground: Color
    
    /// Table background color
    public let tableBackground: Color
    
    /// Table border color
    public let tableBorder: Color
    
    /// Thematic break color
    public let thematicBreakColor: Color
    
    // MARK: - Spacing
    
    /// Spacing between block elements
    public let blockSpacing: CGFloat
    
    /// Spacing around paragraphs
    public let paragraphSpacing: CGFloat
    
    /// Spacing around headings
    public let headingSpacing: CGFloat
    
    /// Spacing around code blocks
    public let codeBlockSpacing: CGFloat
    
    /// Spacing around blockquotes
    public let blockQuoteSpacing: CGFloat
    
    /// Spacing around lists
    public let listSpacing: CGFloat
    
    /// Spacing around tables
    public let tableSpacing: CGFloat
    
    /// Spacing around thematic breaks
    public let thematicBreakSpacing: CGFloat
    
    // MARK: - Initializer
    
    public init(
        bodyFont: Font = .body,
        inlineCodeFont: Font = .system(.body, design: .monospaced),
        codeFont: Font = .system(.body, design: .monospaced),
        codeLanguageFont: Font = .system(size: 12, weight: .medium),
        headingFont: @escaping (Int) -> Font = defaultHeadingFont,
        textColor: Color = .primary,
        secondaryTextColor: Color = .secondary,
        linkColor: Color = .blue,
        codeBlockBackground: Color = Color(hex: "#2D2D2D"),
        codeBlockBorder: Color = Color(hex: "#404040"),
        inlineCodeBackground: Color = Color(hex: "#363636"),
        blockQuoteAccent: Color = Color(hex: "#4A90E2"),
        blockQuoteBackground: Color = Color(hex: "#252525"),
        tableBackground: Color = Color(hex: "#2A2A2A"),
        tableBorder: Color = Color(hex: "#404040"),
        thematicBreakColor: Color = .secondary,
        blockSpacing: CGFloat = 8,
        paragraphSpacing: CGFloat = 2,
        headingSpacing: CGFloat = 4,
        codeBlockSpacing: CGFloat = 4,
        blockQuoteSpacing: CGFloat = 4,
        listSpacing: CGFloat = 4,
        tableSpacing: CGFloat = 8,
        thematicBreakSpacing: CGFloat = 16
    ) {
        self.bodyFont = bodyFont
        self.inlineCodeFont = inlineCodeFont
        self.codeFont = codeFont
        self.codeLanguageFont = codeLanguageFont
        self.headingFont = headingFont
        self.textColor = textColor
        self.secondaryTextColor = secondaryTextColor
        self.linkColor = linkColor
        self.codeBlockBackground = codeBlockBackground
        self.codeBlockBorder = codeBlockBorder
        self.inlineCodeBackground = inlineCodeBackground
        self.blockQuoteAccent = blockQuoteAccent
        self.blockQuoteBackground = blockQuoteBackground
        self.tableBackground = tableBackground
        self.tableBorder = tableBorder
        self.thematicBreakColor = thematicBreakColor
        self.blockSpacing = blockSpacing
        self.paragraphSpacing = paragraphSpacing
        self.headingSpacing = headingSpacing
        self.codeBlockSpacing = codeBlockSpacing
        self.blockQuoteSpacing = blockQuoteSpacing
        self.listSpacing = listSpacing
        self.tableSpacing = tableSpacing
        self.thematicBreakSpacing = thematicBreakSpacing
    }
    
    // MARK: - Default Configurations
    
    /// Default configuration
    public static let `default` = RenderConfiguration()
    
    /// Chat-optimized configuration
    public static let chat = RenderConfiguration(
        bodyFont: .system(size: 15, weight: .regular),
        blockSpacing: 6,
        paragraphSpacing: 1,
        headingSpacing: 2,
        codeBlockSpacing: 2,
        blockQuoteSpacing: 2,
        listSpacing: 2
    )
    
    /// Compact configuration for smaller spaces
    public static let compact = RenderConfiguration(
        bodyFont: .system(size: 14, weight: .regular),
        blockSpacing: 4,
        paragraphSpacing: 1,
        headingSpacing: 1,
        codeBlockSpacing: 1,
        blockQuoteSpacing: 1,
        listSpacing: 1
    )
    

}

 