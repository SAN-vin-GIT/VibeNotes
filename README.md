# Vibe Notes

Vibe Notes is a premium, high-performance macOS utility designed to be a snappy, elegant, and persistent side-drawer note-taking application.

Inspired by popular "side-drawer" apps, Vibe Notes lives discreetly on the edge of your screen. It can be toggled instantly to capture fleeting thoughts, organize code snippets, and manage multiple folders of notes without ever interrupting your main workflow.

## Key Features

- **Blazing Fast Animations**: Tuned for 0.15s spring animations – the drawer slides in and folders expand with zero lag.
- **Smart Drawer Sizing**: A dedicated toolbar button toggles the app between a Full-Height mode and a centered, focused Half-Height mode.
- **Universal Trigger**: A sleek, dark, pill-shaped handle (14pt wide, 10pt radius) with a minimalist `|` icon sits on the edge of the screen, providing perfect contrast against any background.
- **Rich Text Formatting**: WYSIWYG **Bold**, __Underline__, and ~~Strikethrough~~ formatting with toolbar buttons. Markdown tags are completely hidden — what you see is what you get.
- **Undo & Redo**: Full `Cmd+Z` / `Cmd+Shift+Z` support with per-note isolated undo history. Switching notes never corrupts your undo stack.
- **Drag & Drop Reordering**: Reorder both folders and notes with smooth, responsive drag-and-drop. Custom lightweight drag previews for instant visual feedback.
- **Space-Transition Safe**: The drawer stays perfectly in place during macOS three-finger Space swipes — no flickering or ghost appearances.
- **Data Persistence**: Uses a local JSON datastore (`data.json`) that saves automatically in the background (debounced by 2 seconds) to minimize CPU and disk usage. Notes are safely stored in `~/Library/Application Support/VibeNotes/`.
- **Premium Aesthetics**: Features a subtle white-glow sidebar (`ultraThickMaterial`), a clean note editor (`ultraThinMaterial`), seamless rounded application corners (20pt radius), and a seamless single-scrollbar experience.
- **Safety**: Includes a protected "Power" button to exit the application with a confirmation dialogue, preventing accidental closure.

## Technology Stack

- **Language**: Swift 5.9+
- **Framework**: SwiftUI (Native App Lifecycle)
- **Architecture**: MVVM (Model-View-ViewModel) using Combine and `ObservableObject` for state management.
- **Platform**: macOS 13.0+

## Data Storage & Backups

Vibe Notes stores all your notes and folders entirely locally on your machine in a plain JSON format. This means your data is fully under your control, privacy-respecting, and incredibly easy to back up, sync to a cloud drive (like iCloud/Dropbox), or migrate to another Mac!

**Your notes are located at:**
```bash
~/Library/Application Support/VibeNotes/data.json
```

**How to open this folder:**
1. Open Finder.
2. Press `Cmd + Shift + G` to open the "Go to Folder" prompt.
3. Paste `~/Library/Application Support/VibeNotes/` and press Enter.

> **Note:** The `Library` folder is hidden by default in macOS. You won't see it in Finder unless you use the "Go to Folder" shortcut above, or press `Cmd + Shift + .` in Finder to temporarily reveal hidden files.

To back up your notes, simply copy the `data.json` file. To restore them later, just paste your backup file into that exact same folder before opening the app!

## Development Setup

To build and run the application locally for development or testing:

1. Open a terminal in the project directory.
2. Run the following command:
   ```bash
   swift run
   ```

## Packaging & Distribution

Vibe Notes includes a script to automatically compile a high-performance `Release` build, bundle your custom icon (`VibeNotesLogo.png`), and package everything into an installable macOS Application (`Vibe Notes.app`) and a distributable Disk Image (`VibeNotes.dmg`).

### How to Regenerate the `.dmg` Installer

If you lose your `VibeNotes.dmg` file, you can easily recreate it natively from this source code.

1. Open your Terminal program on macOS.
2. Navigate to this project folder. For example:
   ```bash
   cd /path/to/VibeNotes
   ```
3. Run the following command to automatically generate the `.app` and package the `.dmg`:
   ```bash
   ./build_app.sh && hdiutil create -volname "Vibe Notes" -srcfolder "Vibe Notes.app" -ov -format UDZO VibeNotes.dmg
   ```
4. The script will run. Once it says `created: ... VibeNotes.dmg`, you will find your shiny new installer ready to share in this folder!
