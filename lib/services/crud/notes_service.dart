/* import 'dart:async';

import 'package:mynotesflutter/extenstions/filter.dart';
import 'package:mynotesflutter/services/crud/crud_exceptions.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' show join;
class NotesService {
  Database? _db;
  List<DatabaseNOtes> _notes = [];
  DatabaseUser?_user;
  static final NotesService _shared = NotesService._sharedInstance();
  NotesService._sharedInstance(){
   _notesStreamController = StreamController<List<DatabaseNOtes>>.broadcast(
    onListen: (){
      _notesStreamController.sink.add(_notes);
    }
   );
  }
  factory NotesService() => _shared;
  late final  StreamController<List<DatabaseNOtes>> _notesStreamController;
  Stream<List<DatabaseNOtes>> get allNotes =>
    _notesStreamController.stream.filter((note) {
      final currentUser = _user;
      if (currentUser != null) {
        return note.userId == currentUser.id;
      } else {
        throw UserShouldBeSetBeforeReadingAllNotes();
      }
    });
  Future<void> _cacheNotes() async {
    final allNotes = await getallnotes();
    _notes = allNotes.toList();
    _notesStreamController.add(_notes);
  }
  Future<void>_ensureDbISOpen()async{
    try{
      await open();
    }on DatabaseAlreadyOpenException{
      // Database already open, no action needed
    }
  }
  Future<DatabaseNOtes>upDateNote({required DatabaseNOtes note, required String text}) async {
    await _ensureDbISOpen();
    final db = _getDatabaseOrThrow();
    final updateCount = await db.update(
      notesTable,
      {textColumn: text, isSyncedWithCloudColumn: 0},
      where: 'id = ?',
      whereArgs: [note.id],
    );
    if (updateCount == 0) {
      throw CouldNotUpdateNoteException();
    }else{
      final updatedNote = await getnotes(id: note.id);
      _notes.removeWhere((note) => note.id == updatedNote.id);
      _notes.add(updatedNote);
      _notesStreamController.add(_notes);
      return updatedNote;
    }
  }
Future<List<DatabaseNOtes>>getallnotes() async {
  await _ensureDbISOpen();
  final db = _getDatabaseOrThrow();
  final notes = await db.query(notesTable);
  return notes.map((noteRow) => DatabaseNOtes.fromRow(noteRow)).toList();
}
  Future<DatabaseNOtes>getnotes({required int id}) async {
    await _ensureDbISOpen();
    final db = _getDatabaseOrThrow();
    final notes = await db.query(
      notesTable,
      limit: 1,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (notes.isEmpty) {
      throw CouldNotFindNoteException();
    } else {
      final note = DatabaseNOtes.fromRow(notes.first);
      _notes.removeWhere((note) => note.id == id);
      _notes.add(note);
      _notesStreamController.add(_notes);
      return note;
    }
  }
  Future<void>deleteAllUsers() async {
    await _ensureDbISOpen();
    final db = _getDatabaseOrThrow();
    await db.delete(notesTable);
  }
  Future<void> deleteNote({required int id}) async {
   await _ensureDbISOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      notesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (deletedCount != 1) {
      throw CouldNotDeleteNoteException();
    }else{
      _notes.removeWhere((note) => note.id == id);
      _notesStreamController.add(_notes);
    }
  }
  Future<DatabaseNOtes> createNote({required DatabaseUser owner, required String text}) async {
   await _ensureDbISOpen();
    final db = _getDatabaseOrThrow();
    final dbUser = await getOrCreateUser(email: owner.email);
    if(dbUser != owner){
      throw CouldNotFindUserException();
    }
    final noteId = await db.insert(notesTable, {
      userIdColumn: owner.id,
      textColumn: text,
      isSyncedWithCloudColumn: 1,
    });
    final note = DatabaseNOtes(
      id: noteId,
      userId: owner.id,
      text: text,
      isSyncedWithCloud: true,
    );
    _notes.add(note); 
    _notesStreamController.add(_notes);
    return note;
  }

  Future<DatabaseUser> getUser({required String email}) async {
   await _ensureDbISOpen();
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      usersTable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (results.isEmpty) {
      throw CouldNotFindUserException();
    }else{
      return DatabaseUser.fromRow(results.first);
    }
  }
  Future<DatabaseUser>getOrCreateUser({
    required String email,
    bool setAsCurrentUser = true,
    }
    )async{
    await _ensureDbISOpen();
    try{
      final user = await getUser(email: email);
      if(setAsCurrentUser){
        _user = user;
        _notesStreamController.add(_notes);
      }
      return user;
    }on CouldNotFindUserException{
      final createdUser = await createUser(email: email);
       if(setAsCurrentUser){
        _user = createdUser;
        _notesStreamController.add(_notes);
      }
      return createdUser;
    }catch(e){
      rethrow;
    }
  }
  Future<DatabaseUser> createUser({required String email}) async {
    await _ensureDbISOpen();
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      usersTable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (results.isNotEmpty) {
      throw UserAlreadyExistsException();
    }
    db.insert(usersTable, {
      emailColumn: email.toLowerCase(),
      });
    final userId = await db.insert(usersTable, {emailColumn: email.toLowerCase()});
    return DatabaseUser(id: userId, email: email);
  }

  Future <void> deleteAllNotes() async {
    await _ensureDbISOpen();
    final db = _getDatabaseOrThrow();
    final numberOfDeletions = await db.delete(notesTable);
    _notes = [];
    _notesStreamController.add(_notes);
  }

  Database _getDatabaseOrThrow() {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpenException();
    } else {
      return db;
    }
  }

  Future<void> open() async {
    if (_db != null) {
      throw DatabaseAlreadyOpenException();
    }

    try {
      final dbsPath = await getDatabasesPath();
      final dbPath = join(dbsPath, dbName);
      final db = await openDatabase(dbPath);
      _db = db;
      await db.execute(createUsersTable);
      await db.execute(createNotesTable);
      await _cacheNotes();
    } on MissingDataException {
      throw UnableToGetDocumentsDirectoryException();
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpenException();
    }

    await db.close();
    _db = null;
  }
}
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
  String toString() => 'Person, ID = $id, email = $email';
  @override
  bool operator ==(covariant DatabaseUser other) => id == other.id;
  @override
  int get hashCode => id.hashCode;
}
class DatabaseNOtes{
  final int id;
  final int userId;
  final String text;
  final bool isSyncedWithCloud;

  DatabaseNOtes({required this.id, required this.userId, required this.text, required this.isSyncedWithCloud});

    DatabaseNOtes.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        userId = map[userIdColumn] as int,
        text = map[textColumn] as String,
        isSyncedWithCloud = map[isSyncedWithCloudColumn] as int == 1 ? true : false;
  @override
  String toString() => 'Note, ID = $id, userId = $userId, text = $text, isSyncedWithCloud = $isSyncedWithCloud';
   @override
  bool operator ==(covariant DatabaseNOtes other) => id == other.id;
  @override
  int get hashCode => id.hashCode;
}
const dbName = 'mynotes.db';
const dbVersion = 1;
const usersTable = 'users';
const notesTable = 'notes';
const idColumn = 'id';
const emailColumn = 'email';
const userIdColumn = 'user_id';
const textColumn = 'text';
const isSyncedWithCloudColumn = 'is_synced_with_cloud';
const createUsersTable = '''CREATE TABLE IF NOT EXISTS $usersTable(
      $idColumn INTEGER PRIMARY KEY AUTOINCREMENT,
      $emailColumn TEXT NOT NULL UNIQUE
    )''';
 const createNotesTable = '''CREATE TABLE IF NOT EXISTS $notesTable(
      $idColumn INTEGER PRIMARY KEY AUTOINCREMENT,
      $userIdColumn INTEGER NOT NULL,
      $textColumn TEXT NOT NULL,
      $isSyncedWithCloudColumn INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY($userIdColumn) REFERENCES $usersTable($idColumn)
    )''';
 */