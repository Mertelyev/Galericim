import 'package:flutter_test/flutter_test.dart';
import 'package:galericim/utils/error_handler.dart';

void main() {
  group('ErrorHandler Tests', () {
    test('should handle general exceptions without throwing', () {
      final exception = Exception('Test exception');
      
      expect(() => ErrorHandler.handleError(exception, null), returnsNormally);
    });

    test('should handle DatabaseException without throwing', () {
      final exception = DatabaseException('Database connection failed');
      
      expect(() => ErrorHandler.handleError(exception, null), returnsNormally);
    });

    test('should handle ValidationException without throwing', () {
      final exception = ValidationException('Invalid input data');
      
      expect(() => ErrorHandler.handleError(exception, null), returnsNormally);
    });

    test('should handle unknown error types without throwing', () {
      expect(() => ErrorHandler.handleError('String error', null), returnsNormally);
    });

    test('should handle null errors without throwing', () {
      expect(() => ErrorHandler.handleError(null, null), returnsNormally);
    });

    test('should handle errors with context', () {
      final exception = Exception('Test exception');
      
      expect(() => ErrorHandler.handleError(
        exception, 
        null, 
        context: 'Test context'
      ), returnsNormally);
    });

    test('should get user friendly message for database errors', () {
      final message = ErrorHandler.getUserFriendlyMessage('database connection failed');
      
      expect(message, equals('Veritabanı hatası oluştu. Lütfen uygulamayı yeniden başlatın.'));
    });

    test('should get user friendly message for network errors', () {
      final message = ErrorHandler.getUserFriendlyMessage('network timeout');
      
      expect(message, equals('İnternet bağlantısı sorunu. Lütfen bağlantınızı kontrol edin.'));
    });

    test('should get user friendly message for permission errors', () {
      final message = ErrorHandler.getUserFriendlyMessage('permission denied');
      
      expect(message, equals('İzin hatası. Lütfen uygulama ayarlarını kontrol edin.'));
    });

    test('should get default user friendly message for unknown errors', () {
      final message = ErrorHandler.getUserFriendlyMessage('unknown error');
      
      expect(message, equals('Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.'));
    });
  });

  group('DatabaseException Tests', () {
    test('should create DatabaseException with message', () {
      final exception = DatabaseException('Test database error');

      expect(exception.message, equals('Test database error'));
      expect(exception.toString(),
          equals('DatabaseException: Test database error'));
    });

    test('should create DatabaseException with original error', () {
      final originalError = Exception('Original error');
      final exception = DatabaseException('Test database error', originalError);

      expect(exception.message, equals('Test database error'));
      expect(exception.originalError, equals(originalError));
    });

    test('should extend Exception', () {
      final exception = DatabaseException('Test error');

      expect(exception, isA<Exception>());
    });
  });

  group('ValidationException Tests', () {
    test('should create ValidationException with message', () {
      final exception = ValidationException('Test validation error');

      expect(exception.message, equals('Test validation error'));
      expect(exception.toString(),
          equals('ValidationException: Test validation error'));
    });

    test('should create ValidationException with field errors', () {
      final fieldErrors = {'field1': 'Error 1', 'field2': 'Error 2'};
      final exception = ValidationException('Test validation error', fieldErrors);

      expect(exception.message, equals('Test validation error'));
      expect(exception.fieldErrors, equals(fieldErrors));
    });

    test('should extend Exception', () {
      final exception = ValidationException('Test error');

      expect(exception, isA<Exception>());
    });
  });
}
