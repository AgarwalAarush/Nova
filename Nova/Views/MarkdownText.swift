//
//  MarkdownText.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/11/25.
//

import SwiftUI

/// SwiftUI view for rendering markdown text using the NovaMarkdown module
struct MarkdownText: View {
    let content: String
    
    var body: some View {
        NovaMarkdownView.withAppFonts(content)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#if DEBUG
struct MarkdownText_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                MarkdownText(content: """
                # Welcome to Nova!
                
                This is a **markdown** rendering example with *italic* text and `inline code`.
                
                ## Code Block
                
                ```swift
                func greet() {
                    print("Hello, World!")
                }
                ```
                
                ## Lists
                
                ### Unordered List
                - First item
                - Second item with **bold** text
                - Third item with *italic* text
                
                ### Ordered List
                1. First numbered item
                2. Second numbered item
                3. Third numbered item
                
                ### Task List
                - [x] Completed task
                - [ ] Pending task
                - [x] Another completed task
                
                ## Blockquote
                
                > This is a blockquote with some interesting content.
                > It can span multiple lines and contain **formatting**.
                
                ## Links
                
                Check out [OpenAI](https://openai.com) for more information.
                
                ## Thematic Break
                
                ---
                
                That's all for now!
                """)
                .padding()
            }
        }
        .background(Color.black)
        .previewDisplayName("Nova Markdown")
    }
}
#endif
