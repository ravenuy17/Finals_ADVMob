import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'gestures.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE gestures(id INTEGER PRIMARY KEY, label TEXT, imagePath TEXT)',
        );
      },
    );
  }

  // Insert label and image path into the database
  Future<void> insertLabel(String label, String imagePath) async {
    final db = await database;

    await db.insert(
      'gestures',
      {'label': label, 'imagePath': imagePath},
      conflictAlgorithm:
          ConflictAlgorithm.replace, // Replace if label already exists
    );
  }
}
