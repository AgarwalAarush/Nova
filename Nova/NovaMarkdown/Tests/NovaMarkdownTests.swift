//
//  NovaMarkdownTests.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/11/25.
//

import Foundation

/// Test suite for NovaMarkdown functionality
public struct NovaMarkdownTests {
    
    /// Run basic functionality tests
    public static func runBasicTests() {
        print("🧪 Running NovaMarkdown Tests...")
        
        testBasicParsing()
        testInlineElements()
        testBlockElements()
        testCodeBlocks()
        testLists()
        
        print("✅ All tests completed!")
    }
    
    private static func testBasicParsing() {
        print("Testing basic parsing...")
        
        let markdown = "Hello **world**!"
        let document = Document(parsing: markdown)
        
        assert(document.blocks.count == 1, "Should have one block")
        assert(document.blocks[0] is Paragraph, "First block should be paragraph")
        
        let paragraph = document.blocks[0] as! Paragraph
        assert(paragraph.inlines.count == 3, "Should have 3 inline elements")
        assert(paragraph.inlines[0] is Text, "First inline should be text")
        assert(paragraph.inlines[1] is Strong, "Second inline should be strong")
        assert(paragraph.inlines[2] is Text, "Third inline should be text")
        
        print("✅ Basic parsing test passed")
    }
    
    private static func testInlineElements() {
        print("Testing inline elements...")
        
        let markdown = "This is *italic* and **bold** and `code`"
        let document = Document(parsing: markdown)
        
        let paragraph = document.blocks[0] as! Paragraph
        assert(paragraph.inlines.count >= 5, "Should have multiple inline elements")
        
        var hasEmphasis = false
        var hasStrong = false
        var hasCode = false
        
        for inline in paragraph.inlines {
            if inline is Emphasis { hasEmphasis = true }
            if inline is Strong { hasStrong = true }
            if inline is InlineCode { hasCode = true }
        }
        
        assert(hasEmphasis, "Should have emphasis")
        assert(hasStrong, "Should have strong")
        assert(hasCode, "Should have inline code")
        
        print("✅ Inline elements test passed")
    }
    
    private static func testBlockElements() {
        print("Testing block elements...")
        
        let markdown = """
        # Heading 1
        
        This is a paragraph.
        
        ## Heading 2
        
        > This is a blockquote
        """
        
        let document = Document(parsing: markdown)
        
        assert(document.blocks.count >= 3, "Should have multiple blocks")
        
        var hasHeading = false
        var hasParagraph = false
        var hasBlockquote = false
        
        for block in document.blocks {
            if block is Heading { hasHeading = true }
            if block is Paragraph { hasParagraph = true }
            if block is BlockQuote { hasBlockquote = true }
        }
        
        assert(hasHeading, "Should have heading")
        assert(hasParagraph, "Should have paragraph")
        assert(hasBlockquote, "Should have blockquote")
        
        print("✅ Block elements test passed")
    }
    
    private static func testCodeBlocks() {
        print("Testing code blocks...")
        
        let markdown = """
        ```swift
        let x = 42
        print(x)
        ```
        """
        
        let document = Document(parsing: markdown)
        
        assert(document.blocks.count == 1, "Should have one block")
        assert(document.blocks[0] is CodeBlock, "Should be code block")
        
        let codeBlock = document.blocks[0] as! CodeBlock
        assert(codeBlock.language == "swift", "Should have swift language")
        assert(codeBlock.code.contains("let x = 42"), "Should contain code content")
        
        print("✅ Code blocks test passed")
    }
    
    private static func testLists() {
        print("Testing lists...")
        
        let markdown = """
        - Item 1
        - Item 2
        - Item 3
        
        1. First
        2. Second
        3. Third
        """
        
        let document = Document(parsing: markdown)
        
        assert(document.blocks.count >= 2, "Should have multiple blocks")
        
        var hasUnorderedList = false
        var hasOrderedList = false
        
        for block in document.blocks {
            if block is UnorderedList { hasUnorderedList = true }
            if block is OrderedList { hasOrderedList = true }
        }
        
        assert(hasUnorderedList, "Should have unordered list")
        assert(hasOrderedList, "Should have ordered list")
        
        print("✅ Lists test passed")
    }
}

// MARK: - Test Runner

#if DEBUG
extension NovaMarkdownTests {
    /// Quick test for debugging
    public static func quickTest() {
        let markdown = "Hello **world** with `code`!"
        let document = Document(parsing: markdown)
        
        print("Document has \(document.blocks.count) blocks")
        if let paragraph = document.blocks.first as? Paragraph {
            print("First paragraph has \(paragraph.inlines.count) inlines")
            for (index, inline) in paragraph.inlines.enumerated() {
                print("  \(index): \(type(of: inline)) - '\(inline.plainText)'")
            }
        }
    }
}
#endif 