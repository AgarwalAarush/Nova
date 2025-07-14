//
//  InlineElements.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/11/25.
//

import Foundation

/// Text content element
public class Text: BaseMarkup, InlineMarkup {
    public let content: String
    
    public required init() {
        self.content = ""
        super.init()
    }
    
    public init(_ content: String) {
        self.content = content
        super.init()
    }
    
    public override func accept<V: MarkupVisitor>(_ visitor: V) -> V.Result {
        return visitor.visitText(self)
    }
    
    public override var plainText: String {
        return content
    }
}

/// Emphasized text (italic)
public class Emphasis: BaseMarkup, InlineMarkup, InlineContainer {
    public var inlines: [InlineMarkup] {
        return children.compactMap { $0 as? InlineMarkup }
    }
    
    public override func accept<V: MarkupVisitor>(_ visitor: V) -> V.Result {
        return visitor.visitEmphasis(self)
    }
    
    /// Create emphasis with inline content
    public convenience init(inlines: [InlineMarkup]) {
        self.init()
        for inline in inlines {
            addChild(inline)
        }
    }
}

/// Strong text (bold)
public class Strong: BaseMarkup, InlineMarkup, InlineContainer {
    public var inlines: [InlineMarkup] {
        return children.compactMap { $0 as? InlineMarkup }
    }
    
    public override func accept<V: MarkupVisitor>(_ visitor: V) -> V.Result {
        return visitor.visitStrong(self)
    }
    
    /// Create strong with inline content
    public convenience init(inlines: [InlineMarkup]) {
        self.init()
        for inline in inlines {
            addChild(inline)
        }
    }
}

/// Strikethrough text
public class Strikethrough: BaseMarkup, InlineMarkup, InlineContainer {
    public var inlines: [InlineMarkup] {
        return children.compactMap { $0 as? InlineMarkup }
    }
    
    public override func accept<V: MarkupVisitor>(_ visitor: V) -> V.Result {
        return visitor.visitStrikethrough(self)
    }
    
    /// Create strikethrough with inline content
    public convenience init(inlines: [InlineMarkup]) {
        self.init()
        for inline in inlines {
            addChild(inline)
        }
    }
}

/// Inline code element
public class InlineCode: BaseMarkup, InlineMarkup {
    public let code: String
    
    public required init() {
        self.code = ""
        super.init()
    }
    
    public init(_ code: String) {
        self.code = code
        super.init()
    }
    
    public override func accept<V: MarkupVisitor>(_ visitor: V) -> V.Result {
        return visitor.visitInlineCode(self)
    }
    
    public override var plainText: String {
        return code
    }
}

/// Hyperlink element
public class Link: BaseMarkup, InlineMarkup, InlineContainer {
    public let destination: String
    public let title: String?
    
    public var inlines: [InlineMarkup] {
        return children.compactMap { $0 as? InlineMarkup }
    }
    
    public required init() {
        self.destination = ""
        self.title = nil
        super.init()
    }
    
    public init(destination: String, title: String? = nil) {
        self.destination = destination
        self.title = title
        super.init()
    }
    
    public override func accept<V: MarkupVisitor>(_ visitor: V) -> V.Result {
        return visitor.visitLink(self)
    }
    
    /// Create link with destination and inline content
    public convenience init(destination: String, title: String? = nil, inlines: [InlineMarkup]) {
        self.init(destination: destination, title: title)
        for inline in inlines {
            addChild(inline)
        }
    }
}

/// Image element
public class Image: BaseMarkup, InlineMarkup, InlineContainer {
    public let source: String
    public let title: String?
    
    public var inlines: [InlineMarkup] {
        return children.compactMap { $0 as? InlineMarkup }
    }
    
    public required init() {
        self.source = ""
        self.title = nil
        super.init()
    }
    
    public init(source: String, title: String? = nil) {
        self.source = source
        self.title = title
        super.init()
    }
    
    public override func accept<V: MarkupVisitor>(_ visitor: V) -> V.Result {
        return visitor.visitImage(self)
    }
    
    /// Create image with source and alt text
    public convenience init(source: String, title: String? = nil, altText: [InlineMarkup]) {
        self.init(source: source, title: title)
        for inline in altText {
            addChild(inline)
        }
    }
}

/// Line break element (hard break)
public class LineBreak: BaseMarkup, InlineMarkup {
    public override func accept<V: MarkupVisitor>(_ visitor: V) -> V.Result {
        return visitor.visitLineBreak(self)
    }
    
    public override var plainText: String {
        return "\n"
    }
}

/// Soft break element (space or newline that doesn't create a line break)
public class SoftBreak: BaseMarkup, InlineMarkup {
    public override func accept<V: MarkupVisitor>(_ visitor: V) -> V.Result {
        return visitor.visitSoftBreak(self)
    }
    
    public override var plainText: String {
        return " "
    }
} 