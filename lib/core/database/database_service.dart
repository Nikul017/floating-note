import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../features/notes/models/note_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('floatnotex.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE notes ADD COLUMN bubbleSize INTEGER NOT NULL DEFAULT 60');
    }
    if (oldVersion < 3) {
      await db.execute("ALTER TABLE notes ADD COLUMN bubbleShape TEXT NOT NULL DEFAULT 'circle'");
    }
    if (oldVersion < 4) {
      await db.execute("ALTER TABLE notes ADD COLUMN folder TEXT NOT NULL DEFAULT ''");
    }
    if (oldVersion < 5) {
      await db.execute("ALTER TABLE checklist_items ADD COLUMN indent INTEGER NOT NULL DEFAULT 0");
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        type TEXT NOT NULL,
        color TEXT NOT NULL,
        icon TEXT NOT NULL,
        opacity REAL NOT NULL,
        posX REAL NOT NULL,
        posY REAL NOT NULL,
        width REAL NOT NULL,
        height REAL NOT NULL,
        isDocked INTEGER NOT NULL,
        isLocked INTEGER NOT NULL,
        bubbleSize INTEGER NOT NULL DEFAULT 60,
        bubbleShape TEXT NOT NULL DEFAULT 'circle',
        folder TEXT NOT NULL DEFAULT '',
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE checklist_items (
        id TEXT PRIMARY KEY,
        noteId TEXT NOT NULL,
        text TEXT NOT NULL,
        checked INTEGER NOT NULL,
        indent INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (noteId) REFERENCES notes (id) ON DELETE CASCADE
      )
    ''');
  }

  // --- NOTES CRUD ---

  Future<void> insertNote(Note note) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.insert(
        'notes',
        note.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Remove old checklist items and insert new ones
      await txn.delete(
        'checklist_items',
        where: 'noteId = ?',
        whereArgs: [note.id],
      );

      for (var item in note.checklistItems) {
        await txn.insert(
          'checklist_items',
          item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<Note>> getAllNotes() async {
    final db = await instance.database;

    final notesMaps = await db.query('notes', orderBy: 'updatedAt DESC');
    final checklistMaps = await db.query('checklist_items');

    // Group checklist items by noteId
    final checklistGroup = <String, List<ChecklistItem>>{};
    for (var map in checklistMaps) {
      final item = ChecklistItem.fromMap(map);
      checklistGroup.putIfAbsent(item.noteId, () => []).add(item);
    }

    return notesMaps.map((map) {
      final id = map['id'] as String;
      return Note.fromMap(
        map,
        checklistItems: checklistGroup[id] ?? [],
      );
    }).toList();
  }

  Future<Note?> getNoteById(String id) async {
    final db = await instance.database;
    final maps = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    final checklistMaps = await db.query(
      'checklist_items',
      where: 'noteId = ?',
      whereArgs: [id],
    );

    final checklistItems = checklistMaps.map((map) => ChecklistItem.fromMap(map)).toList();

    return Note.fromMap(maps.first, checklistItems: checklistItems);
  }

  Future<void> updateNote(Note note) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.update(
        'notes',
        note.toMap(),
        where: 'id = ?',
        whereArgs: [note.id],
      );

      await txn.delete(
        'checklist_items',
        where: 'noteId = ?',
        whereArgs: [note.id],
      );

      for (var item in note.checklistItems) {
        await txn.insert(
          'checklist_items',
          item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> deleteNote(String id) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete(
        'checklist_items',
        where: 'noteId = ?',
        whereArgs: [id],
      );
      await txn.delete(
        'notes',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<void> clearAll() async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('checklist_items');
      await txn.delete('notes');
    });
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
