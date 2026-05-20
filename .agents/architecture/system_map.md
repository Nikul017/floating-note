# System Map

## Project Overview

Project Name: Floating Note
Purpose: Create, manage, and display floating overlay notes and checklists on Android with native windows.
Platforms: Android (fully native overlay support), iOS, Windows, macOS, Linux, Web
Main Stack: Flutter, Kotlin, Riverpod, SQLite (sqflite)

---

# Features

- **Floating Notes**: Renders interactive notes as movable, dockable bubbles/overlays on Android.
- **Note Types**: Supports Plain text and Checklist types.
- **Checklist Items**: Nested/indented list items per note.
- **Folder Grouping**: Notes categorization under specific folder names.
- **Customization**: Individual and global bubble shapes, sizes, colors, and opacity configurations.
- **Native Overlay Channel**: Real-time position, docking, locking, and visibility synchronization between Dart and Kotlin.

---

# Architecture

Pattern:
- feature-first structure
- Repository / Service abstraction pattern
- Riverpod state management

---

# State Flow

UI (Dashboard, Note Editor, Native Overlay)
→ State Notifiers (notesProvider, settingsProvider)
→ Storage / Channel Layer (DatabaseService, OverlayChannel)
→ SQLite DB / Native Android Window Manager

---

# Native Android Layer

Flutter ↔ Kotlin bridge via `MethodChannel` and `EventChannel` (`OverlayChannel.instance`)

Used for:
- Creating floating window overlays.
- Synchronizing real-time overlay note state modifications.
- Handling window events: drag/position updates, minimizing/docking, locking, and deletions.
- Requesting system alert window permissions.

---

# Critical Services

## DatabaseService
Handles database initialization, migrations, and CRUD transactions for notes and checklist items.

## OverlayChannel
Coordinates communication with the Android background service and window overlay renderer.

## SettingsManager (settingsProvider)
Manages user configurations, persistent settings, default notes colors, and global bubble geometry.

---

# Database

SQLite tables:
- `notes`: Contains note content, type, geometry (posX, posY, width, height), docking/locking flags, bubble characteristics, folder, and timestamps.
- `checklist_items`: Individual checklist items with foreign key relation to a note ID, text, checked status, and custom indentation levels.

---

# Navigation

DashboardScreen
→ NoteEditorScreen (create or modify a note)
→ SettingsScreen (adjust global bubble shapes, default sizes, styles, and clear database)
