import 'package:flutter/foundation.dart';

class ErrorHandler {
  static void handleError(dynamic error, StackTrace? stackTrace, {
    String? context,
    bool showToUser = false,
  }) {
    // Development modunda hataları konsola yazdır
    if (kDebugMode) {
      debugPrint('🚨 Error occurred: $error');
      if (context != null) debugPrint('📍 Context: $context');
      if (stackTrace != null) debugPrint('📚 Stack trace: $stackTrace');
    }
    
    // Üretim modunda hataları log servisine gönder
    // TODO: Implement logging service for production
    
    // Kritik hatalar için kullanıcıya bildirim göster
    if (showToUser) {
      // TODO: Show user-friendly error message
    }
  }

  static String getUserFriendlyMessage(dynamic error) {
    if (error.toString().contains('database')) {
      return 'Veritabanı hatası oluştu. Lütfen uygulamayı yeniden başlatın.';
    } else if (error.toString().contains('network')) {
      return 'İnternet bağlantısı sorunu. Lütfen bağlantınızı kontrol edin.';
    } else if (error.toString().contains('permission')) {
      return 'İzin hatası. Lütfen uygulama ayarlarını kontrol edin.';
    } else {
      return 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }
}

class DatabaseException implements Exception {
  final String message;
  final dynamic originalError;
  
  DatabaseException(this.message, [this.originalError]);
  
  @override
  String toString() => 'DatabaseException: $message';
}

class ValidationException implements Exception {
  final String message;
  final Map<String, String>? fieldErrors;
  
  ValidationException(this.message, [this.fieldErrors]);
  
  @override
  String toString() => 'ValidationException: $message';
}
