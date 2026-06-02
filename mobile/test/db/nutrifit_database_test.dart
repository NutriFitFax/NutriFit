import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Database> _openInMemory() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, _) async {
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
        await db.execute('''
          CREATE TABLE water_logs (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            date       TEXT    NOT NULL,
            logged_at  INTEGER NOT NULL,
            amount_ml  INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE weight_logs (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            logged_at  INTEGER NOT NULL,
            weight_kg  REAL    NOT NULL
          )
        ''');
      },
    ),
  );
  return db;
}

void main() {
  late Database db;

  setUp(() async => db = await _openInMemory());
  tearDown(() async => db.close());

  group('meal_logs', () {
    test('insert and query by date', () async {
      await db.insert('meal_logs', {
        'date': '2024-01-15',
        'logged_at': 1705320000000,
        'name': 'Chicken',
        'calories': 250.0,
        'protein_g': 30.0,
        'carbs_g': 0.0,
        'fat_g': 5.0,
      });

      final rows = await db.query(
        'meal_logs',
        where: 'date = ?',
        whereArgs: ['2024-01-15'],
      );
      expect(rows, hasLength(1));
      expect(rows.first['name'], 'Chicken');
      expect(rows.first['calories'], 250.0);
    });

    test('query different date returns empty', () async {
      await db.insert('meal_logs', {
        'date': '2024-01-15',
        'logged_at': 1705320000000,
        'name': 'Salad',
        'calories': 100.0,
        'protein_g': 2.0,
        'carbs_g': 10.0,
        'fat_g': 1.0,
      });

      final rows = await db.query(
        'meal_logs',
        where: 'date = ?',
        whereArgs: ['2024-01-16'],
      );
      expect(rows, isEmpty);
    });

    test('delete removes specific row', () async {
      final id = await db.insert('meal_logs', {
        'date': '2024-01-15',
        'logged_at': 1705320000000,
        'name': 'Toast',
        'calories': 80.0,
        'protein_g': 3.0,
        'carbs_g': 15.0,
        'fat_g': 1.0,
      });

      await db.delete('meal_logs', where: 'id = ?', whereArgs: [id]);
      final rows = await db.query('meal_logs');
      expect(rows, isEmpty);
    });

    test('multiple meals on same date all returned', () async {
      for (final name in ['Breakfast', 'Lunch', 'Dinner']) {
        await db.insert('meal_logs', {
          'date': '2024-01-15',
          'logged_at': 1705320000000,
          'name': name,
          'calories': 500.0,
          'protein_g': 25.0,
          'carbs_g': 50.0,
          'fat_g': 15.0,
        });
      }
      final rows = await db.query('meal_logs', where: 'date = ?', whereArgs: ['2024-01-15']);
      expect(rows, hasLength(3));
    });
  });

  group('water_logs', () {
    test('insert and query by date', () async {
      await db.insert('water_logs', {
        'date': '2024-01-15',
        'logged_at': 1705320000000,
        'amount_ml': 500,
      });

      final rows = await db.query(
        'water_logs',
        where: 'date = ?',
        whereArgs: ['2024-01-15'],
      );
      expect(rows, hasLength(1));
      expect(rows.first['amount_ml'], 500);
    });

    test('delete by date clears entries', () async {
      await db.insert('water_logs', {
        'date': '2024-01-15',
        'logged_at': 1705320000000,
        'amount_ml': 250,
      });

      await db.delete('water_logs', where: 'date = ?', whereArgs: ['2024-01-15']);
      final rows = await db.query('water_logs');
      expect(rows, isEmpty);
    });
  });

  group('weight_logs', () {
    test('insert and query newest first', () async {
      await db.insert('weight_logs', {'logged_at': 1000, 'weight_kg': 70.0});
      await db.insert('weight_logs', {'logged_at': 2000, 'weight_kg': 71.5});

      final rows = await db.query('weight_logs', orderBy: 'logged_at DESC', limit: 8);
      expect(rows, hasLength(2));
      expect(rows.first['weight_kg'], 71.5); // newest first
    });

    test('limit respected', () async {
      for (int i = 0; i < 10; i++) {
        await db.insert('weight_logs', {
          'logged_at': i * 1000,
          'weight_kg': 70.0 + i,
        });
      }
      final rows = await db.query('weight_logs', orderBy: 'logged_at DESC', limit: 8);
      expect(rows, hasLength(8));
    });

    test('clear all weight logs', () async {
      await db.insert('weight_logs', {'logged_at': 1000, 'weight_kg': 70.0});
      await db.delete('weight_logs');
      final rows = await db.query('weight_logs');
      expect(rows, isEmpty);
    });
  });
}
