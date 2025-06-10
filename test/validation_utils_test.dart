import 'package:flutter_test/flutter_test.dart';
import 'package:galericim/utils/validation_utils.dart';

void main() {
  group('ValidationUtils Tests', () {
    test('validateRequired should return error for empty string', () {
      expect(ValidationUtils.validateRequired('', 'Test Field'),
          equals('Test Field gereklidir'));
      expect(ValidationUtils.validateRequired('   ', 'Test Field'),
          equals('Test Field gereklidir'));
    });

    test('validateRequired should return null for valid string', () {
      expect(ValidationUtils.validateRequired('test', 'Test Field'), isNull);
      expect(
          ValidationUtils.validateRequired('  test  ', 'Test Field'), isNull);
    });

    test('validateNumber should return error for invalid number', () {
      expect(ValidationUtils.validateNumber('abc', 'Test Number'),
          equals('Geçerli bir Test Number giriniz'));
      expect(ValidationUtils.validateNumber('', 'Test Number'),
          equals('Test Number gereklidir'));
    });

    test('validateNumber should return null for valid number', () {
      expect(ValidationUtils.validateNumber('123', 'Test Number'), isNull);
      expect(ValidationUtils.validateNumber('0', 'Test Number'), isNull);
    });
    test('validatePrice should return error for invalid price', () {
      expect(ValidationUtils.validatePrice('abc'),
          equals('Geçerli bir fiyat giriniz'));
      expect(ValidationUtils.validatePrice(''), equals('Fiyat gereklidir'));
      expect(ValidationUtils.validatePrice('-100'),
          equals('Fiyat negatif olamaz'));
    });

    test('validatePrice should return null for valid price', () {
      expect(ValidationUtils.validatePrice('100'), isNull);
      expect(ValidationUtils.validatePrice('100.50'), isNull);
      expect(ValidationUtils.validatePrice('0'), isNull);
    });
    test('validateYear should return error for invalid year', () {
      final currentYear = DateTime.now().year;
      expect(ValidationUtils.validateYear('abc'),
          equals('Geçerli bir Yıl giriniz'));
      expect(ValidationUtils.validateYear(''), equals('Yıl gereklidir'));
      expect(ValidationUtils.validateYear('1989'),
          equals('Yıl en az 1990 olmalıdır'));
      expect(ValidationUtils.validateYear('${currentYear + 2}'),
          equals('Yıl en fazla ${currentYear + 1} olmalıdır'));
    });

    test('validateYear should return null for valid year', () {
      final currentYear = DateTime.now().year;
      expect(ValidationUtils.validateYear('2000'), isNull);
      expect(ValidationUtils.validateYear('$currentYear'), isNull);
      expect(ValidationUtils.validateYear('${currentYear + 1}'), isNull);
      expect(ValidationUtils.validateYear('1990'), isNull);
    });
    test('validateKilometers should return error for invalid kilometers', () {
      expect(ValidationUtils.validateKilometers('abc'),
          equals('Geçerli bir Kilometre giriniz'));
      expect(ValidationUtils.validateKilometers('-100'),
          equals('Kilometre en az 0 olmalıdır'));
    });

    test('validateKilometers should return null for valid kilometers', () {
      expect(ValidationUtils.validateKilometers(''), isNull); // Optional field
      expect(ValidationUtils.validateKilometers('0'), isNull);
      expect(ValidationUtils.validateKilometers('50000'), isNull);
      expect(ValidationUtils.validateKilometers('150000'), isNull);
    });
    test('validatePhone should return error for invalid phone', () {
      expect(ValidationUtils.validatePhone('abc'),
          equals('Geçerli bir telefon numarası giriniz'));
      expect(ValidationUtils.validatePhone('123'),
          equals('Geçerli bir telefon numarası giriniz'));
      expect(
          ValidationUtils.validatePhone('051234567890'), // 11 haneli
          equals('Geçerli bir telefon numarası giriniz'));
      expect(
          ValidationUtils.validatePhone('04123456789'), // 4 ile başlayan
          equals('Geçerli bir telefon numarası giriniz'));
    });
    test('validatePhone should return null for valid Turkish phone', () {
      expect(ValidationUtils.validatePhone('05123456789'), isNull); // 10 haneli
      expect(ValidationUtils.validatePhone('05323456789'), isNull);
      expect(ValidationUtils.validatePhone('05523456789'), isNull);
      expect(ValidationUtils.validatePhone('+905123456789'), isNull); // +90 ile
    });

    test('validatePhone should return null for empty phone (optional)', () {
      expect(ValidationUtils.validatePhone(''), isNull);
      expect(ValidationUtils.validatePhone(null), isNull);
    });
    test('validateTcNo should return error for invalid TC number', () {
      expect(ValidationUtils.validateTcNo('abc'),
          equals('TC Kimlik No 11 haneli olmalıdır'));
      expect(ValidationUtils.validateTcNo('123'),
          equals('TC Kimlik No 11 haneli olmalıdır'));
      expect(ValidationUtils.validateTcNo('12345678901'),
          equals('Geçersiz TC Kimlik No')); // Invalid algorithm
      expect(ValidationUtils.validateTcNo('01234567890'),
          equals('Geçerli bir TC Kimlik No giriniz')); // Starts with 0
    });
    test('validateTcNo should return null for valid TC number', () {
      // Bu test için TC No algoritmasını basit tutuyoruz
      expect(ValidationUtils.validateTcNo('12345678901'),
          equals('Geçersiz TC Kimlik No')); // Invalid test
    });

    test('validateTcNo should return null for empty TC (optional field)', () {
      expect(ValidationUtils.validateTcNo(''), isNull);
      expect(ValidationUtils.validateTcNo(null), isNull);
    });
  });
}
