import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mynotes/extension/list/filter.dart';
import 'package:mynotes/services/crud/crud_exception.dart';
import "package:sqflite/sqflite.dart";
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart'
    show MissingPlatformDirectoryException, getApplicationDocumentsDirectory;
import 'package:sqflite/sqlite_api.dart';

class NoteService {
  Database? _db;

  List<DatabaseNote> _notes = [];

  DatabaseUser? _user;

// Singleton
  static final NoteService _shared = NoteService._sharedInstance();
  NoteService._sharedInstance() {
    _noteStreamController = StreamController<List<DatabaseNote>>.broadcast(
      onListen: () {
        _noteStreamController.sink.add(_notes);
      },
    );
  }
  factory NoteService() => _shared;
// -----
  late final StreamController<List<DatabaseNote>> _noteStreamController;

  Stream<List<DatabaseNote>> get allNotes =>
      _noteStreamController.stream.filter((note) {
        final currentUser = _user;
        if (currentUser != null) {
          return note.userId == currentUser.id;
        } else {
          throw UserShouldBeSetBeforeCreateNote();
        }
      });

  Future<void> _cacheNotes() async {
    final allNotes = await getAllNotes();
    _notes = allNotes.toList();
    _noteStreamController.add(_notes);
  }

  Future<DatabaseUser> getOrCreateUser({
    required String email,
    bool setAsCurrentUser = true,
  }) async {
    try {
      final user = await getUser(email: email);
      if (setAsCurrentUser) {
        _user = user;
      }
      return user;
    } on CouldNotFindUser {
      final createdUser = await createUser(email: email);
      if (setAsCurrentUser) {
        _user = createdUser;
      }
      return createdUser;
    } catch (e) {
      rethrow;
    }
  }

  Database _getDatabaseOrThrow() {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpen();
    } else {
      return db;
    }
  }

  Future<void> _ensureDbIsOpen() async {
    try {
      await open();
    } on DatabaseAllReadOpenException {}
  }

  Future<void> open() async {
    if (_db != null) {
      throw DatabaseAllReadOpenException();
    }

    try {
      final docsPath = await getApplicationDocumentsDirectory();
      final dbPath = join(docsPath.path, dbName);
      final db = await openDatabase(dbPath);
      _db = db;

      await db.execute(createUserTable);
      await db.execute(createNoteTable);
      await _cacheNotes();
    } on MissingPlatformDirectoryException {
      throw UnableToGetDocumentDirectory();
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpen();
    } else {
      await db.close();
      _db = null;
    }
  }

// create user service
  Future<void> deleteUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    final deletedCount = await db.delete(
      userTable,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );

    if (deletedCount != 1) {
      throw CouldNotDeleteUser();
    }
  }

  Future<DatabaseUser> createUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final result = await db.query(
      userTable,
      limit: 1,
      where: "email = ?",
      whereArgs: [email.toLowerCase()],
    );

    if (result.isNotEmpty) {
      throw UserAlreadyExist();
    }

    final userId = await db.insert(
      userTable,
      {emailColumn: email.toLowerCase()},
    );

    return DatabaseUser(
      id: userId,
      email: email,
    );
  }

  Future<DatabaseUser> getUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    final result = await db.query(
      userTable,
      limit: 1,
      where: "email = ?",
      whereArgs: [email.toLowerCase()],
    );

    if (result.isEmpty) {
      throw CouldNotFindUser();
    } else {
      return DatabaseUser.fromRow(result.first);
    }
  }

// Note servcie

  Future<DatabaseNote> createNote({required DatabaseUser user}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    final dbUser = await getUser(email: user.email);

    if (dbUser != user) {
      throw CouldNotFindUser();
    }

    var text = '';

    final noteId = await db.insert(
      noteTable,
      {userIdColumn: user.id, textColumn: text, syncColumn: 1},
    );

    final note = DatabaseNote(
      id: noteId,
      userId: user.id,
      text: text,
      isSyncWithCloud: true,
    );

    _notes.add(note);
    _noteStreamController.add(_notes);

    return note;
  }

  Future<void> deleteNote({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      noteTable,
      where: " id = ? ",
      whereArgs: [id],
    );

    if (deletedCount == 0) {
      throw CouldNotDeleteNote();
    }

    _notes.removeWhere((element) => element.id == id);
    _noteStreamController.add(_notes);
  }

  Future<int> deleteAllNotes() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    final deleteCount = await db.delete(noteTable);
    _notes = [];
    _noteStreamController.add(_notes);
    return deleteCount;
  }

  Future<DatabaseNote> getNotes({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    final notes = await db.query(
      noteTable,
      limit: 1,
      where: " id = ? ",
      whereArgs: [id],
    );

    if (notes.isEmpty) {
      throw CouldNotFindNote();
    }

    final note = DatabaseNote.fromRow(notes.first);
    _notes.removeWhere((element) => element.id == id);
    _notes.add(note);
    _noteStreamController.add(_notes);

    return note;
  }

  Future<Iterable<DatabaseNote>> getAllNotes() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    final notes = await db.query(
      noteTable,
    );

    if (notes.isEmpty) {
      throw CouldNotFindNote();
    }

    return notes.map((e) => DatabaseNote.fromRow(e));
  }

  Future<DatabaseNote> updateNote({
    required DatabaseNote note,
    required String text,
  }) async {
    final db = _getDatabaseOrThrow();

    await getNotes(id: note.id);

    final updateCount = await db.update(
        noteTable,
        {
          textColumn: text,
          syncColumn: 0,
        },
        where: "id = ? ",
        whereArgs: [note.id]);

    if (updateCount == 0) {
      throw CouldNotUpdateNote();
    }

    final updatedNote = await getNotes(id: note.id);
    _notes.removeWhere((element) => element.id == updatedNote.id);
    _notes.add(updatedNote);
    _noteStreamController.add(_notes);

    return updatedNote;
  }
}

@immutable
class DatabaseUser {
  final int id;
  final String email;

  const DatabaseUser({
    required this.id,
    required this.email,
  });

  DatabaseUser.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        email = map[emailColumn] as String;

  @override
  String toString() {
    return 'Person {id: $id , email: $email}';
  }

  @override
  bool operator ==(covariant DatabaseUser other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class DatabaseNote {
  final int id;
  final int userId;
  final String text;
  final bool isSyncWithCloud;

  DatabaseNote({
    required this.id,
    required this.userId,
    required this.text,
    required this.isSyncWithCloud,
  });

  DatabaseNote.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        userId = map[userIdColumn] as int,
        text = map[textColumn] as String,
        isSyncWithCloud = (map[syncColumn] as int) == 1 ? true : false;

  @override
  String toString() {
    return "Note {id: $id, userId: $userId, "
        "text: ${text.substring(0, 10)}..., isSync: $isSyncWithCloud}";
  }

  @override
  bool operator ==(covariant DatabaseNote other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

const dbName = "notes.db";
const noteTable = "notes";
const userTable = "user";
const idColumn = "id";
const emailColumn = "email";
const userIdColumn = "user_id";
const textColumn = "text";
const syncColumn = "is_sync";
const createUserTable = ''' CREATE TABLE IF NOT EXISTS "user"  (
    	"id"	INTEGER NOT NULL,
	    "email"	TEXT NOT NULL UNIQUE,
	    PRIMARY KEY("id" AUTOINCREMENT));''';

const createNoteTable = '''CREATE TABLE IF NOT EXISTS "notes" (
	  "id"	INTEGER NOT NULL,
	  "user_id"	INTEGER,
	  "text"	TEXT,
	  "is_sync"	INTEGER DEFAULT 0,
	  PRIMARY KEY("id" AUTOINCREMENT),
	  FOREIGN KEY("user_id") REFERENCES "user"("id")
);''';
