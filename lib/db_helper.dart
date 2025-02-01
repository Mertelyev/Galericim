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
    try {
      var path = join(await getDatabasesPath(), 'cars.db');
      if (kIsWeb) {
        databaseFactory = databaseFactoryFfiWeb;
        path = 'cars_web.db';
      }
      debugPrint('Veritabanı yolu: $path');

      return await openDatabase(
        path,
        version: 1,
        onCreate: _createDB,
        onOpen: (db) {
          debugPrint('Veritabanı açıldı');
          _checkTableExists(db);
        },
      );
    } catch (e) {
      debugPrint('Veritabanı oluşturulurken hata: $e');
      rethrow;
    }
  }

  Future<void> _checkTableExists(Database db) async {
    try {
      var tables = await db.query('sqlite_master',
          where: 'type = ? AND name = ?', whereArgs: ['table', 'cars']);
      debugPrint('Tablolar: $tables');
    } catch (e) {
      debugPrint('Tablo kontrolünde hata: $e');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    try {
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
      debugPrint('Tablo oluşturuldu');
    } catch (e) {
      debugPrint('Tablo oluşturulurken hata: $e');
      rethrow;
    }
  }

  Future<void> insertCar(Car car) async {
    try {
      final db = await database;
      await db.insert('cars', car.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      debugPrint('Araç eklendi: ${car.brand} ${car.model}');
    } catch (e) {
      debugPrint('Araç eklenirken hata: $e');
      rethrow;
    }
  }

  Future<List<Car>> getCars() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('cars');
      debugPrint('Araçlar yüklendi: ${maps.length} adet');
      return List.generate(maps.length, (i) {
        return Car.fromMap(maps[i]);
      });
    } catch (e) {
      debugPrint('Araçlar yüklenirken hata: $e');
      rethrow;
    }
  }

  Future<void> updateCar(Car car) async {
    try {
      final db = await database;
      await db
          .update('cars', car.toMap(), where: 'id = ?', whereArgs: [car.id]);
      debugPrint('Araç güncellendi: ${car.brand} ${car.model}');
    } catch (e) {
      debugPrint('Araç güncellenirken hata: $e');
      rethrow;
    }
  }

  Future<void> deleteCar(int id) async {
    try {
      final db = await database;
      await db.delete('cars', where: 'id = ?', whereArgs: [id]);
      debugPrint('Araç silindi: $id');
    } catch (e) {
      debugPrint('Araç silinirken hata: $e');
      rethrow;
    }
  }
}
