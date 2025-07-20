//
//  TestExample.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/11/25.
//

import Foundation

/// Simple test to verify NovaMarkdown functionality
public func testNovaMarkdown() {
    print("🧪 Testing NovaMarkdown...")
    
    // Test basic parsing
    let markdownText = """
    # Hello World
    
    This is a **bold** and *italic* example with `inline code`.
    
    ## Code Block
    
    ```swift
    let greeting = "Hello, World!"
    print(greeting)
    ```
    
    ## Lists
    
    - Item 1
    - Item 2
    - Item 3
    
    1. First
    2. Second
    3. Third
    
    > This is a blockquote with **emphasis**.
    
    Check out [Swift](https://swift.org) for more info!
    """
    
    // Parse the markdown
    let document = Document(parsing: markdownText)
    
    print("✅ Document parsed successfully!")
    print("📊 Document contains \(document.blocks.count) blocks")
    
    // Examine the structure
    for (index, block) in document.blocks.enumerated() {
        print("  Block \(index): \(type(of: block))")
        
        if let paragraph = block as? Paragraph {
            print("    Paragraph with \(paragraph.inlines.count) inlines")
        } else if let heading = block as? Heading {
            print("    Heading level \(heading.level): '\(heading.plainText)'")
        } else if let codeBlock = block as? CodeBlock {
            print("    Code block (\(codeBlock.language ?? "no language")): \(codeBlock.code.count) characters")
        } else if let list = block as? UnorderedList {
            print("    Unordered list with \(list.items.count) items")
        } else if let list = block as? OrderedList {
            print("    Ordered list with \(list.items.count) items")
        } else if let quote = block as? BlockQuote {
            print("    Blockquote with \(quote.blocks.count) blocks")
        }
    }
    
    print("🎉 NovaMarkdown test completed successfully!")
} 