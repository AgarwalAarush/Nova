//
//  GrowingTextView.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/11/25.
//

import SwiftUI
import AppKit

struct GrowingTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var height: CGFloat
    let onSend: () -> Void

    private let minHeight: CGFloat = 22
    private let maxHeight: CGFloat = 22 * 8

    func makeNSView(context: Context) -> NSScrollView {
        // Wrapper scroll view – required so the NSTextView reliably becomes first‑responder
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        // Actual editable text view
        let textView = NSTextView()
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.usesFindPanel = false
        textView.usesInspectorBar = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false

        // Ensure the text view expands horizontally with its scroll view so text is visible
        textView.minSize = NSSize(width: 0, height: minHeight)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.autoresizingMask = [.width]
        textView.font = .systemFont(ofSize: 15)
        textView.drawsBackground = false
        textView.textColor = NSColor(AppColors.primaryText)
        textView.backgroundColor = .clear
        textView.insertionPointColor = NSColor(AppColors.primaryText)

        // Text‑container configuration
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = CGSize(width: 0,
                                                       height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainerInset = NSSize(width: 0, height: 0)

        // Disable automatic substitutions for plain input
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isAutomaticDataDetectionEnabled = false

        // Set typing attributes to ensure typed text has correct appearance
        let typingAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 15),
            .foregroundColor: NSColor(AppColors.primaryText)
        ]
        textView.typingAttributes = typingAttributes

        // Delegate & focus notifications
        textView.delegate = context.coordinator

        // Text-change notifications
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.textDidChange(_:)),
            name: NSText.didChangeNotification,
            object: textView
        )

        // Embed text view inside scroll view
        scrollView.documentView = textView
        context.coordinator.textView = textView

        // Make the text view the first responder when it appears
        DispatchQueue.main.async {
            textView.window?.makeFirstResponder(textView)
        }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        if textView.string != text {
            // Store the current selection to restore it after updating
            let selectedRange = textView.selectedRange()
            
            // Create attributed string with proper attributes
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 15),
                .foregroundColor: NSColor(AppColors.primaryText)
            ]
            
            let attributedString = NSAttributedString(string: text, attributes: attributes)
            
            // Use replaceCharacters to maintain undo/redo and proper text view behavior
            let fullRange = NSRange(location: 0, length: textView.string.count)
            if textView.shouldChangeText(in: fullRange, replacementString: text) {
                textView.textStorage?.replaceCharacters(in: fullRange, with: attributedString)
                textView.didChangeText()
                
                // Restore selection, ensuring it's within bounds
                let newSelection = NSRange(
                    location: min(selectedRange.location, text.count),
                    length: min(selectedRange.length, text.count - min(selectedRange.location, text.count))
                )
                textView.setSelectedRange(newSelection)
            }
        }

        calculateHeight(for: textView)
    }

    private func calculateHeight(for textView: NSTextView) {
        guard
            let layoutManager = textView.layoutManager,
            let textContainer = textView.textContainer
        else { return }

        layoutManager.ensureLayout(for: textContainer)
        let usedRect = layoutManager.usedRect(for: textContainer)

        // unwrap font
        let font = textView.font ?? .systemFont(ofSize: 15)
        // call the instance method on layoutManager, not as a static
        let lineHeight = layoutManager.defaultLineHeight(for: font)
        let newHeight = min(max(usedRect.height, lineHeight), maxHeight)

        DispatchQueue.main.async {
            if abs(self.height - newHeight) > 1 {
                self.height = newHeight
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text,
                    height: $height,
                    onSend: onSend,
                    owner: self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        private let text: Binding<String>
        private let height: Binding<CGFloat>
        private let onSend: () -> Void
        private let owner: GrowingTextView
        weak var textView: NSTextView?

        init(text: Binding<String>,
             height: Binding<CGFloat>,
             onSend: @escaping () -> Void,
             owner: GrowingTextView)
        {
            self.text = text
            self.height = height
            self.onSend = onSend
            self.owner = owner
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }

        @objc func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text.wrappedValue = textView.string
            owner.calculateHeight(for: textView)
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                if !NSEvent.modifierFlags.contains(.shift) {
                    onSend()
                    return true
                } else {
                    // Allow newline with Shift+Enter
                    textView.insertNewline(nil)
                    return true
                }
            }
            return false
        }
    }
}
