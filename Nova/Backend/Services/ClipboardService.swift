//
//  ClipboardService.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/16/25.
//

import Foundation
import AppKit

class ClipboardService: ObservableObject {
    
    static let shared = ClipboardService()
    
    private init() {}
    
    /// Retrieves the current clipboard content as a string
    /// Returns the top item from the macOS clipboard
    func getCurrentClipboardContent() -> String {
        let pasteboard = NSPasteboard.general
        
        // Try to get string content first (most common)
        if let string = pasteboard.string(forType: .string) {
            return string.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Try to get HTML content and convert to plain text
        if let html = pasteboard.string(forType: .html),
           let data = html.data(using: .utf8),
           let attributedString = try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.html],
            documentAttributes: nil
           ) {
            return attributedString.string.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Try to get RTF content and convert to plain text
        if let rtf = pasteboard.string(forType: .rtf),
           let data = rtf.data(using: .utf8),
           let attributedString = try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.rtf],
            documentAttributes: nil
           ) {
            return attributedString.string.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Try to get URL content
        if let url = pasteboard.string(forType: .URL) {
            return url.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Try to get file URL content
        if let fileURL = pasteboard.string(forType: .fileURL) {
            return fileURL.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // If no text content is available, return a descriptive message
        let availableTypes = pasteboard.types?.map { $0.rawValue } ?? []
        if availableTypes.isEmpty {
            return "[Empty clipboard]"
        } else {
            return "[Non-text content: \(availableTypes.joined(separator: ", "))]"
        }
    }
    
    /// Checks if clipboard has any content
    var hasContent: Bool {
        let pasteboard = NSPasteboard.general
        return !(pasteboard.types?.isEmpty ?? true)
    }
    
    /// Gets clipboard content with metadata about the type
    func getClipboardContentWithMetadata() -> (content: String, type: String) {
        let pasteboard = NSPasteboard.general
        
        if let string = pasteboard.string(forType: .string) {
            return (string.trimmingCharacters(in: .whitespacesAndNewlines), "text")
        }
        
        if let html = pasteboard.string(forType: .html) {
            if let data = html.data(using: .utf8),
               let attributedString = try? NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.html],
                documentAttributes: nil
               ) {
                return (attributedString.string.trimmingCharacters(in: .whitespacesAndNewlines), "html")
            }
        }
        
        if let url = pasteboard.string(forType: .URL) {
            return (url.trimmingCharacters(in: .whitespacesAndNewlines), "url")
        }
        
        if let fileURL = pasteboard.string(forType: .fileURL) {
            return (fileURL.trimmingCharacters(in: .whitespacesAndNewlines), "file")
        }
        
        if pasteboard.canReadItem(withDataConformingToTypes: [NSPasteboard.PasteboardType.tiff.rawValue, NSPasteboard.PasteboardType.png.rawValue]) {
            return ("[Image content]", "image")
        }
        
        let availableTypes = pasteboard.types?.map { $0.rawValue } ?? []
        if availableTypes.isEmpty {
            return ("[Empty clipboard]", "empty")
        } else {
            return ("[Non-text content: \(availableTypes.joined(separator: ", "))]", "other")
        }
    }
    
    /// Retrieves an image from the clipboard
    /// - Returns: An NSImage if available, otherwise nil
    func getClipboardImage() -> NSImage? {
        let pasteboard = NSPasteboard.general
        
        if pasteboard.canReadItem(withDataConformingToTypes: [NSPasteboard.PasteboardType.tiff.rawValue, NSPasteboard.PasteboardType.png.rawValue]) {
            return NSImage(pasteboard: pasteboard)
        }
        
        return nil
    }
}
