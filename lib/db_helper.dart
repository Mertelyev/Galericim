import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'car.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DBHelper {
  static const int _latestVersion = 5; // Version increased
  static const String _tableName = 'cars';

  // Veritabanı şema değişikliklerini takip eden map
  static final Map<int, List<String>> _migrations = {
    1: [
      '''CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        brand TEXT NOT NULL,
        model TEXT NOT NULL,
        year TEXT NOT NULL,
        price TEXT NOT NULL,
        addedDate TEXT NOT NULL,
        soldDate TEXT,
        isSold INTEGER NOT NULL DEFAULT 0
      )'''
    ],
    2: [
      'ALTER TABLE $_tableName ADD COLUMN damageRecord TEXT NOT NULL DEFAULT "0"'
    ],
    3: ['ALTER TABLE $_tableName ADD COLUMN description TEXT'],
    4: ['ALTER TABLE cars ADD COLUMN package TEXT'],
    5: [
      '''ALTER TABLE cars ADD COLUMN customerName TEXT''',
      '''ALTER TABLE cars ADD COLUMN customerCity TEXT''',
      '''ALTER TABLE cars ADD COLUMN customerPhone TEXT''',
      '''ALTER TABLE cars ADD COLUMN customerTcNo TEXT''',
    ],
  };

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

      return await openDatabase(
        path,
        version: _latestVersion,
        onCreate: _createDB,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      debugPrint('Veritabanı başlatılırken hata: $e');
      rethrow;
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // En baştan en son versiyona kadar tüm migrasyonları uygula
    for (int i = 1; i <= version; i++) {
      if (_migrations.containsKey(i)) {
        for (String query in _migrations[i]!) {
          await db.execute(query);
        }
      }
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Sadece gerekli migrasyonları uygula
    for (int i = oldVersion + 1; i <= newVersion; i++) {
      if (_migrations.containsKey(i)) {
        debugPrint('Versiyon $i için migrasyon uygulanıyor...');
        for (String query in _migrations[i]!) {
          try {
            await db.execute(query);
            debugPrint('Başarılı: $query');
          } catch (e) {
            debugPrint('Migrasyon hatası (v$i): $e');
            // Kritik kolonlar için hata fırlat, diğerlerini görmezden gel
            if (query.contains('NOT NULL') && !query.contains('DEFAULT')) {
              rethrow;
            }
          }
        }
      }
    }
  }

  // Veritabanı sürümünü kontrol etmek için yardımcı metod
  Future<void> checkDatabaseVersion() async {
    final db = await database;
    final version = await db.getVersion();
    debugPrint('Mevcut veritabanı sürümü: $version');
    debugPrint('En son veritabanı sürümü: $_latestVersion');
  }

  Future<void> insertCar(Car car) async {
    final db = await database;
    final id = await db.insert(
      'cars',
      car.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // ID'yi kontrol et
    if (id <= 0) {
      throw Exception('Araç eklenirken hata oluştu');
    }
  }

  Future<List<Car>> getCars() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cars',
      orderBy: 'addedDate DESC',
    );

    return List.generate(maps.length, (i) {
      try {
        return Car.fromMap(maps[i]);
      } catch (e) {
        throw Exception('Araç verisi dönüştürülürken hata: ${maps[i]}');
      }
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
