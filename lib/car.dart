class Car {
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
  });

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
    );
  }

  void markAsSold() {
    if (!isSold) {
      isSold = true;
      soldDate = DateTime.now();
    }
  }

  void markAsUnsold() {
    if (isSold) {
      isSold = false;
      soldDate = null;
    }
  }
}
