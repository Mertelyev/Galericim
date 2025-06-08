import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import '../car.dart';
import '../db_helper.dart';
import 'logging_service.dart';

class BackupService {
  static final _logger = LoggingService();
  static const String backupFileName = 'galericim_backup.json';

  /// Creates a backup of all car data
  static Future<Map<String, dynamic>> createBackup() async {
    try {
      _logger.info('Creating backup', tag: 'Backup');
      
      final dbHelper = DBHelper();
      final cars = await dbHelper.getCars();
      
      final backup = {
        'version': '1.0.0',
        'timestamp': DateTime.now().toIso8601String(),
        'totalCars': cars.length,
        'data': {
          'cars': cars.map((car) => car.toMap()).toList(),
        },
        'metadata': {
          'appVersion': '1.0.0',
          'platform': Platform.operatingSystem,
          'createdBy': 'Galericim App',
        }
      };
      
      _logger.info('Backup created successfully', tag: 'Backup', data: {
        'totalCars': cars.length,
        'timestamp': backup['timestamp'],
      });
      
      return backup;
    } catch (e, stackTrace) {
      _logger.error('Failed to create backup', tag: 'Backup', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Exports backup data as JSON string
  static Future<String> exportBackupAsJson() async {
    try {
      final backup = await createBackup();
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(backup);
    } catch (e, stackTrace) {
      _logger.error('Failed to export backup as JSON', tag: 'Backup', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Copies backup to clipboard
  static Future<void> copyBackupToClipboard() async {
    try {
      final jsonString = await exportBackupAsJson();
      await Clipboard.setData(ClipboardData(text: jsonString));
      _logger.info('Backup copied to clipboard', tag: 'Backup');
    } catch (e, stackTrace) {
      _logger.error('Failed to copy backup to clipboard', tag: 'Backup', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Validates backup data structure
  static bool validateBackupData(Map<String, dynamic> backupData) {
    try {
      // Check required fields
      if (!backupData.containsKey('version') ||
          !backupData.containsKey('timestamp') ||
          !backupData.containsKey('data') ||
          !backupData.containsKey('totalCars')) {
        _logger.warning('Backup validation failed: Missing required fields', tag: 'Backup');
        return false;
      }

      final data = backupData['data'] as Map<String, dynamic>?;
      if (data == null || !data.containsKey('cars')) {
        _logger.warning('Backup validation failed: Missing cars data', tag: 'Backup');
        return false;
      }

      final cars = data['cars'] as List?;
      if (cars == null) {
        _logger.warning('Backup validation failed: Cars data is not a list', tag: 'Backup');
        return false;
      }

      // Validate each car data structure
      for (final carData in cars) {
        if (carData is! Map<String, dynamic>) {
          _logger.warning('Backup validation failed: Invalid car data structure', tag: 'Backup');
          return false;
        }

        // Check required car fields
        final requiredFields = ['brand', 'model', 'year', 'price', 'addedDate'];
        for (final field in requiredFields) {
          if (!carData.containsKey(field)) {
            _logger.warning('Backup validation failed: Missing car field: $field', tag: 'Backup');
            return false;
          }
        }
      }

      _logger.info('Backup validation successful', tag: 'Backup', data: {
        'totalCars': cars.length,
        'version': backupData['version'],
      });
      
      return true;
    } catch (e, stackTrace) {
      _logger.error('Backup validation error', tag: 'Backup', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Restores data from backup
  static Future<RestoreResult> restoreFromBackup(
    Map<String, dynamic> backupData, {
    RestoreMode mode = RestoreMode.merge,
  }) async {
    try {
      _logger.info('Starting restore from backup', tag: 'Backup', data: {
        'mode': mode.toString(),
      });

      if (!validateBackupData(backupData)) {
        throw const BackupException('Invalid backup data structure');
      }

      final dbHelper = DBHelper();
      final data = backupData['data'] as Map<String, dynamic>;
      final carsData = data['cars'] as List;
      
      int restoredCount = 0;
      int skippedCount = 0;
      int errorCount = 0;
      List<String> errors = [];

      // If replace mode, clear existing data
      if (mode == RestoreMode.replace) {
        _logger.info('Clearing existing data for replace mode', tag: 'Backup');
        final existingCars = await dbHelper.getCars();
        for (final car in existingCars) {
          await dbHelper.deleteCar(car.id!);
        }
      }

      // Restore cars
      for (final carData in carsData) {
        try {
          final car = Car.fromMap(carData as Map<String, dynamic>);
          
          if (mode == RestoreMode.merge) {
            // Check if car already exists (by brand, model, year combination)
            final existingCars = await dbHelper.getCars();
            final exists = existingCars.any((existing) =>
                existing.brand == car.brand &&
                existing.model == car.model &&
                existing.year == car.year &&
                existing.addedDate.isAtSameMomentAs(car.addedDate));
            
            if (exists) {
              skippedCount++;
              continue;
            }
          }

          // Create new car without ID for insertion
          final newCar = Car(
            brand: car.brand,
            model: car.model,
            package: car.package,
            year: car.year,
            price: car.price,
            addedDate: car.addedDate,
            soldDate: car.soldDate,
            isSold: car.isSold,
            damageRecord: car.damageRecord,
            description: car.description,
            customerName: car.customerName,
            customerCity: car.customerCity,
            customerPhone: car.customerPhone,
            customerTcNo: car.customerTcNo,
            kilometers: car.kilometers,
            fuelType: car.fuelType,
            transmission: car.transmission,
            color: car.color,
          );

          await dbHelper.insertCar(newCar);
          restoredCount++;
        } catch (e) {
          errorCount++;        errors.add('Failed to restore car: $e');
          _logger.warning('Failed to restore individual car', tag: 'Backup', data: {'error': e.toString()});
        }
      }

      final result = RestoreResult(
        success: true,
        restoredCount: restoredCount,
        skippedCount: skippedCount,
        errorCount: errorCount,
        errors: errors,
        totalProcessed: carsData.length,
      );

      _logger.info('Restore completed', tag: 'Backup', data: {
        'restoredCount': restoredCount,
        'skippedCount': skippedCount,
        'errorCount': errorCount,
        'totalProcessed': carsData.length,
      });

      return result;
    } catch (e, stackTrace) {
      _logger.error('Restore failed', tag: 'Backup', error: e, stackTrace: stackTrace);
      
      return RestoreResult(
        success: false,
        restoredCount: 0,
        skippedCount: 0,
        errorCount: 1,
        errors: ['Restore failed: $e'],
        totalProcessed: 0,
      );
    }
  }

  /// Restores from JSON string
  static Future<RestoreResult> restoreFromJson(
    String jsonString, {
    RestoreMode mode = RestoreMode.merge,
  }) async {
    try {
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;
      return await restoreFromBackup(backupData, mode: mode);
    } catch (e, stackTrace) {
      _logger.error('Failed to parse backup JSON', tag: 'Backup', error: e, stackTrace: stackTrace);
      
      return RestoreResult(
        success: false,
        restoredCount: 0,
        skippedCount: 0,
        errorCount: 1,
        errors: ['Failed to parse backup JSON: $e'],
        totalProcessed: 0,
      );
    }
  }

  /// Gets backup metadata without processing the full backup
  static Map<String, dynamic>? getBackupMetadata(String jsonString) {
    try {
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      return {
        'version': backupData['version'],
        'timestamp': backupData['timestamp'],
        'totalCars': backupData['totalCars'],
        'metadata': backupData['metadata'],
      };    } catch (e) {
      _logger.warning('Failed to get backup metadata', tag: 'Backup', data: {'error': e.toString()});
      return null;
    }
  }

  /// Creates an automated backup with timestamp
  static Future<String> createTimestampedBackup() async {
    try {
      final backup = await createBackup();
      final timestamp = DateTime.now();
      final filename = 'galericim_backup_${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}_${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}.json';
      
      const encoder = JsonEncoder.withIndent('  ');
      final jsonString = encoder.convert(backup);
      
      _logger.info('Created timestamped backup', tag: 'Backup', data: {
        'filename': filename,
        'size': jsonString.length,
      });
      
      return jsonString;
    } catch (e, stackTrace) {
      _logger.error('Failed to create timestamped backup', tag: 'Backup', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}

enum RestoreMode {
  merge,     // Add new cars, skip existing ones
  replace,   // Clear all data and restore from backup
}

class RestoreResult {
  final bool success;
  final int restoredCount;
  final int skippedCount;
  final int errorCount;
  final List<String> errors;
  final int totalProcessed;

  const RestoreResult({
    required this.success,
    required this.restoredCount,
    required this.skippedCount,
    required this.errorCount,
    required this.errors,
    required this.totalProcessed,
  });

  String get summary {
    if (!success) {
      return 'Yedekleme geri yükleme başarısız: ${errors.first}';
    }
    
    String summary = '$restoredCount araç başarıyla geri yüklendi';
    
    if (skippedCount > 0) {
      summary += ', $skippedCount araç zaten mevcut (atlandı)';
    }
    
    if (errorCount > 0) {
      summary += ', $errorCount hata oluştu';
    }
    
    return summary;
  }
}

class BackupException implements Exception {
  final String message;
  
  const BackupException(this.message);
  
  @override
  String toString() => 'BackupException: $message';
}
