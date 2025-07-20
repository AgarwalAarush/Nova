//
//  GrowingTextView.swift
//  Nova
//
//  Created by Aarush Agarwal on 7/11/25.
//

import SwiftUI
import AppKit

public struct GrowingTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var height: CGFloat
    @Binding var isPlaceholderVisible: Bool
    let onSend: () -> Void
    
    public init(text: Binding<String>, height: Binding<CGFloat>, isPlaceholderVisible: Binding<Bool>, onSend: @escaping () -> Void) {
        self._text = text
        self._height = height
        self._isPlaceholderVisible = isPlaceholderVisible
        self.onSend = onSend
    }

    private var font: NSFont {
        NSFont(name: "Open Sans", size: 14) ?? NSFont.systemFont(ofSize: 14)
    }
    private let buffer: CGFloat = 4
    
    // Public static property for initial height
    public static var initialHeight: CGFloat {
        singleLineHeight + 4 // singleLineHeight + buffer
    }

    // Static constant for consistent height calculations
    static let singleLineHeight: CGFloat = 17.0 // Approximate height for 14pt Open Sans font
    
    private var singleLineHeight: CGFloat {
        GrowingTextView.singleLineHeight
    }

    private var insetHeight: CGFloat {
        buffer / 2
    }

    private var minHeight: CGFloat {
        singleLineHeight + buffer
    }
    private var maxHeight: CGFloat {
        minHeight * 8
    }

    public func makeNSView(context: Context) -> NSScrollView {
        // Wrapper scroll view – required so the NSTextView reliably becomes first‑responder
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = false

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
        textView.font = font
        textView.drawsBackground = false
        textView.textColor = NSColor(AppColors.primaryText)
        textView.backgroundColor = .clear
        textView.insertionPointColor = NSColor(AppColors.primaryText)

        // Text‑container configuration
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = CGSize(width: 300, // Start with reasonable width instead of 0
                                                       height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainerInset = NSSize(width: 0, height: 0) // Align with model selector button

        // Disable automatic substitutions for plain input
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isAutomaticDataDetectionEnabled = false

        // Set typing attributes to ensure typed text has correct appearance
        let typingAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
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
        
        // Set initial height immediately
        calculateHeight(for: textView)

        // Make the text view the first responder when it appears
        DispatchQueue.main.async {
            textView.window?.makeFirstResponder(textView)
            // Ensure initial height is calculated
            self.calculateHeight(for: textView)
        }

        return scrollView
    }

    public func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        if textView.string != text {
            // Store the current selection to restore it after updating
            let selectedRange = textView.selectedRange()
            
            // Create attributed string with proper attributes
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
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
        var newHeight: CGFloat
        
        // For empty text, always use minHeight
        if textView.string.isEmpty {
            newHeight = minHeight
            Task { @MainActor in
                if abs(self.height - newHeight) > 0.1 {
                    self.height = newHeight
                }
            }
            return
        }
        
        guard
            let layoutManager = textView.layoutManager,
            let textContainer = textView.textContainer
        else {
            newHeight = minHeight
            Task { @MainActor in
                if abs(self.height - newHeight) > 0.1 {
                    self.height = newHeight
                }
            }
            return
        }
        
        let containerWidth = max(textView.frame.width, 100)
        textContainer.containerSize = CGSize(width: containerWidth, height: CGFloat.greatestFiniteMagnitude)
        
        layoutManager.ensureLayout(for: textContainer)
        let usedHeight = layoutManager.usedRect(for: textContainer).height
        let totalHeight = usedHeight + buffer
        newHeight = min(max(totalHeight, minHeight), maxHeight)
        Task { @MainActor in
            if abs(self.height - newHeight) > 0.1 {
                self.height = newHeight
            }
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(text: $text,
                    height: $height,
                    isPlaceholderVisible: $isPlaceholderVisible,
                    onSend: onSend,
                    owner: self)
    }

    public class Coordinator: NSObject, NSTextViewDelegate {
        private let text: Binding<String>
        private let height: Binding<CGFloat>
        private let isPlaceholderVisible: Binding<Bool>
        private let onSend: () -> Void
        private let owner: GrowingTextView
        weak var textView: NSTextView?

        init(text: Binding<String>,
             height: Binding<CGFloat>,
             isPlaceholderVisible: Binding<Bool>,
             onSend: @escaping () -> Void,
             owner: GrowingTextView)
        {
            self.text = text
            self.height = height
            self.isPlaceholderVisible = isPlaceholderVisible
            self.onSend = onSend
            self.owner = owner
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }

        @objc public func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            // Update bindings and placeholder visibility
            self.text.wrappedValue = textView.string
            self.isPlaceholderVisible.wrappedValue = textView.string.isEmpty
            
            // Recalculate height
            self.owner.calculateHeight(for: textView)
        }

        public func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
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
