# quicknote

A minimal native macOS notes app with a clean notepad and a compact floating Quick Note.

## Download and install

The GitHub Actions workflow automatically builds a **DMG installer** whenever code is pushed to `main`.

1. Open the [Actions tab](../../actions/workflows/build-macos.yml).
2. Select the latest successful **Build macOS app** run.
3. Under **Artifacts**, download `quicknote-installer`.
4. Open the downloaded artifact ZIP to extract `quicknote-macOS.dmg`.
5. Open the DMG and drag `quicknote.app` onto the Applications shortcut shown in the window.
6. Eject the disk image and launch quicknote from Applications.

You do not need Xcode to install or use the app. The app is unsigned and not notarized with an Apple Developer ID, so macOS may show a security warning on first launch. Only open it if you trust the source.

**Requirement:** macOS 13 Ventura or later.

## Features

- **Notepad:** a spacious writing area with only the title and a simple "Start writing" placeholder.
- **Floating Quick Note:** use the toolbar button to open a small window configured to stay above other windows, including fullscreen Spaces.
- **Independent notes:** the main Notepad and Quick Note save different text.
- **Autosave:** notes persist locally after quitting and reopening.
- **Offline-first:** notes are stored on this Mac and are not uploaded to GitHub or a server.
- **Dark interface:** native SwiftUI with a purple accent.

## Build locally

On a Mac with Apple's Swift toolchain installed:

```bash
git clone https://github.com/waynetay/macos-notes.git
cd macos-notes
bash scripts/build-app.sh
open dist/quicknote.app
```

## Storage

Notes are stored locally in macOS UserDefaults under separate keys for the main Notepad and floating Quick Note. Uninstalling the app does not necessarily remove saved preferences.

## Project structure

- `Package.swift` — Swift package definition.
- `Sources/Notepad/NotepadApp.swift` — app interface and note persistence.
- `scripts/build-app.sh` — packages the executable as `quicknote.app` and creates a DMG installer.
- `.github/workflows/build-macos.yml` — builds and uploads the installer artifact.

## License

MIT
