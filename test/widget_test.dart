// This is a basic Flutter widget test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:galericim/car.dart';

void main() {
  group('Basic Widget Tests', () {
    testWidgets('Car model can be created and used', (WidgetTester tester) async {
      final car = Car(
        id: 1,
        brand: 'Toyota',
        model: 'Corolla',
        year: '2020',
        color: 'White',
        fuelType: 'Gasoline',
        transmission: 'Automatic',
        kilometers: '50000',
        price: '150000',
        addedDate: DateTime.now(),
        damageRecord: '0',
        description: 'Test car',
        isSold: false,
      );

      expect(car.brand, equals('Toyota'));
      expect(car.model, equals('Corolla'));
      expect(car.year, equals('2020'));
      expect(car.isSold, equals(false));    });

    testWidgets('Basic widget can be created', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Test')),
            body: const Center(child: Text('Hello World')),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
      expect(find.text('Hello World'), findsOneWidget);
    });
  });
}
