class ValidationUtils {
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName gereklidir';
    }
    return null;
  }

  static String? validateNumber(
    String? value,
    String fieldName, {
    int? min,
    int? max,
    bool required = true,
  }) {
    if (required) {
      final requiredCheck = validateRequired(value, fieldName);
      if (requiredCheck != null) return requiredCheck;
    }

    if (value != null && value.isNotEmpty) {
      final number = int.tryParse(value);
      if (number == null) {
        return 'Geçerli bir $fieldName giriniz';
      }

      if (min != null && number < min) {
        return '$fieldName en az $min olmalıdır';
      }

      if (max != null && number > max) {
        return '$fieldName en fazla $max olmalıdır';
      }
    }

    return null;
  }

  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Fiyat gereklidir';
    }

    final price = double.tryParse(value.replaceAll(',', ''));
    if (price == null) {
      return 'Geçerli bir fiyat giriniz';
    }

    if (price < 0) {
      return 'Fiyat negatif olamaz';
    }

    if (price > 10000000) {
      return 'Fiyat çok yüksek';
    }

    return null;
  }

  static String? validateYear(String? value) {
    final currentYear = DateTime.now().year;
    return validateNumber(
      value,
      'Yıl',
      min: 1990,
      max: currentYear + 1,
    );
  }

  static String? validateKilometers(String? value) {
    if (value != null && value.isNotEmpty) {
      return validateNumber(
        value,
        'Kilometre',
        min: 0,
        max: 2000000,
        required: false,
      );
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value != null && value.isNotEmpty) {
      // Türkiye telefon numarası formatı kontrolü
      final phoneRegex = RegExp(r'^(\+90|0)?[5][0-9]{9}$');
      if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[\s\-\(\)]'), ''))) {
        return 'Geçerli bir telefon numarası giriniz';
      }
    }
    return null;
  }

  static String? validateTcNo(String? value) {
    if (value != null && value.isNotEmpty) {
      if (value.length != 11) {
        return 'TC Kimlik No 11 haneli olmalıdır';
      }

      if (!RegExp(r'^[1-9][0-9]{10}$').hasMatch(value)) {
        return 'Geçerli bir TC Kimlik No giriniz';
      }

      // TC Kimlik No algoritma kontrolü
      if (!_isValidTcNo(value)) {
        return 'Geçersiz TC Kimlik No';
      }
    }
    return null;
  }

  static bool _isValidTcNo(String tcNo) {
    try {
      if (tcNo.length != 11) return false;

      final digits = tcNo.split('').map((e) => int.tryParse(e) ?? -1).toList();

      // Tüm haneler sayı olmalı
      if (digits.any((d) => d == -1)) return false;

      // İlk hane 0 olamaz
      if (digits[0] == 0) return false;

      // 10. hane kontrolü
      int sum1 = 0;
      int sum2 = 0;

      for (int i = 0; i < 9; i++) {
        if (i % 2 == 0) {
          sum1 += digits[i];
        } else {
          sum2 += digits[i];
        }
      }

      int check1 = (sum1 * 7 - sum2) % 10;
      if (check1 != digits[9]) return false;

      // 11. hane kontrolü
      int totalSum = 0;
      for (int i = 0; i < 10; i++) {
        totalSum += digits[i];
      }

      int check2 = totalSum % 10;
      return check2 == digits[10];
    } catch (e) {
      return false;
    }
  }
}
