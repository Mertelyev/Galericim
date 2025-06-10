import 'dart:convert';
import 'package:flutter/services.dart';
import '../car.dart';

class DataExportService {
  static const String _csvHeaders =
      'ID,Marka,Model,Paket,Yıl,Fiyat,Eklenme Tarihi,Satış Tarihi,Satıldı mı?,Hasar Kaydı,Açıklama,Müşteri Adı,Müşteri Şehri,Müşteri Telefonu,Müşteri TC No,Kilometre,Yakıt Tipi,Vites,Renk';

  /// Export cars data as CSV string
  static String exportToCsv(List<Car> cars) {
    final buffer = StringBuffer();
    buffer.writeln(_csvHeaders);

    for (final car in cars) {
      buffer.writeln(_carToCsvRow(car));
    }

    return buffer.toString();
  }

  /// Export cars data as JSON string
  static String exportToJson(List<Car> cars) {
    final List<Map<String, dynamic>> carsJson =
        cars.map((car) => car.toMap()).toList();

    final exportData = {
      'exported_at': DateTime.now().toIso8601String(),
      'total_cars': cars.length,
      'cars': carsJson,
    };

    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  /// Generate statistics summary as text
  static String generateStatisticsSummary(List<Car> cars) {
    final soldCars = cars.where((car) => car.isSold).toList();
    final totalCars = cars.length;
    final availableCars = totalCars - soldCars.length;

    // Brand distribution
    final Map<String, int> brandCount = {};
    for (final car in cars) {
      brandCount[car.brand] = (brandCount[car.brand] ?? 0) + 1;
    }

    // Fuel type distribution (sold cars only)
    final Map<String, int> fuelTypeCount = {};
    for (final car in soldCars) {
      if (car.fuelType != null && car.fuelType!.isNotEmpty) {
        fuelTypeCount[car.fuelType!] = (fuelTypeCount[car.fuelType!] ?? 0) + 1;
      }
    }

    // Average price of sold cars
    double averagePrice = 0;
    if (soldCars.isNotEmpty) {
      final totalPrice = soldCars.fold<double>(
        0,
        (sum, car) =>
            sum + (double.tryParse(car.price.replaceAll(',', '')) ?? 0),
      );
      averagePrice = totalPrice / soldCars.length;
    }

    final buffer = StringBuffer();
    buffer.writeln('GALERICIM - İSTATISTIK RAPORU');
    buffer.writeln('=' * 40);
    buffer.writeln(
        'Rapor Tarihi: ${DateTime.now().toLocal().toString().split('.')[0]}');
    buffer.writeln();

    buffer.writeln('GENEL İSTATISTIKLER');
    buffer.writeln('-' * 20);
    buffer.writeln('Toplam Araç: $totalCars');
    buffer.writeln('Satılan Araç: ${soldCars.length}');
    buffer.writeln('Mevcut Araç: $availableCars');
    buffer.writeln(
        'Satış Oranı: ${totalCars > 0 ? ((soldCars.length / totalCars) * 100).toStringAsFixed(1) : '0'}%');
    buffer.writeln();

    if (soldCars.isNotEmpty) {
      buffer.writeln('SATIŞ İSTATISTIKLERİ');
      buffer.writeln('-' * 20);
      buffer.writeln(
          'Ortalama Satış Fiyatı: ${averagePrice.toStringAsFixed(0)} TL');
      buffer.writeln();
    }

    if (brandCount.isNotEmpty) {
      buffer.writeln('MARKA DAĞILIMI');
      buffer.writeln('-' * 15);
      final sortedBrands = brandCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      for (final entry in sortedBrands) {
        final percentage = totalCars > 0
            ? (entry.value / totalCars * 100).toStringAsFixed(1)
            : '0';
        buffer.writeln('${entry.key}: ${entry.value} araç (%$percentage)');
      }
      buffer.writeln();
    }

    if (fuelTypeCount.isNotEmpty) {
      buffer.writeln('YAKITA TIPO DAĞILIMI (Satılan Araçlar)');
      buffer.writeln('-' * 35);
      final sortedFuelTypes = fuelTypeCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      for (final entry in sortedFuelTypes) {
        final percentage = soldCars.isNotEmpty
            ? (entry.value / soldCars.length * 100).toStringAsFixed(1)
            : '0';
        buffer.writeln('${entry.key}: ${entry.value} araç (%$percentage)');
      }
    }

    return buffer.toString();
  }

  /// Copy text to clipboard
  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Generate car detail report
  static String generateCarDetailReport(Car car) {
    final buffer = StringBuffer();
    buffer.writeln('ARAÇ DETAY RAPORU');
    buffer.writeln('=' * 25);
    buffer.writeln(
        'Rapor Tarihi: ${DateTime.now().toLocal().toString().split('.')[0]}');
    buffer.writeln();

    buffer.writeln('ARAÇ BİLGİLERİ');
    buffer.writeln('-' * 15);
    buffer.writeln('Marka: ${car.brand}');
    buffer.writeln('Model: ${car.model}');
    if (car.package != null && car.package!.isNotEmpty) {
      buffer.writeln('Paket: ${car.package}');
    }
    buffer.writeln('Yıl: ${car.year}');
    buffer.writeln('Fiyat: ${car.price} TL');
    if (car.kilometers != null && car.kilometers!.isNotEmpty) {
      buffer.writeln('Kilometre: ${car.kilometers}');
    }
    if (car.fuelType != null && car.fuelType!.isNotEmpty) {
      buffer.writeln('Yakıt Tipi: ${car.fuelType}');
    }
    if (car.transmission != null && car.transmission!.isNotEmpty) {
      buffer.writeln('Vites: ${car.transmission}');
    }
    if (car.color != null && car.color!.isNotEmpty) {
      buffer.writeln('Renk: ${car.color}');
    }
    buffer.writeln('Hasar Kaydı: ${car.damageRecord}');
    buffer.writeln('Eklenme Tarihi: ${_formatDate(car.addedDate)}');
    buffer.writeln();

    buffer.writeln('SATIŞ DURUMU');
    buffer.writeln('-' * 15);
    buffer.writeln('Satış Durumu: ${car.isSold ? "Satıldı" : "Mevcut"}');
    if (car.isSold && car.soldDate != null) {
      buffer.writeln('Satış Tarihi: ${_formatDate(car.soldDate!)}');
    }
    buffer.writeln();

    if (car.customerName != null && car.customerName!.isNotEmpty) {
      buffer.writeln('MÜŞTERİ BİLGİLERİ');
      buffer.writeln('-' * 15);
      buffer.writeln('Müşteri Adı: ${car.customerName}');
      if (car.customerCity != null && car.customerCity!.isNotEmpty) {
        buffer.writeln('Şehir: ${car.customerCity}');
      }
      if (car.customerPhone != null && car.customerPhone!.isNotEmpty) {
        buffer.writeln('Telefon: ${car.customerPhone}');
      }
      if (car.customerTcNo != null && car.customerTcNo!.isNotEmpty) {
        buffer.writeln('TC No: ${car.customerTcNo}');
      }
      buffer.writeln();
    }

    if (car.description != null && car.description!.isNotEmpty) {
      buffer.writeln('AÇIKLAMA');
      buffer.writeln('-' * 10);
      buffer.writeln(car.description);
    }

    return buffer.toString();
  }

  static String _carToCsvRow(Car car) {
    return [
      car.id?.toString() ?? '',
      _escapeCsv(car.brand),
      _escapeCsv(car.model),
      _escapeCsv(car.package ?? ''),
      car.year.toString(),
      _escapeCsv(car.price),
      _formatDate(car.addedDate),
      car.soldDate != null ? _formatDate(car.soldDate!) : '',
      car.isSold ? 'Evet' : 'Hayır',
      _escapeCsv(car.damageRecord.isEmpty ? '' : car.damageRecord),
      _escapeCsv(car.description ?? ''),
      _escapeCsv(car.customerName ?? ''),
      _escapeCsv(car.customerCity ?? ''),
      _escapeCsv(car.customerPhone ?? ''),
      _escapeCsv(car.customerTcNo ?? ''),
      _escapeCsv(car.kilometers ?? ''),
      _escapeCsv(car.fuelType ?? ''),
      _escapeCsv(car.transmission ?? ''),
      _escapeCsv(car.color ?? ''),
    ].join(',');
  }

  static String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }
}
