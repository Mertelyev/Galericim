import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  factory LoggingService() => _instance;
  LoggingService._internal();

  // In-memory log storage for development/debugging
  final List<LogEntry> _logs = [];
  static const int maxLogEntries = 1000;

  void log(
    String message, {
    LogLevel level = LogLevel.info,
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    final logEntry = LogEntry(
      message: message,
      level: level,
      tag: tag ?? 'Galericim',
      timestamp: DateTime.now(),
      error: error,
      stackTrace: stackTrace,
      data: data,
    );

    // Add to in-memory storage
    _addToMemoryLog(logEntry);

    // Output to console in debug mode
    if (kDebugMode) {
      _outputToConsole(logEntry);
    }

    // In production, you could send critical errors to a crash reporting service
    if (level == LogLevel.critical && kReleaseMode) {
      _reportCriticalError(logEntry);
    }
  }

  void debug(String message, {String? tag, Map<String, dynamic>? data}) {
    log(message, level: LogLevel.debug, tag: tag, data: data);
  }

  void info(String message, {String? tag, Map<String, dynamic>? data}) {
    log(message, level: LogLevel.info, tag: tag, data: data);
  }

  void warning(String message, {String? tag, Map<String, dynamic>? data}) {
    log(message, level: LogLevel.warning, tag: tag, data: data);
  }

  void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    log(
      message,
      level: LogLevel.error,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  void critical(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    log(
      message,
      level: LogLevel.critical,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  void _addToMemoryLog(LogEntry entry) {
    _logs.add(entry);
    if (_logs.length > maxLogEntries) {
      _logs.removeAt(0);
    }
  }

  void _outputToConsole(LogEntry entry) {
    final timestamp = entry.timestamp.toString().substring(0, 19);
    final levelStr = entry.level.name.toUpperCase().padRight(8);
    final tag = entry.tag.padRight(12);
    
    final message = '[$timestamp] $levelStr $tag: ${entry.message}';
    
    switch (entry.level) {
      case LogLevel.debug:
        developer.log(message, name: entry.tag, level: 500);
        break;
      case LogLevel.info:
        developer.log(message, name: entry.tag, level: 800);
        break;
      case LogLevel.warning:
        developer.log(message, name: entry.tag, level: 900);
        break;
      case LogLevel.error:
      case LogLevel.critical:
        developer.log(
          message,
          name: entry.tag,
          level: 1000,
          error: entry.error,
          stackTrace: entry.stackTrace,
        );
        break;
    }

    if (entry.data != null) {
      developer.log('Data: ${entry.data}', name: entry.tag);
    }
  }

  void _reportCriticalError(LogEntry entry) {    // In a real app, you would integrate with services like:
    // - Firebase Crashlytics
    // - Sentry
    // - Bugsnag
    // For now, we'll just use debugPrint
    debugPrint('CRITICAL ERROR: ${entry.message}');
    if (entry.error != null) {
      debugPrint('Error: ${entry.error}');
    }
    if (entry.stackTrace != null) {
      debugPrint('Stack Trace: ${entry.stackTrace}');
    }
  }

  // Get logs for debugging or support
  List<LogEntry> getLogs({LogLevel? minLevel}) {
    if (minLevel == null) return List.unmodifiable(_logs);
    
    final minLevelIndex = LogLevel.values.indexOf(minLevel);
    return _logs
        .where((log) => LogLevel.values.indexOf(log.level) >= minLevelIndex)
        .toList();
  }

  // Clear logs
  void clearLogs() {
    _logs.clear();
  }

  // Export logs as text for support
  String exportLogsAsText({LogLevel? minLevel}) {
    final logs = getLogs(minLevel: minLevel);
    final buffer = StringBuffer();
    
    buffer.writeln('Galericim App Logs');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('Total entries: ${logs.length}');
    buffer.writeln('=' * 50);
    
    for (final log in logs) {
      buffer.writeln(log.toString());
      buffer.writeln('-' * 30);
    }
    
    return buffer.toString();
  }
}

class LogEntry {
  final String message;
  final LogLevel level;
  final String tag;
  final DateTime timestamp;
  final Object? error;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? data;

  const LogEntry({
    required this.message,
    required this.level,
    required this.tag,
    required this.timestamp,
    this.error,
    this.stackTrace,
    this.data,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('[${timestamp.toString().substring(0, 19)}] ${level.name.toUpperCase()} $tag');
    buffer.writeln('Message: $message');
    
    if (error != null) {
      buffer.writeln('Error: $error');
    }
    
    if (data != null) {
      buffer.writeln('Data: $data');
    }
    
    if (stackTrace != null) {
      buffer.writeln('Stack Trace:');
      buffer.writeln(stackTrace.toString());
    }
    
    return buffer.toString();
  }
}
