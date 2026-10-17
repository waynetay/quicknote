import AppKit
import SwiftUI

@main
struct NotepadApp: App {
    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .frame(minWidth: 760, minHeight: 520)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.titleBar)

        WindowGroup("Quick Note", id: "quick-note") {
            QuickNoteWindowView()
                .frame(minWidth: 280, idealWidth: 320, maxWidth: 520,
                       minHeight: 240, idealHeight: 360, maxHeight: 700)
                .preferredColorScheme(.dark)
        }
        .defaultSize(width: 320, height: 360)
    }
}

private enum NotesPage: String, CaseIterable, Identifiable {
    case quickNote = "Quick Note"
    case fullPad = "Full Pad"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .quickNote: return "note.text"
        case .fullPad: return "doc.text"
        }
    }
}

private enum AppStyle {
    static let accent = Color(red: 0.482, green: 0.286, blue: 1.0)
    static let background = Color(red: 0.075, green: 0.075, blue: 0.09)
    static let panel = Color(red: 0.105, green: 0.105, blue: 0.125)
    static let muted = Color.white.opacity(0.48)
}

struct MainWindowView: View {
    @AppStorage("quickNoteText") private var quickNoteText = ""
    @AppStorage("fullPadText") private var fullPadText = ""
    @State private var selectedPage: NotesPage? = .fullPad
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 10) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(AppStyle.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Notepad")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Your space to think")
                            .font(.system(size: 11))
                            .foregroundStyle(AppStyle.muted)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 18)

                List(selection: $selectedPage) {
                    Section("WORKSPACES") {
                        ForEach(NotesPage.allCases) { page in
                            Label(page.rawValue, systemImage: page.symbol)
                                .tag(page)
                                .padding(.vertical, 5)
                        }
                    }
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 5) {
                    Label("Saved automatically", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(AppStyle.muted)
                    Text("Notes stay on this Mac.")
                        .foregroundStyle(AppStyle.muted.opacity(0.8))
                }
                .font(.system(size: 11))
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .frame(minWidth: 190)
            .background(AppStyle.background)
            .navigationSplitViewColumnWidth(min: 190, ideal: 220, max: 260)
        } detail: {
            Group {
                switch selectedPage ?? .fullPad {
                case .quickNote:
                    NoteEditorView(
                        title: "Quick Note",
                        subtitle: "A little space for the things you don't want to forget.",
                        placeholder: "Jot something down…",
                        text: $quickNoteText,
                        compact: true
                    )
                case .fullPad:
                    NoteEditorView(
                        title: "Full Pad",
                        subtitle: "Room to think, plan, and write without limits.",
                        placeholder: "Start writing…",
                        text: $fullPadText,
                        compact: false
                    )
                }
            }
            .background(AppStyle.background)
        }
        .tint(AppStyle.accent)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    openWindow(id: "quick-note")
                } label: {
                    Label("Floating Quick Note", systemImage: "macwindow")
                }
                .help("Open Quick Note in a small separate window")

                Button {
                    NSApp.keyWindow?.toggleFullScreen(nil)
                } label: {
                    Label("Full Screen", systemImage: "arrow.up.left.and.arrow.down.right")
                }
                .help("Toggle full-screen writing")
            }
        }
    }
}

private struct NoteEditorView: View {
    let title: String
    let subtitle: String
    let placeholder: String
    @Binding var text: String
    let compact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(title)
                        .font(.system(size: compact ? 25 : 31, weight: .semibold, design: .rounded))
                        .tracking(-0.7)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(AppStyle.muted)
                }
                Spacer()
                Image(systemName: compact ? "note.text" : "doc.text")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(AppStyle.accent)
                    .frame(width: 44, height: 44)
                    .background(AppStyle.accent.opacity(0.13), in: RoundedRectangle(cornerRadius: 13))
            }
            .padding(.bottom, 24)

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 15))
                        .foregroundStyle(AppStyle.muted.opacity(0.7))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 9)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $text)
                    .font(.system(size: compact ? 14 : 15))
                    .lineSpacing(5)
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(Color.white.opacity(0.92))
                    .textEditorStyle(.plain)
                    .accessibilityLabel(title)
            }
            .padding(15)
            .background(AppStyle.panel, in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
            }

            HStack(spacing: 7) {
                Circle()
                    .fill(AppStyle.accent)
                    .frame(width: 6, height: 6)
                Text("Saved on this Mac")
                Spacer()
                Text("\(text.count) characters")
                    .monospacedDigit()
            }
            .font(.system(size: 11))
            .foregroundStyle(AppStyle.muted)
            .padding(.top, 12)
        }
        .padding(compact ? 22 : 34)
    }
}

private struct QuickNoteWindowView: View {
    @AppStorage("quickNoteText") private var quickNoteText = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "note.text")
                    .foregroundStyle(AppStyle.accent)
                Text("Quick Note")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("AUTOSAVED")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(0.7)
                    .foregroundStyle(AppStyle.muted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)

            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)

            ZStack(alignment: .topLeading) {
                if quickNoteText.isEmpty {
                    Text("What's on your mind?")
                        .foregroundStyle(AppStyle.muted.opacity(0.75))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $quickNoteText)
                    .font(.system(size: 14))
                    .lineSpacing(4)
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(Color.white.opacity(0.94))
                    .textEditorStyle(.plain)
                    .accessibilityLabel("Quick Note text")
            }
            .padding(12)
        }
        .background(AppStyle.background)
        .onAppear {
            DispatchQueue.main.async {
                if let window = NSApp.windows.first(where: { $0.title == "Quick Note" }) {
                    window.level = .floating
                    window.collectionBehavior.insert(.canJoinAllSpaces)
                    window.isReleasedWhenClosed = false
                }
            }
        }
    }
}
