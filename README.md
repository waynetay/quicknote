# quicknote

A minimal native macOS notes app with a clean notepad and a compact floating Quick Note.

## Features

- **Notepad:** a spacious writing area with only the title and a simple "Start writing" placeholder.
- **Floating Quick Note:** use the toolbar button to open a small window that stays above other windows.
- **Independent notes:** the main Notepad and Quick Note save different text.
- **Autosave:** notes persist locally after quitting and reopening.
- **Offline-first:** notes are stored on this Mac and are not uploaded to GitHub or a server.
- **Dark interface:** native SwiftUI with a purple accent.

## Download (no Xcode required to use)

Every push to `main` triggers a GitHub Actions build.

1. Open the [Actions tab](../../actions/workflows/build-macos.yml).
2. Select the latest successful **Build macOS app** run.
3. Download the **quicknote-macOS** artifact.
4. Unzip it and move `quicknote.app` to Applications.
5. Open `quicknote.app`.

The app is unsigned and not notarized with an Apple Developer ID, so macOS may show a security warning on first launch. Only open it if you trust the source.

**Requirement:** macOS 13 Ventura or later.

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
- `scripts/build-app.sh` — packages the executable into a `.app` bundle.
- `.github/workflows/build-macos.yml` — builds and uploads the app artifact.

## License

MIT
