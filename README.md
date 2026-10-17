# Notepad for macOS

A minimal, native macOS notes app with two independent writing spaces: a compact floating Quick Note and a distraction-free Full Pad.

## Features

- **Quick Note:** jot down short reminders in the main window or open a small floating window that can stay above other windows.
- **Full Pad:** a larger writing area with a full-screen toggle.
- **Separate notes:** each workspace stores its own text; editing one does not replace the other.
- **Autosave:** notes are saved locally using macOS preferences and remain available after quitting and reopening the app.
- **Offline-first:** the app does not need an account or network connection.
- **Dark interface:** native SwiftUI controls with a purple accent.

## Download the app (no Xcode required)

The GitHub Actions workflow builds the app automatically whenever code is pushed to `main`.

1. Open the repository's [Actions tab](../../actions/workflows/build-macos.yml).
2. Select the latest successful **Build macOS app** run.
3. Under **Artifacts**, download **Notepad-macOS**.
4. Unzip `Notepad-macOS.zip`.
5. Move `Notepad.app` into your **Applications** folder and open it.

The artifact is an unsigned app bundle. Since it is not notarized with an Apple Developer ID, macOS may show a security warning the first time you open it. Only bypass that warning if you trust the source and have reviewed the project.

**System requirement:** macOS 13 Ventura or later.

## Build locally

You only need Apple's Swift toolchain on a Mac. Xcode is one way to install it, but once the toolchain is available you can build from Terminal:

```bash
git clone https://github.com/waynetay/macos-notes.git
cd macos-notes
bash scripts/build-app.sh
open dist/Notepad.app
```

The build script creates `dist/Notepad.app`.

## Where notes are stored

The text is stored locally in the app's macOS `UserDefaults` preferences. Quick Note and Full Pad use separate keys. Notes are not uploaded to GitHub or any server.

Uninstalling the app does not necessarily remove its saved preferences. To manually reset the saved notes, use macOS app preferences only if you know what you are deleting; the current version does not include a reset button.

## Project structure

- `Package.swift` — Swift package definition.
- `Sources/Notepad/NotepadApp.swift` — app UI and note persistence.
- `scripts/build-app.sh` — packages the executable into a `.app` bundle.
- `.github/workflows/build-macos.yml` — builds and uploads a downloadable app artifact.

## License

MIT
