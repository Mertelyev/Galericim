import 'package:flutter_test/flutter_test.dart';
import 'package:galericim/car.dart';

void main() {
  group('Car Model Tests', () {
    test('Car should be created with required fields', () {
      final car = Car(
        brand: 'BMW',
        model: 'X5',
        year: '2020',
        price: '750000',
        addedDate: DateTime.now(),
      );

      expect(car.brand, 'BMW');
      expect(car.model, 'X5');
      expect(car.year, '2020');
      expect(car.price, '750000');
      expect(car.isSold, false);
      expect(car.damageRecord, '0');
    });

    test('Car should convert to and from Map correctly', () {
      final originalCar = Car(
        id: 1,
        brand: 'Mercedes',
        model: 'C180',
        year: '2019',
        price: '650000',
        addedDate: DateTime(2023, 1, 15),
        damageRecord: '15000',
        description: 'Temiz araç',
        kilometers: '125000',
        fuelType: 'Benzin',
      );

      final map = originalCar.toMap();
      final recreatedCar = Car.fromMap(map);

      expect(recreatedCar.id, originalCar.id);
      expect(recreatedCar.brand, originalCar.brand);
      expect(recreatedCar.model, originalCar.model);
      expect(recreatedCar.year, originalCar.year);
      expect(recreatedCar.price, originalCar.price);
      expect(recreatedCar.damageRecord, originalCar.damageRecord);
      expect(recreatedCar.description, originalCar.description);
      expect(recreatedCar.kilometers, originalCar.kilometers);
      expect(recreatedCar.fuelType, originalCar.fuelType);
    });

    test('Car should handle sold status correctly', () {
      final car = Car(
        brand: 'Audi',
        model: 'A4',
        year: '2021',
        price: '850000',
        addedDate: DateTime.now(),
      );

      expect(car.isSold, false);
      expect(car.soldDate, null);

      car.markAsSold();
      expect(car.isSold, true);
      expect(car.soldDate, isNotNull);

      car.markAsUnsold();
      expect(car.isSold, false);
      expect(car.soldDate, null);
    });

    test('Car should handle damage record correctly', () {
      final carWithoutDamage = Car(
        brand: 'Toyota',
        model: 'Corolla',
        year: '2022',
        price: '450000',
        addedDate: DateTime.now(),
      );

      expect(carWithoutDamage.damageRecord, '0');

      final carWithDamage = Car(
        brand: 'Honda',
        model: 'Civic',
        year: '2021',
        price: '520000',
        addedDate: DateTime.now(),
        damageRecord: '25000',
      );

      expect(carWithDamage.damageRecord, '25000');
    });
  });
}
