import AppKit
import Combine
import SwiftUI

@MainActor
final class RichTextEditorState: ObservableObject {
    weak var textView: NSTextView?
    var persistChanges: (() -> Void)?

    func focus() {
        guard let textView else { return }
        textView.window?.makeFirstResponder(textView)
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
        let isActive: Bool
        if range.length > 0, range.location < textView.string.utf16.count {
            let current = textView.attributedString().attribute(key, at: range.location, effectiveRange: nil)
            isActive = (current as? NSNumber)?.intValue != nil && (current as? NSNumber)?.intValue != 0
        } else {
            isActive = (textView.typingAttributes[key] as? NSNumber)?.intValue != nil &&
                (textView.typingAttributes[key] as? NSNumber)?.intValue != 0
        }

        let newValue: Any? = isActive ? nil : NSNumber(value: NSUnderlineStyle.single.rawValue)
        if range.length == 0 {
            var attributes = textView.typingAttributes
            attributes[key] = newValue
            textView.typingAttributes = attributes
        } else if let storage = textView.textStorage {
            if let newValue {
                storage.addAttribute(key, value: newValue, range: range)
            } else {
                storage.removeAttribute(key, range: range)
            }
        }
        persistChanges?()
    }

    private func font(at location: Int, in textView: NSTextView) -> NSFont? {
        guard location >= 0, location < textView.string.utf16.count else { return nil }
        return textView.attributedString().attribute(.font, at: location, effectiveRange: nil) as? NSFont
    }
}

private struct RichTextFormattingToolbar: View {
    let state: RichTextEditorState

    var body: some View {
        HStack(spacing: 6) {
            formatButton("B", name: "Bold", weight: .bold) {
                state.toggleFontTrait(.boldFontMask)
            }
            formatButton("I", name: "Italic", italic: true) {
                state.toggleFontTrait(.italicFontMask)
            }
            formatButton("S̶", name: "Strikethrough") {
                state.toggleStrikethrough()
            }
            formatButton("U̲", name: "Underline") {
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
        weight: Font.Weight = .medium,
        italic: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: weight, design: .rounded).italic(italic))
                .foregroundStyle(Color.white.opacity(0.88))
                .frame(width: 30, height: 27)
                .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .help(name)
        .accessibilityLabel(name)
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

        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.isRichText = true
        textView.importsGraphics = false
        textView.usesFontPanel = false
        textView.drawsBackground = false
        textView.font = .systemFont(ofSize: 15)
        textView.textColor = NSColor.white.withAlphaComponent(0.94)
        textView.insertionPointColor = NSColor(red: 0.482, green: 0.286, blue: 1, alpha: 1)
        textView.textContainerInset = NSSize(width: 0, height: 0)
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
