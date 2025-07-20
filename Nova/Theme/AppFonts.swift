//
//  AppFonts.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/11/25.
//

import SwiftUI

struct AppFonts {
    // Custom font family
    // private static let fontFamily = "Open Sans"
    private static let fontFamily = "JetBrains Mono"
    private static let codeFamily = "JetBrains Mono"
    
    // Headings
    static let largeTitle = Font.custom(fontFamily, size: 34).weight(.regular)
    static let title1 = Font.custom(fontFamily, size: 28).weight(.regular)
    static let title2 = Font.custom(fontFamily, size: 22).weight(.regular)
    static let title3 = Font.custom(fontFamily, size: 20).weight(.regular)
    static let headline = Font.custom(fontFamily, size: 17).weight(.semibold)
    static let subheadline = Font.custom(fontFamily, size: 15).weight(.regular)
    
    // Body text
    static let body = Font.custom(fontFamily, size: 14).weight(.regular)
    static let bodyMedium = Font.custom(fontFamily, size: 14).weight(.medium)
    static let callout = Font.custom(fontFamily, size: 13).weight(.regular)
    static let footnote = Font.custom(fontFamily, size: 12).weight(.regular)
    static let caption1 = Font.custom(fontFamily, size: 12).weight(.regular)
    static let caption2 = Font.custom(fontFamily, size: 11).weight(.regular)
    static let modelNameSmall = Font.custom(fontFamily, size: 13).weight(.regular)
    
    // Chat specific
    static let messageBody = Font.custom(fontFamily, size: 14).weight(.regular)
    static let messageTimestamp = Font.custom(fontFamily, size: 12).weight(.medium)
    static let inputField = Font.custom(fontFamily, size: 14).weight(.regular)
    
    // Code and monospace
    static let codeBlock = Font.custom(codeFamily, size: 14)
    static let inlineCode = Font.custom(codeFamily, size: 15)
}
