import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/logging_service.dart';
import '../services/notification_service.dart';

/// Enhanced error handler that integrates with logging and notification services
///
/// Usage examples:
/// ```dart
/// // Basic error handling
/// ErrorHandler.handleError(e, stackTrace, context: 'User login', showToUser: true);
///
/// // Database-specific error handling
/// ErrorHandler.handleDatabaseError(e, stackTrace, operation: 'Save car data', buildContext: context);
///
/// // Validation error handling
/// ErrorHandler.handleValidationError(validationException, buildContext: context);
///
/// // Critical error reporting
/// ErrorHandler.reportCriticalError(e, stackTrace, context: 'Payment processing');
/// ```
class ErrorHandler {
  static final _logger = LoggingService();
  static final _notificationService = NotificationService();

  static void handleError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
    bool showToUser = false,
    BuildContext? buildContext,
  }) {
    if (kDebugMode) {
      debugPrint('🚨 Error occurred: $error');
      if (context != null) debugPrint('📍 Context: $context');
      if (stackTrace != null) debugPrint('📚 Stack trace: $stackTrace');
    }

    _logger.error(
      'Error occurred: $error',
      tag: 'ErrorHandler',
      error: error,
      stackTrace: stackTrace,
      data: context != null ? {'context': context} : null,
    );

    if (showToUser) {
      final userMessage = getUserFriendlyMessage(error);
      _notificationService.showError(userMessage);

      if (buildContext != null && buildContext.mounted) {
        ScaffoldMessenger.of(buildContext).showSnackBar(
          SnackBar(
            content: Text(userMessage),
            backgroundColor: Theme.of(buildContext).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Tamam',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(buildContext).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
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

  /// Handle database-related errors specifically
  static void handleDatabaseError(
    dynamic error,
    StackTrace? stackTrace, {
    String? operation,
    BuildContext? buildContext,
  }) {
    handleError(
      error,
      stackTrace,
      context: 'Database Operation: ${operation ?? 'Unknown'}',
      showToUser: true,
      buildContext: buildContext,
    );
  }

  /// Handle network-related errors specifically
  static void handleNetworkError(
    dynamic error,
    StackTrace? stackTrace, {
    String? endpoint,
    BuildContext? buildContext,
  }) {
    handleError(
      error,
      stackTrace,
      context: 'Network Request: ${endpoint ?? 'Unknown'}',
      showToUser: true,
      buildContext: buildContext,
    );
  }

  /// Handle validation errors specifically
  static void handleValidationError(
    ValidationException error, {
    BuildContext? buildContext,
  }) {
    _logger.warning(
      'Validation error: ${error.message}',
      tag: 'ErrorHandler',
      data: error.fieldErrors,
    );

    if (buildContext != null && buildContext.mounted) {
      ScaffoldMessenger.of(buildContext).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Report critical errors that need immediate attention
  static void reportCriticalError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
    Map<String, dynamic>? additionalData,
  }) {
    _logger.critical(
      'CRITICAL ERROR: $error',
      tag: 'ErrorHandler',
      error: error,
      stackTrace: stackTrace,
      data: {
        'context': context,
        ...?additionalData,
      },
    ); // Üretim modunda kritik hataları crash reporting servisine gönder
    if (kReleaseMode) {
      _sendToCrashReporting(error, stackTrace, context, additionalData);
    }
  }

  static void _sendToCrashReporting(
    dynamic error,
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? additionalData,
  ) {
    // Firebase Crashlytics veya benzeri servis entegrasyonu için hazır
    // Şu anda sadece konsola yazdırıyor
    if (kDebugMode) {
      debugPrint('📤 Would send to crash reporting: $error');
      debugPrint('📝 Context: $context');
      if (additionalData != null) {
        debugPrint('📊 Additional data: $additionalData');
      }
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
