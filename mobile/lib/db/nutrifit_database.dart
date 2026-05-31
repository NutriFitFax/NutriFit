import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class NutrifitDatabase {
  NutrifitDatabase._();

  static Database? _db;

  static Future<Database> open() async {
    _db ??= await openDatabase(
      join(await getDatabasesPath(), 'nutrifit_v1.db'),
      version: 1,
      onCreate: _create,
    );
    return _db!;
  }

  static Future<void> _create(Database db, int _) async {
    await db.execute('''
      CREATE TABLE meal_logs (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        date       TEXT    NOT NULL,
        logged_at  INTEGER NOT NULL,
        name       TEXT    NOT NULL,
        calories   REAL    NOT NULL,
        protein_g  REAL    NOT NULL DEFAULT 0,
        carbs_g    REAL    NOT NULL DEFAULT 0,
        fat_g      REAL    NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('CREATE INDEX idx_meal_date ON meal_logs(date)');

    await db.execute('''
      CREATE TABLE water_logs (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        date       TEXT    NOT NULL,
        logged_at  INTEGER NOT NULL,
        amount_ml  INTEGER NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_water_date ON water_logs(date)');

    await db.execute('''
      CREATE TABLE weight_logs (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        logged_at  INTEGER NOT NULL,
        weight_kg  REAL    NOT NULL
      )
    ''');
  }
}
