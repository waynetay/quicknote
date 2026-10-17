import AppKit
import SwiftUI

@main
struct QuicknoteApp: App {
    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .frame(minWidth: 640, minHeight: 440)
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

private enum AppStyle {
    static let accent = Color(red: 0.482, green: 0.286, blue: 1.0)
    static let background = Color(red: 0.075, green: 0.075, blue: 0.09)
    static let panel = Color(red: 0.105, green: 0.105, blue: 0.125)
    static let muted = Color.white.opacity(0.48)
}

struct MainWindowView: View {
    @AppStorage("fullPadText") private var fullPadText = ""
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Notepad")
                    .font(.system(size: 29, weight: .semibold, design: .rounded))
                    .tracking(-0.7)
                Spacer()
            }
            .padding(.bottom, 24)

            ZStack {
                if fullPadText.isEmpty {
                    Text("Start writing")
                        .font(.system(size: 15))
                        .foregroundStyle(AppStyle.muted.opacity(0.7))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $fullPadText)
                    .font(.system(size: 15))
                    .lineSpacing(5)
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(Color.white.opacity(0.92))
                    .accessibilityLabel("Notepad")
            }
            .padding(15)
            .background(AppStyle.panel, in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
            }
        }
        .padding(30)
        .background(AppStyle.background)
        .tint(AppStyle.accent)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    openWindow(id: "quick-note")
                } label: {
                    Label("Quick Note", systemImage: "macwindow")
                }
                .help("Open the floating Quick Note")
            }
        }
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
                    .accessibilityLabel("Quick Note text")
            }
            .padding(12)
        }
        .background(AppStyle.background)
        .onAppear {
            DispatchQueue.main.async {
                if let window = NSApp.windows.first(where: { $0.title == "Quick Note" }) {
                    window.level = .floating
                    window.collectionBehavior.insert([.canJoinAllSpaces, .fullScreenAuxiliary])
                    window.isReleasedWhenClosed = false
                }
            }
        }
    }
}
