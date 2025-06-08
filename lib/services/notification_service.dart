import 'dart:async';
import 'package:flutter/material.dart';
import 'logging_service.dart';

class NotificationService {
  static final _logger = LoggingService();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<AppNotification> _notifications = [];
  final StreamController<List<AppNotification>> _notificationController = 
      StreamController<List<AppNotification>>.broadcast();

  Stream<List<AppNotification>> get notificationStream => _notificationController.stream;
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Shows a simple info notification
  void showInfo(String message, {String? title, Duration? duration}) {
    _addNotification(AppNotification(
      id: _generateId(),
      type: NotificationType.info,
      title: title ?? 'Bilgi',
      message: message,
      timestamp: DateTime.now(),
      duration: duration,
    ));
  }

  /// Shows a success notification
  void showSuccess(String message, {String? title, Duration? duration}) {
    _addNotification(AppNotification(
      id: _generateId(),
      type: NotificationType.success,
      title: title ?? 'Başarılı',
      message: message,
      timestamp: DateTime.now(),
      duration: duration,
    ));
  }

  /// Shows a warning notification
  void showWarning(String message, {String? title, Duration? duration}) {
    _addNotification(AppNotification(
      id: _generateId(),
      type: NotificationType.warning,
      title: title ?? 'Uyarı',
      message: message,
      timestamp: DateTime.now(),
      duration: duration,
    ));
  }

  /// Shows an error notification
  void showError(String message, {String? title, Duration? duration}) {
    _addNotification(AppNotification(
      id: _generateId(),
      type: NotificationType.error,
      title: title ?? 'Hata',
      message: message,
      timestamp: DateTime.now(),
      duration: duration,
    ));
  }

  /// Shows a backup-related notification
  void showBackupNotification(String message, {bool isSuccess = true}) {
    _addNotification(AppNotification(
      id: _generateId(),
      type: isSuccess ? NotificationType.success : NotificationType.error,
      title: 'Yedekleme',
      message: message,
      timestamp: DateTime.now(),
      category: NotificationCategory.backup,
    ));
  }

  /// Shows a car-related notification
  void showCarNotification(String message, NotificationType type, {String? carInfo}) {
    _addNotification(AppNotification(
      id: _generateId(),
      type: type,
      title: 'Araç İşlemi',
      message: message,
      timestamp: DateTime.now(),
      category: NotificationCategory.car,
      metadata: carInfo != null ? {'carInfo': carInfo} : null,
    ));
  }

  /// Shows a database-related notification
  void showDatabaseNotification(String message, NotificationType type) {
    _addNotification(AppNotification(
      id: _generateId(),
      type: type,
      title: 'Veritabanı',
      message: message,
      timestamp: DateTime.now(),
      category: NotificationCategory.database,
    ));
  }

  /// Shows a system notification
  void showSystemNotification(String message, NotificationType type) {
    _addNotification(AppNotification(
      id: _generateId(),
      type: type,
      title: 'Sistem',
      message: message,
      timestamp: DateTime.now(),
      category: NotificationCategory.system,
    ));
  }

  /// Shows an actionable notification with custom actions
  void showActionableNotification({
    required String title,
    required String message,
    required NotificationType type,
    required List<NotificationAction> actions,
    NotificationCategory? category,
    Map<String, dynamic>? metadata,
  }) {
    _addNotification(AppNotification(
      id: _generateId(),
      type: type,
      title: title,
      message: message,
      timestamp: DateTime.now(),
      category: category,
      actions: actions,
      metadata: metadata,
    ));
  }

  /// Shows a Flutter SnackBar notification
  void showSnackBar(
    BuildContext context, 
    String message, {
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    try {
      final color = _getColorForType(type, Theme.of(context));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: duration,
          action: action,
          behavior: SnackBarBehavior.floating,
        ),
      );

      _logger.debug('SnackBar shown', tag: 'Notification', data: {
        'message': message,
        'type': type.toString(),
      });
    } catch (e, stackTrace) {
      _logger.error('Failed to show SnackBar', tag: 'Notification', error: e, stackTrace: stackTrace);
    }
  }

  /// Shows a system alert dialog
  Future<void> showAlert(
    BuildContext context, {
    required String title,
    required String message,
    NotificationType type = NotificationType.info,
    List<AlertAction>? actions,
  }) async {
    try {
      final defaultActions = actions ?? [
        AlertAction(
          label: 'Tamam',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ];

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: _getIconForType(type),
          title: Text(title),
          content: Text(message),
          actions: defaultActions.map((action) => TextButton(
            onPressed: action.onPressed,
            child: Text(action.label),
          )).toList(),
        ),
      );

      _logger.debug('Alert dialog shown', tag: 'Notification', data: {
        'title': title,
        'message': message,
        'type': type.toString(),
      });
    } catch (e, stackTrace) {
      _logger.error('Failed to show alert dialog', tag: 'Notification', error: e, stackTrace: stackTrace);
    }
  }

  /// Shows a confirmation dialog
  Future<bool> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Evet',
    String cancelLabel = 'Hayır',
    NotificationType type = NotificationType.warning,
  }) async {
    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: _getIconForType(type),
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelLabel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        ),
      );

      _logger.debug('Confirmation dialog result', tag: 'Notification', data: {
        'title': title,
        'result': result,
      });

      return result ?? false;
    } catch (e, stackTrace) {
      _logger.error('Failed to show confirmation dialog', tag: 'Notification', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Marks a notification as read
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _notificationController.add(_notifications);
      
      _logger.debug('Notification marked as read', tag: 'Notification', data: {
        'notificationId': notificationId,
      });
    }
  }

  /// Marks all notifications as read
  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    _notificationController.add(_notifications);
    
    _logger.info('All notifications marked as read', tag: 'Notification');
  }

  /// Removes a notification
  void removeNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    _notificationController.add(_notifications);
    
    _logger.debug('Notification removed', tag: 'Notification', data: {
      'notificationId': notificationId,
    });
  }

  /// Clears all notifications
  void clearAll() {
    _notifications.clear();
    _notificationController.add(_notifications);
    
    _logger.info('All notifications cleared', tag: 'Notification');
  }

  /// Clears notifications by category
  void clearByCategory(NotificationCategory category) {
    _notifications.removeWhere((n) => n.category == category);
    _notificationController.add(_notifications);
    
    _logger.debug('Notifications cleared by category', tag: 'Notification', data: {
      'category': category.toString(),
    });
  }

  /// Gets notifications by category
  List<AppNotification> getByCategory(NotificationCategory category) {
    return _notifications.where((n) => n.category == category).toList();
  }

  /// Gets notifications by type
  List<AppNotification> getByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  /// Gets recent notifications
  List<AppNotification> getRecent({int limit = 10}) {
    final sorted = List<AppNotification>.from(_notifications)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted.take(limit).toList();
  }

  void dispose() {
    _notificationController.close();
  }

  // Private methods

  void _addNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    
    // Limit number of notifications to prevent memory issues
    if (_notifications.length > 100) {
      _notifications.removeRange(100, _notifications.length);
    }
    
    _notificationController.add(_notifications);
    
    // Auto-remove if duration is set
    if (notification.duration != null) {
      Timer(notification.duration!, () {
        removeNotification(notification.id);
      });
    }
    
    _logger.debug('Notification added', tag: 'Notification', data: {
      'id': notification.id,
      'type': notification.type.toString(),
      'message': notification.message,
    });
  }

  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_notifications.length}';
  }

  Color _getColorForType(NotificationType type, ThemeData theme) {
    switch (type) {
      case NotificationType.success:
        return Colors.green;
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.error:
        return theme.colorScheme.error;
      case NotificationType.info:
      default:
        return theme.colorScheme.primary;
    }
  }

  Icon _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return const Icon(Icons.check_circle, color: Colors.green);
      case NotificationType.warning:
        return const Icon(Icons.warning, color: Colors.orange);
      case NotificationType.error:
        return const Icon(Icons.error, color: Colors.red);
      case NotificationType.info:
      default:
        return const Icon(Icons.info, color: Colors.blue);
    }
  }
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final NotificationCategory? category;
  final Duration? duration;
  final List<NotificationAction>? actions;
  final Map<String, dynamic>? metadata;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.category,
    this.duration,
    this.actions,
    this.metadata,
  });

  AppNotification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    NotificationCategory? category,
    Duration? duration,
    List<NotificationAction>? actions,
    Map<String, dynamic>? metadata,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      category: category ?? this.category,
      duration: duration ?? this.duration,
      actions: actions ?? this.actions,
      metadata: metadata ?? this.metadata,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Az önce';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} saat önce';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

class NotificationAction {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  const NotificationAction({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  });
}

class AlertAction {
  final String label;
  final VoidCallback onPressed;
  final bool isDestructive;

  const AlertAction({
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
  });
}

enum NotificationType {
  info,
  success,
  warning,
  error,
}

enum NotificationCategory {
  car,
  backup,
  database,
  system,
  user,
}
