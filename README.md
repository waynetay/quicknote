# quicknote

A minimal native macOS notes app with a clean notepad and a compact floating Quick Note.

## Download and install

Download the **v1.3 installer ZIP** from the [GitHub Releases page](https://github.com/waynetay/macos-notes/releases/latest).

1. Download the installer ZIP asset.
2. Double-click the ZIP to extract `quicknote-macOS.dmg`.
3. Open the DMG.
4. Drag `quicknote.app` onto the **Applications** shortcut in the installer window.
5. Eject the disk image, then launch quicknote from Applications.


**Requirements:** macOS 13 Ventura or later.

The app is ad-hoc signed, not signed with an Apple Developer ID or notarized. macOS may show a security warning on first launch. If that happens, use macOS **System Settings → Privacy & Security** to review the blocked app and allow it.

## Features

- **Notepad:** a spacious writing area with a simple "Start writing" placeholder.
- **Floating Quick Note:** a compact window that can appear above other apps, including in full-screen Spaces.
- **Quick launch:** press **Option–Q** to open the floating Quick Note from anywhere while quicknote is running.
- **Menu bar app:** quicknote stays available in the menu bar without keeping the Notepad window open. Use **Open at Login** to start it automatically.
- **Independent notes:** the main Notepad and Quick Note save different text.
- **Autosave:** notes persist locally after quitting and reopening.
- **Offline-first:** notes are stored on this Mac and are not uploaded to GitHub or a server.
- **Liquid Glass:** Liquid glass is used in this app

## Notes

Notes are stored locally in macOS UserDefaults under separate keys for the main Notepad and floating Quick Note. Uninstalling the app does not necessarily remove saved preferences.

## License

MIT
