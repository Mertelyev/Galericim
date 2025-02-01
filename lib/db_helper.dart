import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'car.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    var path = join(await getDatabasesPath(), 'cars.db');
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      path = 'cars_web.db';
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cars (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        brand TEXT,
        model TEXT,
        year TEXT,
        price TEXT,
        addedDate TEXT,
        soldDate TEXT,
        isSold INTEGER
      )
    ''');
  }

  Future<void> insertCar(Car car) async {
    final db = await database;
    await db.insert('cars', car.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Car>> getCars() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('cars');
    return List.generate(maps.length, (i) {
      return Car.fromMap(maps[i]);
    });
  }

  Future<void> updateCar(Car car) async {
    final db = await database;
    await db.update('cars', car.toMap(), where: 'id = ?', whereArgs: [car.id]);
  }

  Future<void> deleteCar(int id) async {
    final db = await database;
    await db.delete('cars', where: 'id = ?', whereArgs: [id]);
  }
}
