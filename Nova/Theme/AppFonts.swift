//
//  AppFonts.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/11/25.
//

import SwiftUI

struct AppFonts {
    // Headings
    static let largeTitle = Font.largeTitle
    static let title1 = Font.title
    static let title2 = Font.title2
    static let title3 = Font.title3
    static let headline = Font.headline
    static let subheadline = Font.subheadline
    
    // Body text
    static let body = Font.body
    static let bodyMedium = Font.body.weight(.medium)
    static let callout = Font.callout
    static let footnote = Font.footnote
    static let caption1 = Font.caption
    static let caption2 = Font.caption2
    
    // Chat specific
    static let messageBody = Font.system(size: 14)
    static let messageTimestamp = Font.caption.weight(.medium)
    static let inputField = Font.system(size: 13)
    
    // Code and monospace
    static let codeBlock = Font.system(size: 14, design: .monospaced)
    static let inlineCode = Font.system(size: 15, design: .monospaced)
}
