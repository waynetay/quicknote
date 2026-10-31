import AppKit
import Carbon
import ServiceManagement
import SwiftUI

@main
struct QuicknoteApp: App {
    @NSApplicationDelegateAdaptor(QuicknoteAppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("quicknote", systemImage: "note.text") {
            QuicknoteMenuView()
        }
        .menuBarExtraStyle(.menu)
    }
}

private final class QuicknoteAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        QuickNoteHotKey.shared.register(
            quickNoteAction: { QuickNotePanelController.shared.show() },
            notepadAction: { NotepadWindowController.shared.show() }
        )
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}

private final class QuickNoteHotKey {
    static let shared = QuickNoteHotKey()

    private var quickNoteHotKeyRef: EventHotKeyRef?
    private var notepadHotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var quickNoteAction: (() -> Void)?
    private var notepadAction: (() -> Void)?

    func register(quickNoteAction: @escaping () -> Void, notepadAction: @escaping () -> Void) {
        self.quickNoteAction = quickNoteAction
        self.notepadAction = notepadAction
        guard eventHandlerRef == nil else { return }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let handler: EventHandlerProcPtr = { _, event, userData in
            guard let event, let userData else { return OSStatus(eventNotHandledErr) }

            var pressedHotKey = EventHotKeyID()
            let readStatus = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &pressedHotKey
            )
            guard readStatus == noErr else { return readStatus }

            let controller = Unmanaged<QuickNoteHotKey>.fromOpaque(userData).takeUnretainedValue()
            let pressedHotKeyID = pressedHotKey.id
            DispatchQueue.main.async {
                switch pressedHotKeyID {
                case 1:
                    controller.quickNoteAction?()
                case 2:
                    controller.notepadAction?()
                default:
                    break
                }
            }
            return noErr
        }

        let installStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            handler,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )
        guard installStatus == noErr else { return }

        let quickNoteID = EventHotKeyID(signature: OSType(0x514E4F54), id: 1)
        let quickNoteStatus = RegisterEventHotKey(
            UInt32(kVK_ANSI_Q),
            UInt32(optionKey),
            quickNoteID,
            GetApplicationEventTarget(),
            0,
            &quickNoteHotKeyRef
        )
        guard quickNoteStatus == noErr else {
            if let eventHandlerRef {
                RemoveEventHandler(eventHandlerRef)
                self.eventHandlerRef = nil
            }
            return
        }

        let notepadID = EventHotKeyID(signature: OSType(0x514E4F54), id: 2)
        let notepadStatus = RegisterEventHotKey(
            UInt32(kVK_ANSI_Q),
            UInt32(optionKey | shiftKey),
            notepadID,
            GetApplicationEventTarget(),
            0,
            &notepadHotKeyRef
        )
        if notepadStatus != noErr {
            NSLog("Could not register Shift-Option-Q: %d", notepadStatus)
        }
    }
}

private struct QuicknoteMenuView: View {
    @State private var launchAtLoginEnabled = SMAppService.mainApp.status == .enabled

    var body: some View {
        Button("Quick Note  ⌥Q") {
            QuickNotePanelController.shared.show()
        }
        Button("Notepad  ⇧⌥Q") {
            NotepadWindowController.shared.show()
        }

        Divider()

        Toggle("Open at Login", isOn: $launchAtLoginEnabled)
            .onChange(of: launchAtLoginEnabled) { isEnabled in
                do {
                    if isEnabled {
                        try SMAppService.mainApp.register()
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                } catch {
                    launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
                }
            }

        if SMAppService.mainApp.status == .requiresApproval {
            Button("Review Login Items…") {
                SMAppService.openSystemSettingsLoginItems()
            }
        }

        Divider()

        Button("Quit quicknote") {
            NSApp.terminate(nil)
        }
    }
}

private enum AppStyle {
    static let accent = Color(red: 0.482, green: 0.286, blue: 1.0)
    static let background = Color(red: 0.075, green: 0.075, blue: 0.09)
    static let panel = Color(red: 0.105, green: 0.105, blue: 0.125)
    static let muted = Color.white.opacity(0.48)
}

/// Native Liquid Glass on macOS 26+, with a material fallback for macOS 13–15.
private extension View {
    @ViewBuilder
    func adaptiveGlass<S: Shape>(in shape: S) -> some View {
        if #available(macOS 26.0, *) {
            self.glassEffect(.regular, in: shape)
        } else {
            self
                .background(.ultraThinMaterial, in: shape)
                .overlay { shape.stroke(Color.white.opacity(0.12), lineWidth: 1) }
        }
    }
}

struct MainWindowView: View {
    @AppStorage("fullPadText") private var fullPadText = ""

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
            .background(AppStyle.panel.opacity(0.82), in: RoundedRectangle(cornerRadius: 20))
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
                    QuickNotePanelController.shared.show()
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

private final class NotepadWindowController: NSObject, NSWindowDelegate {
    static let shared = NotepadWindowController()
    private var window: NSWindow?

    func show() {
        NSApp.activate(ignoringOtherApps: true)

        if let window {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 520),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Notepad"
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.contentView = NSHostingView(
            rootView: MainWindowView()
                .frame(minWidth: 640, minHeight: 440)
                .preferredColorScheme(.dark)
        )

        self.window = window
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        guard let closingWindow = notification.object as? NSWindow,
              closingWindow === window else { return }
        window = nil
    }
}

private final class QuickNotePanelController: NSObject, NSWindowDelegate {
    static let shared = QuickNotePanelController()
    private var panel: NSPanel?

    func show() {
        NSApp.activate(ignoringOtherApps: true)

        if let panel {
            panel.makeKeyAndOrderFront(nil)
            return
        }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 336, height: 376),
            styleMask: [.titled, .closable, .resizable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.title = "Quick Note"
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .canJoinAllApplications]
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovableByWindowBackground = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.delegate = self
        panel.contentView = NSHostingView(
            rootView: QuickNoteWindowView()
                .frame(
                    minWidth: 280, idealWidth: 320, maxWidth: 520,
                    minHeight: 240, idealHeight: 360, maxHeight: 700
                )
                .preferredColorScheme(.dark)
        )

        self.panel = panel
        panel.center()
        panel.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        guard let closingPanel = notification.object as? NSPanel,
              closingPanel === panel else { return }
        panel = nil
    }
}

private struct QuickNoteWindowView: View {
    @AppStorage("quickNoteText") private var quickNoteText = ""
    @FocusState private var noteIsFocused: Bool
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
            .background(.ultraThinMaterial)

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
                    .focused($noteIsFocused)
                    .font(.system(size: 14))
                    .lineSpacing(4)
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(Color.white.opacity(0.94))
                    .accessibilityLabel("Quick Note text")
            }
            .padding(12)
        }
        .background(QuickNoteGlassBackground(shape: panelShape))
        .clipShape(panelShape)
        .overlay {
            panelShape.strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        }
        .padding(8)
        .background(Color.clear)
        .tint(AppStyle.accent)
        .onAppear {
            DispatchQueue.main.async {
                noteIsFocused = true
            }
        }
    }
}


private struct QuickNoteGlassBackground<S: Shape>: View {
    let shape: S

    var body: some View {
        if #available(macOS 26.0, *) {
            shape.fill(.clear).glassEffect(.regular, in: shape)
        } else {
            shape.fill(.ultraThinMaterial)
        }
    }
}
