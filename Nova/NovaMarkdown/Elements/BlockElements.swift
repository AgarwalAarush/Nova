//
//  BlockElements.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/11/25.
//

import Foundation

/// Document root element
public class Document: BaseMarkup, BlockContainer {
    public var blocks: [BlockMarkup] {
        return children.compactMap { $0 as? BlockMarkup }
    }
    
    public override func accept<V: MarkupVisitor>(_ visitor: V) -> V.Result {
        return visitor.visitDocument(self)
    }
    
    /// Create document from parsing string
    public convenience init(parsing string: String, options: ParseOptions = .chatDefault) {
        self.init()
        let parser = MarkdownParser(options: options)
        let parsedDocument = parser.parse(string)
        self.children = parsedDocument.children
        for child in self.children {
            child.parent = self
        }
    }
}

/// Paragraph element
public class Paragraph: BaseMarkup, BlockMarkup, InlineContainer {
    public var inlines: [InlineMarkup] {
        return children.compactMap { $0 as? InlineMarkup }
    }
    
    public override func accept<V: MarkupVisitor>(_ visitor: V) -> V.Result {
        return visitor.visitParagraph(self)
    }
    
    /// Create paragraph with inline content
    public convenience init(inlines: [InlineMarkup]) {
        self.init()
        for inline in inlines {
            addChild(inline)
        }
    }
}

/// Heading element (H1-H6)
public class Heading: BaseMarkup, BlockMarkup, InlineContainer {
    public let level: Int
    
    public var inlines: [InlineMarkup] {
        return children.compactMap { $0 as? InlineMarkup }
    }
    
    public required init() {
        self.level = 1
        super.init()
    }
    
    public init(level: Int) {
        self.level = max(1, min(6, level))
        super.init()
    }
    
    public override func accept<V: MarkupVisitor>(_ visitor: V) -> V.Result {
        return visitor.visitHeading(self)
    }
    
    /// Create heading with level and inline content
    public convenience init(level: Int, inlines: [InlineMarkup]) {
        self.init(level: level)
        for inline in inlines {
            addChild(inline)
        }
    }
}

/// Code block element
public class CodeBlock: BaseMarkup, BlockMarkup {
    public let language: String?
    public let code: String
    
    public required init() {
        self.language = nil
        self.code = ""
        super.init()
    }
    
    public init(language: String? = nil, code: String) {
        self.language = language
        self.code = code
        super.init()
    }
    
    public override func accept<V: MarkupVisitor>(_ visitor: V) -> V.Result {
        return visitor.visitCodeBlock(self)
    }
    
    public override var plainText: String {
        return code
    }
}

/// Blockquote element
public class BlockQuote: BaseMarkup, BlockMarkup, BlockContainer {
    public var blocks: [BlockMarkup] {
        return children.compactMap { $0 as? BlockMarkup }
    }
    
    public override func accept<V: MarkupVisitor>(_ visitor: V) -> V.Result {
        return visitor.visitBlockQuote(self)
    }
    
    /// Create blockquote with block content
    public convenience init(blocks: [BlockMarkup]) {
        self.init()
        for block in blocks {
            addChild(block)
        }
    }
}

/// Unordered list element
public class UnorderedList: BaseMarkup, BlockMarkup {
    public var items: [ListItem] {
        return children.compactMap { $0 as? ListItem }
    }
    
    public override func accept<V: MarkupVisitor>(_ visitor: V) -> V.Result {
        return visitor.visitUnorderedList(self)
    }
    
    /// Create unordered list with items
    public convenience init(items: [ListItem]) {
        self.init()
        for item in items {
            addChild(item)
        }
    }
}

/// Ordered list element
public class OrderedList: BaseMarkup, BlockMarkup {
    public let startingNumber: Int
    
    public var items: [ListItem] {
        return children.compactMap { $0 as? ListItem }
    }
    
    public required init() {
        self.startingNumber = 1
        super.init()
    }
    
    public init(startingNumber: Int = 1) {
        self.startingNumber = startingNumber
        super.init()
    }
    
    public override func accept<V: MarkupVisitor>(_ visitor: V) -> V.Result {
        return visitor.visitOrderedList(self)
    }
    
    /// Create ordered list with items
    public convenience init(startingNumber: Int = 1, items: [ListItem]) {
        self.init(startingNumber: startingNumber)
        for item in items {
            addChild(item)
        }
    }
}

/// List item element
public class ListItem: BaseMarkup, BlockMarkup, BlockContainer {
    public enum Checkbox {
        case checked
        case unchecked
    }
    
    public let checkbox: Checkbox?
    
    public var blocks: [BlockMarkup] {
        return children.compactMap { $0 as? BlockMarkup }
    }
    
    public required init() {
        self.checkbox = nil
        super.init()
    }
    
    public init(checkbox: Checkbox? = nil) {
        self.checkbox = checkbox
        super.init()
    }
    
    public override func accept<V: MarkupVisitor>(_ visitor: V) -> V.Result {
        return visitor.visitListItem(self)
    }
    
    /// Create list item with block content
    public convenience init(checkbox: Checkbox? = nil, blocks: [BlockMarkup]) {
        self.init(checkbox: checkbox)
        for block in blocks {
            addChild(block)
        }
    }
}

/// Table element
public class Table: BaseMarkup, BlockMarkup {
    public var rows: [TableRow] {
        return children.compactMap { $0 as? TableRow }
    }
    
    public var headerRow: TableRow? {
        return rows.first
    }
    
    public var bodyRows: [TableRow] {
        return Array(rows.dropFirst())
    }
    
    public override func accept<V: MarkupVisitor>(_ visitor: V) -> V.Result {
        return visitor.visitTable(self)
    }
    
    /// Create table with rows
    public convenience init(rows: [TableRow]) {
        self.init()
        for row in rows {
            addChild(row)
        }
    }
}

/// Table row element
public class TableRow: BaseMarkup, BlockMarkup {
    public var cells: [TableCell] {
        return children.compactMap { $0 as? TableCell }
    }
    
    public override func accept<V: MarkupVisitor>(_ visitor: V) -> V.Result {
        return visitor.visitTableRow(self)
    }
    
    /// Create table row with cells
    public convenience init(cells: [TableCell]) {
        self.init()
        for cell in cells {
            addChild(cell)
        }
    }
}

/// Table cell element
public class TableCell: BaseMarkup, BlockMarkup, InlineContainer {
    public enum Alignment {
        case left
        case center
        case right
    }
    
    public let alignment: Alignment
    
    public var inlines: [InlineMarkup] {
        return children.compactMap { $0 as? InlineMarkup }
    }
    
    public required init() {
        self.alignment = .left
        super.init()
    }
    
    public init(alignment: Alignment = .left) {
        self.alignment = alignment
        super.init()
    }
    
    public override func accept<V: MarkupVisitor>(_ visitor: V) -> V.Result {
        return visitor.visitTableCell(self)
    }
    
    /// Create table cell with inline content
    public convenience init(alignment: Alignment = .left, inlines: [InlineMarkup]) {
        self.init(alignment: alignment)
        for inline in inlines {
            addChild(inline)
        }
    }
}

/// Thematic break element (horizontal rule)
public class ThematicBreak: BaseMarkup, BlockMarkup {
    public override func accept<V: MarkupVisitor>(_ visitor: V) -> V.Result {
        return visitor.visitThematicBreak(self)
    }
    
    public override var plainText: String {
        return "---"
    }
} 