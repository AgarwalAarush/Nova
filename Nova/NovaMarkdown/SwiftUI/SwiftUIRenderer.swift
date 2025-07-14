//
//  SwiftUIRenderer.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/11/25.
//

import SwiftUI

/// SwiftUI renderer that converts markdown AST to SwiftUI views
public struct SwiftUIRenderer: MarkupVisitor {
    public typealias Result = AnyView
    
    private let configuration: RenderConfiguration
    
    public init(configuration: RenderConfiguration = .default) {
        self.configuration = configuration
    }
    
    // MARK: - Block Elements
    
    public func visitDocument(_ document: Document) -> AnyView {
        let blocks = document.blocks
        
        return AnyView(
            VStack(alignment: .leading, spacing: configuration.blockSpacing) {
                ForEach(blocks.indices, id: \.self) { index in
                    visit(blocks[index])
                }
            }
        )
    }
    
    public func visitParagraph(_ paragraph: Paragraph) -> AnyView {
        let inlines = paragraph.inlines
        
        return AnyView(
            SwiftUI.Text(buildAttributedString(from: inlines))
                .font(configuration.bodyFont)
                .foregroundColor(configuration.textColor)
                .padding(.vertical, configuration.paragraphSpacing)
        )
    }
    
    public func visitHeading(_ heading: Heading) -> AnyView {
        let inlines = heading.inlines
        let font = configuration.headingFont(heading.level)
        
        return AnyView(
            SwiftUI.Text(buildAttributedString(from: inlines))
                .font(font)
                .bold()
                .foregroundColor(configuration.textColor)
                .padding(.vertical, configuration.headingSpacing)
        )
    }
    
    public func visitCodeBlock(_ codeBlock: CodeBlock) -> AnyView {
        return AnyView(
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    if let language = codeBlock.language {
                        HStack {
                            SwiftUI.Text(language)
                                .font(configuration.codeLanguageFont)
                                .foregroundColor(configuration.secondaryTextColor)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                    }
                    
                    SwiftUI.Text(codeBlock.code)
                        .font(configuration.codeFont)
                        .foregroundColor(configuration.textColor)
                        .textSelection(.enabled)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(configuration.codeBlockBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(configuration.codeBlockBorder, lineWidth: 1)
                    )
            )
            .padding(.vertical, configuration.codeBlockSpacing)
        )
    }
    
    public func visitBlockQuote(_ blockQuote: BlockQuote) -> AnyView {
        let blocks = blockQuote.blocks
        
        return AnyView(
            HStack(alignment: .top, spacing: 12) {
                Rectangle()
                    .fill(configuration.blockQuoteAccent)
                    .frame(width: 4)
                
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(blocks.indices, id: \.self) { index in
                        visit(blocks[index])
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(configuration.blockQuoteBackground)
            )
            .padding(.vertical, configuration.blockQuoteSpacing)
        )
    }
    
    public func visitUnorderedList(_ unorderedList: UnorderedList) -> AnyView {
        let items = unorderedList.items
        
        return AnyView(
            VStack(alignment: .leading, spacing: 4) {
                ForEach(items.indices, id: \.self) { index in
                    visitListItem(items[index], bullet: "•")
                }
            }
            .padding(.vertical, configuration.listSpacing)
        )
    }
    
    public func visitOrderedList(_ orderedList: OrderedList) -> AnyView {
        let items = orderedList.items
        
        return AnyView(
            VStack(alignment: .leading, spacing: 4) {
                ForEach(items.indices, id: \.self) { index in
                    let number = orderedList.startingNumber + index
                    visitListItem(items[index], bullet: "\(number).")
                }
            }
            .padding(.vertical, configuration.listSpacing)
        )
    }
    
    public func visitListItem(_ listItem: ListItem) -> AnyView {
        return visitListItem(listItem, bullet: "•")
    }
    
    private func visitListItem(_ listItem: ListItem, bullet: String) -> AnyView {
        let effectiveBullet: String
        
        if let checkbox = listItem.checkbox {
            effectiveBullet = checkbox == .checked ? "☑" : "☐"
        } else {
            effectiveBullet = bullet
        }
        
        return AnyView(
            HStack(alignment: .top, spacing: 12) {
                SwiftUI.Text(effectiveBullet)
                    .font(configuration.bodyFont)
                    .foregroundColor(configuration.textColor)
                    .frame(minWidth: 20, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(listItem.blocks.indices, id: \.self) { index in
                        visit(listItem.blocks[index])
                    }
                }
            }
            .padding(.leading, 8)
        )
    }
    
    public func visitTable(_ table: Table) -> AnyView {
        let rows = table.rows
        
        return AnyView(
            VStack(alignment: .leading, spacing: 0) {
                ForEach(rows.indices, id: \.self) { index in
                    visit(rows[index])
                    if index < rows.count - 1 {
                        Divider()
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(configuration.tableBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(configuration.tableBorder, lineWidth: 1)
                    )
            )
            .padding(.vertical, configuration.tableSpacing)
        )
    }
    
    public func visitTableRow(_ tableRow: TableRow) -> AnyView {
        let cells = tableRow.cells
        
        return AnyView(
            HStack(alignment: .top, spacing: 0) {
                ForEach(cells.indices, id: \.self) { index in
                    visit(cells[index])
                    if index < cells.count - 1 {
                        Divider()
                    }
                }
            }
            .padding(.vertical, 8)
        )
    }
    
    public func visitTableCell(_ tableCell: TableCell) -> AnyView {
        let inlines = tableCell.inlines
        let alignment: HorizontalAlignment
        
        switch tableCell.alignment {
        case .left:
            alignment = .leading
        case .center:
            alignment = .center
        case .right:
            alignment = .trailing
        }
        
        return AnyView(
            VStack(alignment: alignment, spacing: 0) {
                SwiftUI.Text(buildAttributedString(from: inlines))
                    .font(configuration.bodyFont)
                    .foregroundColor(configuration.textColor)
                    .multilineTextAlignment(textAlignment(for: tableCell.alignment))
            }
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, alignment: .init(horizontal: alignment, vertical: .center))
        )
    }
    
    public func visitThematicBreak(_ thematicBreak: ThematicBreak) -> AnyView {
        return AnyView(
            Rectangle()
                .fill(configuration.thematicBreakColor)
                .frame(height: 1)
                .padding(.vertical, configuration.thematicBreakSpacing)
        )
    }
    
    // MARK: - Inline Elements (handled via AttributedString)
    
    public func visitText(_ text: Text) -> AnyView {
        return AnyView(SwiftUI.Text(text.content))
    }
    
    public func visitEmphasis(_ emphasis: Emphasis) -> AnyView {
        let inlines = emphasis.inlines
        return AnyView(SwiftUI.Text(buildAttributedString(from: inlines)))
    }
    
    public func visitStrong(_ strong: Strong) -> AnyView {
        let inlines = strong.inlines
        return AnyView(SwiftUI.Text(buildAttributedString(from: inlines)))
    }
    
    public func visitStrikethrough(_ strikethrough: Strikethrough) -> AnyView {
        let inlines = strikethrough.inlines
        return AnyView(SwiftUI.Text(buildAttributedString(from: inlines)))
    }
    
    public func visitInlineCode(_ inlineCode: InlineCode) -> AnyView {
        return AnyView(SwiftUI.Text(inlineCode.code))
    }
    
    public func visitLink(_ link: Link) -> AnyView {
        let inlines = link.inlines
        return AnyView(SwiftUI.Text(buildAttributedString(from: inlines)))
    }
    
    public func visitImage(_ image: Image) -> AnyView {
        return AnyView(
            AsyncImage(url: URL(string: image.source)) { imagePhase in
                switch imagePhase {
                case .empty:
                    ProgressView()
                        .frame(width: 100, height: 100)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 300, maxHeight: 200)
                case .failure(_):
                    SwiftUI.Image(systemName: "photo")
                        .foregroundColor(.gray)
                        .frame(width: 100, height: 100)
                @unknown default:
                    EmptyView()
                }
            }
            .padding(.vertical, 4)
        )
    }
    
    public func visitLineBreak(_ lineBreak: LineBreak) -> AnyView {
        return AnyView(SwiftUI.Text("\n"))
    }
    
    public func visitSoftBreak(_ softBreak: SoftBreak) -> AnyView {
        return AnyView(SwiftUI.Text(" "))
    }
    
    public func defaultVisit(_ markup: Markup) -> AnyView {
        return AnyView(SwiftUI.Text(markup.plainText))
    }
    
    // MARK: - Helper Methods
    
    private func buildAttributedString(from inlines: [InlineMarkup]) -> AttributedString {
        var result = AttributedString()
        
        for inline in inlines {
            if let text = inline as? Text {
                result += AttributedString(text.content)
            } else if let strong = inline as? Strong {
                var boldText = AttributedString(strong.plainText)
                boldText.font = configuration.bodyFont.bold()
                result += boldText
            } else if let emphasis = inline as? Emphasis {
                var italicText = AttributedString(emphasis.plainText)
                italicText.font = configuration.bodyFont.italic()
                result += italicText
            } else if let strikethrough = inline as? Strikethrough {
                var strikethroughText = AttributedString(strikethrough.plainText)
                strikethroughText.strikethroughStyle = .single
                result += strikethroughText
            } else if let inlineCode = inline as? InlineCode {
                var codeText = AttributedString(inlineCode.code)
                codeText.font = configuration.inlineCodeFont
                codeText.backgroundColor = configuration.inlineCodeBackground
                result += codeText
            } else if let link = inline as? Link {
                var linkText = AttributedString(link.plainText)
                linkText.foregroundColor = configuration.linkColor
                linkText.underlineStyle = .single
                if let url = URL(string: link.destination) {
                    linkText.link = url
                }
                result += linkText
            } else if let image = inline as? Image {
                // Images are handled separately in visitImage
                result += AttributedString("[Image: \(image.plainText)]")
            } else {
                result += AttributedString(inline.plainText)
            }
        }
        
        return result
    }
    
    private func textAlignment(for alignment: TableCell.Alignment) -> TextAlignment {
        switch alignment {
        case .left:
            return .leading
        case .center:
            return .center
        case .right:
            return .trailing
        }
    }
} 