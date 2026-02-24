# Vibe Notes

Vibe Notes is a premium, high-performance macOS utility designed to be a snappy, elegant, and persistent side-drawer note-taking application.

Inspired by popular "side-drawer" apps, Vibe Notes lives discreetly on the edge of your screen. It can be toggled instantly to capture fleeting thoughts, organize code snippets, and manage multiple folders of notes without ever interrupting your main workflow.

## Key Features

- **Blazing Fast Animations**: Tuned for 0.15s spring animations – the drawer slides in and folders expand with zero lag.
- **Smart Drawer Sizing**: A dedicated toolbar button toggles the app between a Full-Height mode and a centered, focused Half-Height mode.
- **Universal Trigger**: A sleek, dark, pill-shaped handle (14pt wide, 10pt radius) with a minimalist `|` icon sits on the edge of the screen, providing perfect contrast against any background.
- **Data Persistence**: Uses a local JSON datastore (`data.json`) that saves automatically in the background (debounced by 2 seconds) to minimize CPU and disk usage. Notes are safely stored in `~/Library/Application Support/VibeNotes/`.
- **Premium Aesthetics**: Features a subtle white-glow sidebar (`ultraThickMaterial`), a clean note editor (`ultraThinMaterial`), seamless rounded application corners (20pt radius), and a seamless single-scrollbar experience.
- **Safety**: Includes a protected "Power" button to exit the application with a confirmation dialogue, preventing accidental closure. 

## Technology Stack

- **Language**: Swift 5.9+
- **Framework**: SwiftUI (Native App Lifecycle)
- **Architecture**: MVVM (Model-View-ViewModel) using Combine and `ObservableObject` for state management.
- **Platform**: macOS 13.0+

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
   cd /path/to/side-notes
   ```
3. Run the following command to automatically generate the `.app` and package the `.dmg`:
   ```bash
   ./build_app.sh && hdiutil create -volname "Vibe Notes" -srcfolder "Vibe Notes.app" -ov -format UDZO VibeNotes.dmg
   ```
4. The script will run. Once it says `created: ... VibeNotes.dmg`, you will find your shiny new installer ready to share in this folder!
