import 'services/logging_service.dart';

class Car {
  static final _logger = LoggingService();
  
  final int? id;
  final String brand;
  final String model;
  final String? package; // Yeni eklenen paket bilgisi
  final String year;
  final String price;
  final DateTime addedDate;
  DateTime? soldDate;
  bool isSold;
  final String damageRecord;
  final String? description;
  final String? customerName;
  final String? customerCity;
  final String? customerPhone;
  final String? customerTcNo;
  final String? kilometers;
  final String? fuelType;
  final String? transmission;
  final String? color;
  final DateTime lastModifiedDate;

  Car({
    this.id,
    required this.brand,
    required this.model,
    this.package, // Opsiyonel paket bilgisi
    required this.year,
    required this.price,
    required this.addedDate,
    this.soldDate,
    this.isSold = false,
    this.damageRecord = '0',
    this.description,
    this.customerName,
    this.customerCity,
    this.customerPhone,
    this.customerTcNo,
    this.kilometers,
    this.fuelType,
    this.transmission,
    this.color,
    DateTime? lastModifiedDate,
  }) : lastModifiedDate = lastModifiedDate ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'brand': brand,
      'model': model,
      'package': package,
      'year': year,
      'price': price,
      'addedDate': addedDate.toIso8601String(),
      'soldDate': soldDate?.toIso8601String(),
      'isSold': isSold ? 1 : 0,
      'damageRecord': damageRecord,
      'description': description,
      'customerName': customerName,
      'customerCity': customerCity,
      'customerPhone': customerPhone,
      'customerTcNo': customerTcNo,
      'kilometers': kilometers,
      'fuelType': fuelType,
      'transmission': transmission,
      'color': color,
      'lastModifiedDate': lastModifiedDate.toIso8601String(),
    };
  }

  factory Car.fromMap(Map<String, dynamic> map) {
    return Car(
      id: map['id'],
      brand: map['brand'],
      model: map['model'],
      package: map['package'],
      year: map['year'],
      price: map['price'],
      addedDate: DateTime.parse(map['addedDate']),
      soldDate:
          map['soldDate'] != null ? DateTime.parse(map['soldDate']) : null,
      isSold: map['isSold'] == 1,
      damageRecord: map['damageRecord']?.toString() ?? '0',
      description: map['description'],
      customerName: map['customerName'],
      customerCity: map['customerCity'],
      customerPhone: map['customerPhone'],
      customerTcNo: map['customerTcNo'],
      kilometers: map['kilometers'],
      fuelType: map['fuelType'],
      transmission: map['transmission'],
      color: map['color'],
      lastModifiedDate: map['lastModifiedDate'] != null
          ? DateTime.parse(map['lastModifiedDate'])
          : null,
    );
  }
  void markAsSold() {
    if (!isSold) {
      isSold = true;
      soldDate = DateTime.now();
      _logger.info('Car marked as sold', tag: 'Car', data: {
        'carId': id,
        'brand': brand,
        'model': model,
        'soldDate': soldDate?.toIso8601String(),
      });
    }
  }

  void markAsUnsold() {
    if (isSold) {
      isSold = false;
      soldDate = null;
      _logger.info('Car marked as unsold', tag: 'Car', data: {
        'carId': id,
        'brand': brand,
        'model': model,
      });
    }
  }
}
