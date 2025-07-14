//
//  Markup.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/11/25.
//

import Foundation

/// Base protocol for all markup elements
public protocol Markup: AnyObject {
    /// Unique identifier for this markup element
    var id: UUID { get }
    
    /// Children of this markup element
    var children: [Markup] { get set }
    
    /// Parent reference (weak to avoid retain cycles)
    var parent: Markup? { get set }
    
    /// Accept visitor pattern
    func accept<V: MarkupVisitor>(_ visitor: V) -> V.Result
    
    /// Plain text representation
    var plainText: String { get }
}

/// Base class implementing common Markup functionality
public class BaseMarkup: Markup {
    public let id = UUID()
    public var children: [Markup] = []
    public weak var parent: Markup?
    
    public required init() {}
    
    public func accept<V: MarkupVisitor>(_ visitor: V) -> V.Result {
        return visitor.defaultVisit(self)
    }
    
    public var plainText: String {
        return children.map { $0.plainText }.joined()
    }
    
    /// Add child with parent reference
    public func addChild(_ child: Markup) {
        child.parent = self
        children.append(child)
    }
    
    /// Remove child and clear parent reference
    public func removeChild(_ child: Markup) {
        child.parent = nil
        children.removeAll { $0.id == child.id }
    }
    
    /// Replace child at index
    public func replaceChild(at index: Int, with newChild: Markup) {
        guard index >= 0 && index < children.count else { return }
        children[index].parent = nil
        newChild.parent = self
        children[index] = newChild
    }
}

/// Protocol for block-level markup elements
public protocol BlockMarkup: Markup {}

/// Protocol for inline markup elements  
public protocol InlineMarkup: Markup {}

/// Protocol for elements that can contain blocks
public protocol BlockContainer: Markup {
    var blocks: [BlockMarkup] { get }
}

/// Protocol for elements that can contain inline elements
public protocol InlineContainer: Markup {
    var inlines: [InlineMarkup] { get }
}

/// Source range information for debugging
public struct SourceRange: Equatable {
    public let start: Int
    public let end: Int
    
    public init(start: Int, end: Int) {
        self.start = start
        self.end = end
    }
}

/// Parse options for controlling markdown parsing
public struct ParseOptions: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    /// Parse strikethrough text
    public static let parseStrikethrough = ParseOptions(rawValue: 1 << 0)
    /// Parse task lists
    public static let parseTaskLists = ParseOptions(rawValue: 1 << 1)
    /// Parse tables
    public static let parseTables = ParseOptions(rawValue: 1 << 2)
    /// Parse autolinks
    public static let parseAutolinks = ParseOptions(rawValue: 1 << 3)
    
    /// Default options for chat messages
    public static let chatDefault: ParseOptions = [.parseStrikethrough, .parseTaskLists, .parseAutolinks]
} 