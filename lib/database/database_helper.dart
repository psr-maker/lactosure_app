import 'package:lactosure_connect_app/models/correction_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB("correction.db");
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();

    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE corrections(
      id INTEGER PRIMARY KEY AUTOINCREMENT,

      correctionType TEXT NOT NULL,

      societyId TEXT,
      machineId TEXT,
      machineType TEXT,

      channel TEXT NOT NULL,

      fat REAL,
      snf REAL,
      clr REAL,
      protein REAL,
      temp REAL,
      water REAL,

      createdAt TEXT NOT NULL,

      synced INTEGER NOT NULL DEFAULT 0
    )
  ''');
  }

  Future<int> insertCorrection(CorrectionModel correction) async {
    final db = await database;

    return await db.insert(
      "corrections",
      correction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CorrectionModel>> getCorrections() async {
    final db = await database;

    final result = await db.query("corrections", orderBy: "id DESC");

    return result.map((e) => CorrectionModel.fromMap(e)).toList();
  }

  Future<List<CorrectionModel>> getPendingCorrections() async {
    final db = await database;

    final result = await db.query(
      "corrections",
      where: "synced = ?",
      whereArgs: [0],
    );

    return result.map((e) => CorrectionModel.fromMap(e)).toList();
  }

  Future<void> markAsSynced(int id) async {
    final db = await database;

    await db.update(
      "corrections",
      {"synced": 1},
      where: "id = ?",
      whereArgs: [id],
    );
  }

  Future<void> clearCorrections() async {
    final db = await database;

    await db.delete("corrections");
  }
  Future<void> deleteCorrection(int id) async {
  final db = await database;

  await db.delete(
    "corrections",
    where: "id = ?",
    whereArgs: [id],
  );
}
}
