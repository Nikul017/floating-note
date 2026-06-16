# <img src="web/icons/Icon-192.png" width="48" height="48" valign="middle"/> Floating Note (Bubble Note)

A utility note capture application that leverages native Android Window overlays for floating context capture directly on top of third-party apps.

## Core Features
* **Android Window Overlay**: Runs a background service with SYSTEM_ALERT_WINDOW permissions for a floating bubble capture screen.
* **Bidirectional Platform Bridge**: Synchronizes real-time note checklists using MethodChannel/EventChannel between Dart and native Kotlin contexts.
* **Fast Offline DB**: Employs SQLite database structures for instant local storage, editing, and searches.
* **Neo-Brutalist Custom UI**: Uses OLED-friendly dark themes, border designs, and press-depth micro-animations.

## Golden Test Screenshots

| Dashboard | Note Editor (Checklist) | Note Editor (Text) | Settings Screen |
|---|---|---|---|
| ![Dashboard](test/goldens/dashboard_screen.android.png) | ![Checklist Note](test/goldens/note_editor_checklist_note.android.png) | ![Text Note](test/goldens/note_editor_text_note.android.png) | ![Settings](test/goldens/settings_screen.android.png) |
