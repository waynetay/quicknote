import AppKit
import Combine
import SwiftUI

@MainActor
final class RichTextEditorState: ObservableObject {
    @Published private(set) var isBoldActive = false
    @Published private(set) var isItalicActive = false
    @Published private(set) var isStrikethroughActive = false
    @Published private(set) var isUnderlineActive = false
    weak var textView: NSTextView?
    var persistChanges: (() -> Void)?

    func refreshActiveStyles() {
        guard let textView else { return }
        let range = textView.selectedRange()
        var attributes = textView.typingAttributes
        if range.length > 0, range.location < textView.string.utf16.count {
            attributes = textView.attributedString().attributes(at: range.location, effectiveRange: nil)
        }
        let font = (attributes[.font] as? NSFont) ?? textView.font ?? .systemFont(ofSize: 15)
        let traits = NSFontManager.shared.traits(of: font)
        isBoldActive = traits.contains(.boldFontMask)
        isItalicActive = traits.contains(.italicFontMask)
        isStrikethroughActive = selectionHasStyle(.strikethroughStyle, range: range, in: textView)
        isUnderlineActive = selectionHasStyle(.underlineStyle, range: range, in: textView)
    }

    private func styleValue(_ key: NSAttributedString.Key, in attributes: [NSAttributedString.Key: Any]) -> Int {
        if let number = attributes[key] as? NSNumber { return number.intValue }
        if let value = attributes[key] as? Int { return value }
        return 0
    }

    private func selectionHasStyle(_ key: NSAttributedString.Key, range: NSRange, in textView: NSTextView) -> Bool {
        guard range.length > 0, let storage = textView.textStorage else {
            return styleValue(key, in: textView.typingAttributes) != 0
        }
        guard NSMaxRange(range) <= storage.length else { return false }
        var allStyled = true
        storage.enumerateAttribute(key, in: range) { value, _, stop in
            let active = styleValue(key, in: [key: value as Any]) != 0
            if !active {
                allStyled = false
                stop.pointee = true
            }
        }
        return allStyled
    }

    func focus() {
        guard let textView else { return }
        DispatchQueue.main.async { [weak textView] in
            guard let textView, let window = textView.window else { return }
            window.makeFirstResponder(textView)
        }
    }

    func toggleFontTrait(_ trait: NSFontTraitMask) {
        guard let textView else { return }
        let range = textView.selectedRange()
        let attributes = textView.typingAttributes
        let baseFont = (attributes[.font] as? NSFont) ?? textView.font ?? .systemFont(ofSize: 15)
        let referenceFont = font(at: range.location, in: textView) ?? baseFont
        let shouldEnable = !NSFontManager.shared.traits(of: referenceFont).contains(trait)

        if range.length == 0 {
            var updated = attributes
            updated[.font] = shouldEnable
                ? NSFontManager.shared.convert(baseFont, toHaveTrait: trait)
                : NSFontManager.shared.convert(baseFont, toNotHaveTrait: trait)
            textView.typingAttributes = updated
        } else if let storage = textView.textStorage {
            storage.beginEditing()
            storage.enumerateAttribute(.font, in: range) { value, subrange, _ in
                let font = (value as? NSFont) ?? baseFont
                let updatedFont = shouldEnable
                    ? NSFontManager.shared.convert(font, toHaveTrait: trait)
                    : NSFontManager.shared.convert(font, toNotHaveTrait: trait)
                storage.addAttribute(.font, value: updatedFont, range: subrange)
            }
            storage.endEditing()
        }
        persistChanges?()
        refreshActiveStyles()
        refocus(textView)
    }

    func toggleUnderline() {
        toggleStyle(.underlineStyle)
    }

    func toggleStrikethrough() {
        toggleStyle(.strikethroughStyle)
    }

    private func toggleStyle(_ key: NSAttributedString.Key) {
        guard let textView else { return }
        let range = textView.selectedRange()
        let isActive = selectionHasStyle(key, range: range, in: textView)
        let newValue: Any? = isActive ? nil : NSNumber(value: NSUnderlineStyle.single.rawValue)

        if range.length == 0 {
            var updated = textView.typingAttributes
            updated[key] = newValue
            textView.typingAttributes = updated
        } else if let storage = textView.textStorage {
            if let newValue {
                storage.addAttribute(key, value: newValue, range: range)
            } else {
                storage.removeAttribute(key, range: range)
            }
        }
        persistChanges?()
        refreshActiveStyles()
        refocus(textView)
    }

    private func currentAttributes(for range: NSRange, in textView: NSTextView) -> [NSAttributedString.Key: Any] {
        if range.length > 0, range.location < textView.string.utf16.count {
            return textView.attributedString().attributes(at: range.location, effectiveRange: nil)
        }
        return textView.typingAttributes
    }

    private func font(at location: Int, in textView: NSTextView) -> NSFont? {
        guard location >= 0, location < textView.string.utf16.count else { return nil }
        return textView.attributedString().attribute(.font, at: location, effectiveRange: nil) as? NSFont
    }

    private func refocus(_ textView: NSTextView) {
        DispatchQueue.main.async { [weak textView] in
            guard let textView else { return }
            textView.window?.makeFirstResponder(textView)
        }
    }
}

struct RichTextFormattingToolbar: View {
    @ObservedObject var state: RichTextEditorState

    var body: some View {
        HStack(spacing: 6) {
            formatButton("B", name: "Bold", isActive: state.isBoldActive, weight: .bold) {
                state.toggleFontTrait(.boldFontMask)
            }
            formatButton("I", name: "Italic", isActive: state.isItalicActive, italic: true) {
                state.toggleFontTrait(.italicFontMask)
            }
            formatButton("S̶", name: "Strikethrough", isActive: state.isStrikethroughActive) {
                state.toggleStrikethrough()
            }
            formatButton("U̲", name: "Underline", isActive: state.isUnderlineActive) {
                state.toggleUnderline()
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.035))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.07)).frame(height: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Text formatting")
    }

    private func formatButton(
        _ title: String,
        name: String,
        isActive: Bool,
        weight: Font.Weight = .medium,
        italic: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(italic ? .system(size: 13, weight: weight, design: .rounded).italic() : .system(size: 13, weight: weight, design: .rounded))
                .foregroundStyle(isActive ? Color.black.opacity(0.88) : Color.white.opacity(0.72))
                .frame(width: 30, height: 27)
                .background(isActive ? Color.white.opacity(0.92) : Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 6))
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isActive ? Color.white.opacity(0.95) : Color.white.opacity(0.12), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .help(name)
        .accessibilityLabel(name)
        .accessibilityValue(isActive ? "On" : "Off")
    }
}

private final class QuicknoteTextView: NSTextView {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        super.mouseDown(with: event)
    }
}

struct RichTextEditor: NSViewRepresentable {
    @Binding var text: String
    @Binding var richTextData: Data
    let state: RichTextEditorState

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.contentView.drawsBackground = false

        let textView = QuicknoteTextView(frame: .zero)
        scrollView.documentView = textView
        textView.delegate = context.coordinator
        textView.isEditable = true
        textView.isSelectable = true
        textView.isFieldEditor = false
        textView.allowsUndo = true
        textView.isRichText = true
        textView.importsGraphics = false
        textView.usesFontPanel = false
        textView.drawsBackground = false
        textView.font = .systemFont(ofSize: 15)
        textView.textColor = NSColor.white.withAlphaComponent(0.94)
        textView.insertionPointColor = NSColor(red: 0.482, green: 0.286, blue: 1, alpha: 1)
        textView.textContainerInset = NSSize(width: 0, height: 0)
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.typingAttributes = [
            .font: NSFont.systemFont(ofSize: 15),
            .foregroundColor: NSColor.white.withAlphaComponent(0.94)
        ]

        restoreContent(into: textView)
        scrollView.documentView = textView
        state.textView = textView
        installPersistenceCallback(for: textView, coordinator: context.coordinator)
        state.refreshActiveStyles()
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        state.textView = textView
        installPersistenceCallback(for: textView, coordinator: context.coordinator)
        if textView.string != text {
            restoreContent(into: textView)
        }
    }

    private func restoreContent(into textView: NSTextView) {
        if !richTextData.isEmpty,
           let restored = try? NSAttributedString(
            data: richTextData,
            options: [.documentType: NSAttributedString.DocumentType.rtf],
            documentAttributes: nil
           ),
           restored.string == text {
            textView.textStorage?.setAttributedString(restored)
        } else {
            textView.string = text
            textView.typingAttributes = [
                .font: NSFont.systemFont(ofSize: 15),
                .foregroundColor: NSColor.white.withAlphaComponent(0.94)
            ]
        }
    }

    private func installPersistenceCallback(for textView: NSTextView, coordinator: Coordinator) {
        state.persistChanges = { [weak textView, weak coordinator] in
            guard let textView, let coordinator else { return }
            coordinator.persist(textView)
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        private var parent: RichTextEditor

        init(_ parent: RichTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            persist(textView)
            parent.state.refreshActiveStyles()
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            parent.state.refreshActiveStyles()
        }

        func persist(_ textView: NSTextView) {
            parent.text = textView.string
            guard let storage = textView.textStorage else { return }
            let range = NSRange(location: 0, length: storage.length)
            parent.richTextData = storage.rtf(
                from: range,
                documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
            ) ?? Data()
        }
    }
}
