//
//  MarkdownText.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/11/25.
//

import SwiftUI
import Markdown

struct MarkdownText: View {
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            let document = Document(parsing: content)
            let blocks = document.children.compactMap { $0 as? BlockMarkup }
            ForEach(blocks.indices, id: \.self) { index in
                renderBlock(blocks[index])
            }
        }
    }
    
    @ViewBuilder
    private func renderBlock(_ block: BlockMarkup) -> some View {
        switch block {
        case let unorderedList as UnorderedList:
            renderUnorderedList(unorderedList)
        case let orderedList as OrderedList:
            renderOrderedList(orderedList)
        case let paragraph as Paragraph:
            renderParagraph(paragraph)
        case let codeBlock as CodeBlock:
            renderCodeBlock(codeBlock)
        default:
            // Fallback for all other content types
            Text(block.format())
                .font(AppFonts.messageBody)
                .foregroundColor(.primary)
        }
    }
    
    @ViewBuilder
    private func renderUnorderedList(_ list: UnorderedList) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            let items = list.children.compactMap { $0 as? ListItem }
            ForEach(items.indices, id: \.self) { index in
                renderListItem(items[index], bullet: "•")
            }
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private func renderOrderedList(_ list: OrderedList) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            let items = list.children.compactMap { $0 as? ListItem }
            ForEach(items.indices, id: \.self) { index in
                renderListItem(items[index], bullet: "\(index + 1).")
            }
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private func renderListItem(_ listItem: ListItem, bullet: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(bullet)
                .font(AppFonts.messageBody)
                .foregroundColor(.primary)
                .frame(minWidth: 20, alignment: .leading)

            let enumerated = Array(listItem.children.enumerated())
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(enumerated, id: \.0) { _, child in
                    if let paragraph = child as? Paragraph {
                        Text(buildAttributedString(from: paragraph.children.compactMap { $0 as? InlineMarkup }))
                            .font(AppFonts.messageBody)
                            .foregroundColor(.primary)
                    } else if let blockMarkup = child as? BlockMarkup {
                        renderBlock(blockMarkup)
                            .padding(.leading, 16)
                    } else {
                        Text(child.format())
                            .font(AppFonts.messageBody)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .padding(.leading, 8)
    }
    
    @ViewBuilder
    private func renderParagraph(_ paragraph: Paragraph) -> some View {
        Text(buildAttributedString(from: paragraph.children.compactMap { $0 as? InlineMarkup }))
            .font(AppFonts.messageBody)
            .foregroundColor(.primary)
    }
    
    @ViewBuilder
    private func renderCodeBlock(_ codeBlock: CodeBlock) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                if let language = codeBlock.language {
                    HStack {
                        Text(language)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                }
                
                Text(codeBlock.code)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.primary)
                    .textSelection(.enabled)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(AppColors.codeBlockBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppColors.codeBlockBorder, lineWidth: 1)
                )
        )
        .padding(.vertical, 4)
    }
    
    private func buildAttributedString(from inlines: [InlineMarkup]) -> AttributedString {
        var result = AttributedString()
        
        for inline in inlines {
            switch inline {
            case let text as Markdown.Text:
                result += AttributedString(text.string)
            case let strong as Strong:
                var boldText = AttributedString(strong.plainText)
                boldText.font = AppFonts.messageBody.bold()
                result += boldText
            case let emphasis as Emphasis:
                var italicText = AttributedString(emphasis.plainText)
                italicText.font = AppFonts.messageBody.italic()
                result += italicText
            default:
                result += AttributedString(inline.plainText)
            }
        }
        
        return result
    }
    
    private func extractTextFromParagraph(_ paragraph: Paragraph) -> String {
        return paragraph.children.compactMap { child in
            if let text = child as? Markdown.Text {
                return text.string
            } else {
                return child.format()
            }
        }.joined(separator: "")
    }
}

/*
// COMMENTED OUT - Complex implementation causing compilation issues
//
// @ViewBuilder
// private func renderHeading(_ heading: Heading) -> some View {
//     let fontSize: CGFloat = headingFontSize(for: heading.level)
//     
//     Text(heading.plainText)
//         .font(.system(size: fontSize, weight: .bold))
//         .foregroundColor(.primary)
//         .padding(.vertical, 4)
// }
// 
// @ViewBuilder
// private func renderParagraph(_ paragraph: Paragraph) -> some View {
//     renderInlineContent(paragraph.children.compactMap { $0 as? InlineMarkup })
//         .padding(.vertical, 2)
// }
// 
// @ViewBuilder
// private func renderCodeBlock(_ codeBlock: CodeBlock) -> some View {
//     ScrollView(.horizontal, showsIndicators: false) {
//         VStack(alignment: .leading, spacing: 0) {
//             if let language = codeBlock.language {
//                 HStack {
//                     Text(language)
//                         .font(.system(size: 12, weight: .medium))
//                         .foregroundColor(.secondary)
//                     Spacer()
//                 }
//                 .padding(.horizontal, 12)
//                 .padding(.top, 8)
//                 .padding(.bottom, 4)
//             }
//             
//             Text(codeBlock.code)
//                 .font(.system(.body, design: .monospaced))
//                 .foregroundColor(.primary)
//                 .textSelection(.enabled)
//                 .padding(.horizontal, 12)
//                 .padding(.bottom, 8)
//                 .frame(maxWidth: .infinity, alignment: .leading)
//         }
//     }
//     .background(
//         RoundedRectangle(cornerRadius: 8)
//             .fill(AppColors.codeBlockBackground)
//             .overlay(
//                 RoundedRectangle(cornerRadius: 8)
//                     .stroke(AppColors.codeBlockBorder, lineWidth: 1)
//             )
//     )
//     .padding(.vertical, 4)
// }
// 
// @ViewBuilder
// private func renderBlockQuote(_ blockQuote: BlockQuote) -> some View {
//     HStack(alignment: .top, spacing: 12) {
//         Rectangle()
//             .fill(AppColors.blockQuoteAccent)
//             .frame(width: 4)
//         
//         VStack(alignment: .leading, spacing: 4) {
//             let blocks = blockQuote.children.compactMap { $0 as? BlockMarkup }
//             ForEach(blocks.indices, id: \.self) { index in
//                 renderBlock(blocks[index])
//             }
//         }
//     }
//     .padding(.vertical, 4)
//     .background(
//         RoundedRectangle(cornerRadius: 8)
//             .fill(AppColors.blockQuoteBackground)
//     )
// }
// 
// @ViewBuilder
// private func renderInlineContent(_ inlines: [InlineMarkup]) -> some View {
//     Text(buildAttributedString(from: inlines))
//         .font(.system(size: 15, weight: .regular))
//         .foregroundColor(.primary)
//         .textSelection(.enabled)
// }
// 
// private func buildAttributedString(from inlines: [InlineMarkup]) -> AttributedString {
//     var result = AttributedString()
//     
//     for inline in inlines {
//         switch inline {
//         case let text as Markdown.Text:
//             result += AttributedString(text.string)
//         case let strong as Strong:
//             var boldText = AttributedString(strong.plainText)
//             boldText.font = .system(size: 15, weight: .bold)
//             result += boldText
//         case let emphasis as Emphasis:
//             var italicText = AttributedString(emphasis.plainText)
//             italicText.font = .system(size: 15).italic()
//             result += italicText
//         case let code as InlineCode:
//             var codeText = AttributedString(code.code)
//             codeText.font = .system(size: 14, design: .monospaced)
//             codeText.backgroundColor = AppColors.inlineCodeBackground
//             result += codeText
//         case let link as Markdown.Link:
//             var linkText = AttributedString(link.plainText)
//             linkText.foregroundColor = Color.blue
//             linkText.underlineStyle = Text.LineStyle.single
//             if let url = URL(string: link.destination ?? "") {
//                 linkText.link = url
//             }
//             result += linkText
//         default:
//             result += AttributedString(inline.plainText)
//         }
//     }
//     
//     return result
// }
// 
// private func headingFontSize(for level: Int) -> CGFloat {
//     switch level {
//     case 1: return 22
//     case 2: return 20
//     case 3: return 18
//     case 4: return 16
//     case 5: return 14
//     case 6: return 13
//     default: return 15
//     }
// }
*/
