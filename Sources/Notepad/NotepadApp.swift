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

/// Uses Apple's Liquid Glass on macOS 26+, with a translucent material fallback
/// so the app continues to work on its supported macOS 13+ deployment target.
private struct AdaptiveGlass<ShapeType: Shape>: ViewModifier {
    let shape: ShapeType

    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content.glassEffect(.regular, in: shape)
        } else {
            content
                .background(.ultraThinMaterial, in: shape)
                .overlay {
                    shape.strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                }
        }
    }
}

private extension View {
    func adaptiveGlass<S: Shape>(in shape: S) -> some View {
        modifier(AdaptiveGlass(shape: shape))
    }
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
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppStyle.panel.opacity(0.78))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20)
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
                        .padding(.horizontal, 3)
                }
                .help("Open the floating Quick Note")
                .adaptiveGlass(in: Capsule())
            }
        }
    }
}

private struct QuickNoteWindowView: View {
    @AppStorage("quickNoteText") private var quickNoteText = ""

    private let panelShape = RoundedRectangle(cornerRadius: 22, style: .continuous)

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
            .background(.ultraThinMaterial.opacity(0.55))

            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)

            ZStack {
                if quickNoteText.isEmpty {
                    Text("What's on your mind?")
                        .font(.system(size: 14))
                        .foregroundStyle(AppStyle.muted.opacity(0.75))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
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
        .background {
            ZStack {
                AppStyle.background.opacity(0.78)
                if #available(macOS 26.0, *) {
                    panelShape.fill(.clear).glassEffect(.regular, in: panelShape)
                } else {
                    Rectangle().fill(.ultraThinMaterial)
                }
            }
        }
        .clipShape(panelShape)
        .overlay {
            panelShape.strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        }
        .padding(8)
        .background(Color.clear)
        .tint(AppStyle.accent)
        .onAppear {
            DispatchQueue.main.async {
                if let window = NSApp.windows.first(where: { $0.title == "Quick Note" }) {
                    window.level = .floating
                    window.collectionBehavior.insert([.canJoinAllSpaces, .fullScreenAuxiliary])
                    window.isReleasedWhenClosed = false
                    window.titlebarAppearsTransparent = true
                    window.titleVisibility = .hidden
                    window.isMovableByWindowBackground = true
                }
            }
        }
    }
}
