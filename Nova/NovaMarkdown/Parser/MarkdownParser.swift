//
//  MarkdownParser.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/11/25.
//

import Foundation

public class MarkdownParser {
    private let options: ParseOptions
    
    public init(options: ParseOptions = .chatDefault) {
        self.options = options
    }
    
    public func parse(_ text: String) -> Document {
        let document = Document()
        let lines = text.components(separatedBy: .newlines)
        
        var i = 0
        while i < lines.count {
            let line = lines[i]
            
            // Skip empty lines
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                i += 1
                continue
            }
            
            // Try to parse block elements
            if let (blockElement, consumed) = parseBlockElement(lines: lines, startIndex: i) {
                document.addChild(blockElement)
                i += consumed
            } else {
                // Fallback to paragraph
                let paragraph = parseParagraph(lines: lines, startIndex: i)
                document.addChild(paragraph.element)
                i += paragraph.consumed
            }
        }
        
        return document
    }
    
    // MARK: - Block Element Parsing
    
    private func parseBlockElement(lines: [String], startIndex: Int) -> (BlockMarkup, Int)? {
        let line = lines[startIndex]
        
        // Heading
        if let heading = parseHeading(line) {
            return (heading, 1)
        }
        
        // Code block
        if let codeBlock = parseCodeBlock(lines: lines, startIndex: startIndex) {
            return (codeBlock.element, codeBlock.consumed)
        }
        
        // Blockquote
        if let blockquote = parseBlockquote(lines: lines, startIndex: startIndex) {
            return (blockquote.element, blockquote.consumed)
        }
        
        // Lists
        if let list = parseList(lines: lines, startIndex: startIndex) {
            return (list.element, list.consumed)
        }
        
        // Thematic break
        if let thematicBreak = parseThematicBreak(line) {
            return (thematicBreak, 1)
        }
        
        return nil
    }
    
    private func parseHeading(_ line: String) -> Heading? {
        let pattern = #"^(#{1,6})\s+(.+)$"#
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: line.utf16.count)
        
        guard let match = regex.firstMatch(in: line, options: [], range: range) else {
            return nil
        }
        
        let levelRange = Range(match.range(at: 1), in: line)!
        let contentRange = Range(match.range(at: 2), in: line)!
        
        let level = String(line[levelRange]).count
        let content = String(line[contentRange])
        
        let inlines = parseInlineElements(content)
        return Heading(level: level, inlines: inlines)
    }
    
    private func parseCodeBlock(lines: [String], startIndex: Int) -> (element: CodeBlock, consumed: Int)? {
        let line = lines[startIndex]
        
        // Fenced code blocks
        let fencePattern = #"^```\s*(\w+)?\s*$"#
        let fenceRegex = try! NSRegularExpression(pattern: fencePattern)
        let range = NSRange(location: 0, length: line.utf16.count)
        
        guard let match = fenceRegex.firstMatch(in: line, options: [], range: range) else {
            return nil
        }
        
        let language: String?
        if match.range(at: 1).location != NSNotFound {
            let languageRange = Range(match.range(at: 1), in: line)!
            language = String(line[languageRange])
        } else {
            language = nil
        }
        
        var codeLines: [String] = []
        var consumed = 1
        
        for i in (startIndex + 1)..<lines.count {
            let codeLine = lines[i]
            if codeLine.trimmingCharacters(in: .whitespaces) == "```" {
                consumed += 1
                break
            }
            codeLines.append(codeLine)
            consumed += 1
        }
        
        let code = codeLines.joined(separator: "\n")
        return (CodeBlock(language: language, code: code), consumed)
    }
    
    private func parseBlockquote(lines: [String], startIndex: Int) -> (element: BlockQuote, consumed: Int)? {
        let line = lines[startIndex]
        
        guard line.hasPrefix("> ") else {
            return nil
        }
        
        var quoteLines: [String] = []
        var consumed = 0
        
        for i in startIndex..<lines.count {
            let quoteLine = lines[i]
            if quoteLine.hasPrefix("> ") {
                let content = String(quoteLine.dropFirst(2))
                quoteLines.append(content)
                consumed += 1
            } else if quoteLine.trimmingCharacters(in: .whitespaces).isEmpty {
                consumed += 1
            } else {
                break
            }
        }
        
        let quoteText = quoteLines.joined(separator: "\n")
        let quoteParser = MarkdownParser(options: options)
        let quoteDocument = quoteParser.parse(quoteText)
        
        let blockquote = BlockQuote(blocks: quoteDocument.blocks)
        return (blockquote, consumed)
    }
    
    private func parseList(lines: [String], startIndex: Int) -> (element: BlockMarkup, consumed: Int)? {
        let line = lines[startIndex]
        
        // Unordered list
        let unorderedPattern = #"^(\s*)([-*+])\s+(.+)$"#
        let unorderedRegex = try! NSRegularExpression(pattern: unorderedPattern)
        let range = NSRange(location: 0, length: line.utf16.count)
        
        if let match = unorderedRegex.firstMatch(in: line, options: [], range: range) {
            return parseUnorderedList(lines: lines, startIndex: startIndex)
        }
        
        // Ordered list
        let orderedPattern = #"^(\s*)(\d+)\.\s+(.+)$"#
        let orderedRegex = try! NSRegularExpression(pattern: orderedPattern)
        
        if let match = orderedRegex.firstMatch(in: line, options: [], range: range) {
            return parseOrderedList(lines: lines, startIndex: startIndex)
        }
        
        return nil
    }
    
    private func parseUnorderedList(lines: [String], startIndex: Int) -> (element: UnorderedList, consumed: Int)? {
        var items: [ListItem] = []
        var consumed = 0
        
        for i in startIndex..<lines.count {
            let line = lines[i]
            
            let pattern = #"^(\s*)([-*+])\s+(.+)$"#
            let regex = try! NSRegularExpression(pattern: pattern)
            let range = NSRange(location: 0, length: line.utf16.count)
            
            guard let match = regex.firstMatch(in: line, options: [], range: range) else {
                break
            }
            
            let contentRange = Range(match.range(at: 3), in: line)!
            let content = String(line[contentRange])
            
            // Check for task list
            var checkbox: ListItem.Checkbox?
            let taskPattern = #"^\[([x\s])\]\s+(.+)$"#
            let taskRegex = try! NSRegularExpression(pattern: taskPattern)
            let taskRange = NSRange(location: 0, length: content.utf16.count)
            
            let finalContent: String
            if let taskMatch = taskRegex.firstMatch(in: content, options: [], range: taskRange) {
                let checkboxRange = Range(taskMatch.range(at: 1), in: content)!
                let taskContentRange = Range(taskMatch.range(at: 2), in: content)!
                
                checkbox = String(content[checkboxRange]) == "x" ? .checked : .unchecked
                finalContent = String(content[taskContentRange])
            } else {
                finalContent = content
            }
            
            let paragraph = Paragraph(inlines: parseInlineElements(finalContent))
            let listItem = ListItem(checkbox: checkbox, blocks: [paragraph])
            items.append(listItem)
            consumed += 1
        }
        
        return (UnorderedList(items: items), consumed)
    }
    
    private func parseOrderedList(lines: [String], startIndex: Int) -> (element: OrderedList, consumed: Int)? {
        var items: [ListItem] = []
        var consumed = 0
        var startingNumber = 1
        
        for i in startIndex..<lines.count {
            let line = lines[i]
            
            let pattern = #"^(\s*)(\d+)\.\s+(.+)$"#
            let regex = try! NSRegularExpression(pattern: pattern)
            let range = NSRange(location: 0, length: line.utf16.count)
            
            guard let match = regex.firstMatch(in: line, options: [], range: range) else {
                break
            }
            
            let numberRange = Range(match.range(at: 2), in: line)!
            let contentRange = Range(match.range(at: 3), in: line)!
            
            if i == startIndex {
                startingNumber = Int(String(line[numberRange])) ?? 1
            }
            
            let content = String(line[contentRange])
            let paragraph = Paragraph(inlines: parseInlineElements(content))
            let listItem = ListItem(blocks: [paragraph])
            items.append(listItem)
            consumed += 1
        }
        
        return (OrderedList(startingNumber: startingNumber, items: items), consumed)
    }
    
    private func parseThematicBreak(_ line: String) -> ThematicBreak? {
        let pattern = #"^(\s*)([-*_])\s*\2\s*\2[\s\2]*$"#
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: line.utf16.count)
        
        if regex.firstMatch(in: line, options: [], range: range) != nil {
            return ThematicBreak()
        }
        
        return nil
    }
    
    private func parseParagraph(lines: [String], startIndex: Int) -> (element: Paragraph, consumed: Int) {
        var paragraphLines: [String] = []
        var consumed = 0
        
        for i in startIndex..<lines.count {
            let line = lines[i]
            
            // Stop at empty line or start of another block element
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                break
            }
            
            if parseBlockElement(lines: lines, startIndex: i) != nil {
                break
            }
            
            paragraphLines.append(line)
            consumed += 1
        }
        
        let text = paragraphLines.joined(separator: " ")
        let inlines = parseInlineElements(text)
        return (Paragraph(inlines: inlines), consumed)
    }
    
    // MARK: - Inline Element Parsing
    
    private func parseInlineElements(_ text: String) -> [InlineMarkup] {
        var result: [InlineMarkup] = []
        var currentIndex = text.startIndex
        
        while currentIndex < text.endIndex {
            if let (element, endIndex) = parseNextInlineElement(text: text, startIndex: currentIndex) {
                result.append(element)
                currentIndex = endIndex
            } else {
                // If no inline element found, consume one character as text
                let nextIndex = text.index(after: currentIndex)
                let textContent = String(text[currentIndex..<nextIndex])
                result.append(Text(textContent))
                currentIndex = nextIndex
            }
        }
        
        return result
    }
    
    private func parseNextInlineElement(text: String, startIndex: String.Index) -> (InlineMarkup, String.Index)? {
        let substring = text[startIndex...]
        
        // Strong (bold) - **text** or __text__
        if let strongMatch = parseStrong(substring) {
            let endIndex = text.index(startIndex, offsetBy: strongMatch.length)
            return (strongMatch.element, endIndex)
        }
        
        // Emphasis (italic) - *text* or _text_
        if let emphasisMatch = parseEmphasis(substring) {
            let endIndex = text.index(startIndex, offsetBy: emphasisMatch.length)
            return (emphasisMatch.element, endIndex)
        }
        
        // Strikethrough - ~~text~~
        if options.contains(.parseStrikethrough), let strikethroughMatch = parseStrikethrough(substring) {
            let endIndex = text.index(startIndex, offsetBy: strikethroughMatch.length)
            return (strikethroughMatch.element, endIndex)
        }
        
        // Inline code - `code`
        if let codeMatch = parseInlineCode(substring) {
            let endIndex = text.index(startIndex, offsetBy: codeMatch.length)
            return (codeMatch.element, endIndex)
        }
        
        // Link - [text](url)
        if let linkMatch = parseLink(substring) {
            let endIndex = text.index(startIndex, offsetBy: linkMatch.length)
            return (linkMatch.element, endIndex)
        }
        
        // Image - ![alt](url)
        if let imageMatch = parseImage(substring) {
            let endIndex = text.index(startIndex, offsetBy: imageMatch.length)
            return (imageMatch.element, endIndex)
        }
        
        // Autolink - http://example.com
        if options.contains(.parseAutolinks), let autolinkMatch = parseAutolink(substring) {
            let endIndex = text.index(startIndex, offsetBy: autolinkMatch.length)
            return (autolinkMatch.element, endIndex)
        }
        
        return nil
    }
    
    private func parseStrong(_ text: Substring) -> (element: Strong, length: Int)? {
        // **text** pattern
        let pattern = #"^\*\*((?:[^*]|\*(?!\*))+)\*\*"#
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: text.utf16.count)
        
        if let match = regex.firstMatch(in: String(text), options: [], range: range) {
            let contentRange = Range(match.range(at: 1), in: String(text))!
            let content = String(String(text)[contentRange])
            let inlines = parseInlineElements(content)
            return (Strong(inlines: inlines), match.range.length)
        }
        
        // __text__ pattern
        let underscorePattern = #"^__((?:[^_]|_(?!_))+)__"#
        let underscoreRegex = try! NSRegularExpression(pattern: underscorePattern)
        
        if let match = underscoreRegex.firstMatch(in: String(text), options: [], range: range) {
            let contentRange = Range(match.range(at: 1), in: String(text))!
            let content = String(String(text)[contentRange])
            let inlines = parseInlineElements(content)
            return (Strong(inlines: inlines), match.range.length)
        }
        
        return nil
    }
    
    private func parseEmphasis(_ text: Substring) -> (element: Emphasis, length: Int)? {
        // *text* pattern (but not **)
        let pattern = #"^\*([^*]+)\*"#
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: text.utf16.count)
        
        if let match = regex.firstMatch(in: String(text), options: [], range: range) {
            let contentRange = Range(match.range(at: 1), in: String(text))!
            let content = String(String(text)[contentRange])
            let inlines = parseInlineElements(content)
            return (Emphasis(inlines: inlines), match.range.length)
        }
        
        // _text_ pattern (but not __)
        let underscorePattern = #"^_([^_]+)_"#
        let underscoreRegex = try! NSRegularExpression(pattern: underscorePattern)
        
        if let match = underscoreRegex.firstMatch(in: String(text), options: [], range: range) {
            let contentRange = Range(match.range(at: 1), in: String(text))!
            let content = String(String(text)[contentRange])
            let inlines = parseInlineElements(content)
            return (Emphasis(inlines: inlines), match.range.length)
        }
        
        return nil
    }
    
    private func parseStrikethrough(_ text: Substring) -> (element: Strikethrough, length: Int)? {
        let pattern = #"^~~([^~]+)~~"#
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: text.utf16.count)
        
        if let match = regex.firstMatch(in: String(text), options: [], range: range) {
            let contentRange = Range(match.range(at: 1), in: String(text))!
            let content = String(String(text)[contentRange])
            let inlines = parseInlineElements(content)
            return (Strikethrough(inlines: inlines), match.range.length)
        }
        
        return nil
    }
    
    private func parseInlineCode(_ text: Substring) -> (element: InlineCode, length: Int)? {
        let pattern = #"^`([^`]+)`"#
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: text.utf16.count)
        
        if let match = regex.firstMatch(in: String(text), options: [], range: range) {
            let contentRange = Range(match.range(at: 1), in: String(text))!
            let content = String(String(text)[contentRange])
            return (InlineCode(content), match.range.length)
        }
        
        return nil
    }
    
    private func parseLink(_ text: Substring) -> (element: Link, length: Int)? {
        let pattern = #"^\[([^\]]+)\]\(([^)]+)\)"#
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: text.utf16.count)
        
        if let match = regex.firstMatch(in: String(text), options: [], range: range) {
            let textRange = Range(match.range(at: 1), in: String(text))!
            let urlRange = Range(match.range(at: 2), in: String(text))!
            
            let linkText = String(String(text)[textRange])
            let url = String(String(text)[urlRange])
            
            let inlines = parseInlineElements(linkText)
            return (Link(destination: url, inlines: inlines), match.range.length)
        }
        
        return nil
    }
    
    private func parseImage(_ text: Substring) -> (element: Image, length: Int)? {
        let pattern = #"^!\[([^\]]*)\]\(([^)]+)\)"#
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: text.utf16.count)
        
        if let match = regex.firstMatch(in: String(text), options: [], range: range) {
            let altRange = Range(match.range(at: 1), in: String(text))!
            let urlRange = Range(match.range(at: 2), in: String(text))!
            
            let altText = String(String(text)[altRange])
            let url = String(String(text)[urlRange])
            
            let inlines = parseInlineElements(altText)
            return (Image(source: url, altText: inlines), match.range.length)
        }
        
        return nil
    }
    
    private func parseAutolink(_ text: Substring) -> (element: Link, length: Int)? {
        let pattern = #"^(https?://[^\s]+)"#
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: text.utf16.count)
        
        if let match = regex.firstMatch(in: String(text), options: [], range: range) {
            let urlRange = Range(match.range, in: String(text))!
            let url = String(String(text)[urlRange])
            
            let linkText = Text(url)
            return (Link(destination: url, inlines: [linkText]), match.range.length)
        }
        
        return nil
    }
} 