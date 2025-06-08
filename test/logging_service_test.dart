import 'package:flutter_test/flutter_test.dart';
import 'package:galericim/services/logging_service.dart';

void main() {
  group('LoggingService Tests', () {
    late LoggingService logger;

    setUp(() {
      logger = LoggingService();
      logger.clearLogs(); // Clear any existing logs
    });

    test('should be singleton', () {
      final logger1 = LoggingService();
      final logger2 = LoggingService();
      expect(identical(logger1, logger2), isTrue);
    });

    test('should log debug messages', () {
      logger.debug('Debug message');
      final logs = logger.getLogs();
      expect(logs.length, equals(1));
      expect(logs.first.level, equals(LogLevel.debug));
      expect(logs.first.message, equals('Debug message'));
    });

    test('should log info messages', () {
      logger.info('Info message');
      final logs = logger.getLogs();
      expect(logs.length, equals(1));
      expect(logs.first.level, equals(LogLevel.info));
      expect(logs.first.message, equals('Info message'));
    });

    test('should log warning messages', () {
      logger.warning('Warning message');
      final logs = logger.getLogs();
      expect(logs.length, equals(1));
      expect(logs.first.level, equals(LogLevel.warning));
      expect(logs.first.message, equals('Warning message'));
    });

    test('should log error messages', () {
      logger.error('Error message');
      final logs = logger.getLogs();
      expect(logs.length, equals(1));
      expect(logs.first.level, equals(LogLevel.error));
      expect(logs.first.message, equals('Error message'));
    });

    test('should log critical messages', () {
      logger.critical('Critical message');
      final logs = logger.getLogs();
      expect(logs.length, equals(1));
      expect(logs.first.level, equals(LogLevel.critical));
      expect(logs.first.message, equals('Critical message'));
    });

    test('should log error with exception and stack trace', () {
      final exception = Exception('Test exception');
      final stackTrace = StackTrace.current;

      logger.error('Error message', error: exception, stackTrace: stackTrace);
      final logs = logger.getLogs();

      expect(logs.length, equals(1));
      expect(logs.first.level, equals(LogLevel.error));
      expect(logs.first.message, equals('Error message'));
      expect(logs.first.error, equals(exception));
      expect(logs.first.stackTrace, equals(stackTrace));
    });

    test('should maintain log order by timestamp', () {
      logger.debug('First message');
      logger.info('Second message');
      logger.warning('Third message');

      final logs = logger.getLogs();
      expect(logs.length, equals(3));
      expect(logs[0].message, equals('First message'));
      expect(logs[1].message, equals('Second message'));
      expect(logs[2].message, equals('Third message'));

      // Check timestamps are in order
      expect(
          logs[0].timestamp.isBefore(logs[1].timestamp) ||
              logs[0].timestamp.isAtSameMomentAs(logs[1].timestamp),
          isTrue);
      expect(
          logs[1].timestamp.isBefore(logs[2].timestamp) ||
              logs[1].timestamp.isAtSameMomentAs(logs[2].timestamp),
          isTrue);
    });    test('should filter logs by level', () {
      logger.debug('Debug message');
      logger.info('Info message');
      logger.warning('Warning message');
      logger.error('Error message');
      logger.critical('Critical message');

      final errorLogs = logger.getLogs(minLevel: LogLevel.error);
      expect(errorLogs.length, equals(2)); // error + critical
      expect(errorLogs.any((log) => log.message == 'Error message'), isTrue);

      final warningLogs = logger.getLogs(minLevel: LogLevel.warning);
      expect(warningLogs.length, equals(3)); // warning + error + critical
      expect(warningLogs.any((log) => log.message == 'Warning message'), isTrue);
    });

    test('should clear logs', () {
      logger.debug('Debug message');
      logger.info('Info message');
      expect(logger.getLogs().length, equals(2));

      logger.clearLogs();
      expect(logger.getLogs().length, equals(0));
    });

    test('should limit log storage to maxLogEntries', () {
      // Get the current max log entries (should be 1000 by default)
      for (int i = 0; i < 1005; i++) {
        logger.debug('Message $i');
      }

      final logs = logger.getLogs();
      expect(logs.length, equals(1000)); // Should not exceed max
      expect(
          logs.first.message, equals('Message 5')); // First 5 should be removed
      expect(logs.last.message, equals('Message 1004')); // Last should be kept
    });

    test('should format log entry correctly', () {
      logger.info('Test message');
      final logs = logger.getLogs();
      final logEntry = logs.first;

      expect(logEntry.level, equals(LogLevel.info));
      expect(logEntry.message, equals('Test message'));
      expect(logEntry.timestamp, isA<DateTime>());
      expect(logEntry.error, isNull);
      expect(logEntry.stackTrace, isNull);
    });
  });
}
