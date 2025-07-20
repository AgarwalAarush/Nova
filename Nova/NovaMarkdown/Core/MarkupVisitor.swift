//
//  MarkupVisitor.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/11/25.
//

import Foundation

/// Base visitor protocol for markup traversal
public protocol MarkupVisitor {
    associatedtype Result
    
    /// Visit any markup element
    func visit(_ markup: Markup) -> Result
    
    // Block elements
    func visitDocument(_ document: Document) -> Result
    func visitParagraph(_ paragraph: Paragraph) -> Result
    func visitHeading(_ heading: Heading) -> Result
    func visitCodeBlock(_ codeBlock: CodeBlock) -> Result
    func visitBlockQuote(_ blockQuote: BlockQuote) -> Result
    func visitUnorderedList(_ unorderedList: UnorderedList) -> Result
    func visitOrderedList(_ orderedList: OrderedList) -> Result
    func visitListItem(_ listItem: ListItem) -> Result
    func visitTable(_ table: Table) -> Result
    func visitTableRow(_ tableRow: TableRow) -> Result
    func visitTableCell(_ tableCell: TableCell) -> Result
    func visitThematicBreak(_ thematicBreak: ThematicBreak) -> Result
    
    // Inline elements
    func visitText(_ text: Text) -> Result
    func visitEmphasis(_ emphasis: Emphasis) -> Result
    func visitStrong(_ strong: Strong) -> Result
    func visitStrikethrough(_ strikethrough: Strikethrough) -> Result
    func visitInlineCode(_ inlineCode: InlineCode) -> Result
    func visitLink(_ link: Link) -> Result
    func visitImage(_ image: Image) -> Result
    func visitLineBreak(_ lineBreak: LineBreak) -> Result
    func visitSoftBreak(_ softBreak: SoftBreak) -> Result
    
    /// Default implementation for unhandled types
    func defaultVisit(_ markup: Markup) -> Result
}

/// Default visitor implementation
extension MarkupVisitor {
    public func visit(_ markup: Markup) -> Result {
        return markup.accept(self)
    }
    
    public func defaultVisit(_ markup: Markup) -> Result {
        // Default behavior - typically should be overridden
        fatalError("Visitor \(type(of: self)) does not implement visit method for \(type(of: markup))")
    }
}

/// Walker protocol for read-only traversal
public protocol MarkupWalker: MarkupVisitor where Result == Void {
    /// Continue traversal into children
    mutating func descendInto(_ markup: Markup)
}

extension MarkupWalker {
    /// Default traversal implementation
    public mutating func descendInto(_ markup: Markup) {
        for child in markup.children {
            visit(child)
        }
    }
    
    /// Default visit implementation calls descendInto
    public mutating func defaultVisit(_ markup: Markup) {
        descendInto(markup)
    }
}

/// Rewriter protocol for tree transformation
public protocol MarkupRewriter: MarkupVisitor where Result == Markup? {
    /// Transform markup element
    mutating func transform(_ markup: Markup) -> Markup?
}

extension MarkupRewriter {
    /// Default rewriting implementation
    public mutating func defaultVisit(_ markup: Markup) -> Markup? {
        // For the default implementation, just return the markup unchanged
        // Specific rewriters should override specific visit methods
        return markup
    }
} 