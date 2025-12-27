import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  medicineExpiry,
  dosageReminder,
  familyUpdate,
  appUpdate,
  general,
}

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data; // Additional data (medicineId, etc.)

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.data,
  });

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'createdAt': createdAt,
      'isRead': isRead,
      'data': data,
    };
  }

  // Convert from Firestore
  factory AppNotification.fromFirestore(String id, Map<String, dynamic> data) {
    return AppNotification(
      id: id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: _parseNotificationType(data['type']),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      data: data['data'],
    );
  }

  // Parse notification type from string
  static NotificationType _parseNotificationType(String? typeString) {
    switch (typeString) {
      case 'medicineExpiry':
        return NotificationType.medicineExpiry;
      case 'dosageReminder':
        return NotificationType.dosageReminder;
      case 'familyUpdate':
        return NotificationType.familyUpdate;
      case 'appUpdate':
        return NotificationType.appUpdate;
      default:
        return NotificationType.general;
    }
  }

  // Get icon for notification type
  String getIcon() {
    switch (type) {
      case NotificationType.medicineExpiry:
        return '⚠️';
      case NotificationType.dosageReminder:
        return '💊';
      case NotificationType.familyUpdate:
        return '👨‍👩‍👧‍👦';
      case NotificationType.appUpdate:
        return '🔔';
      case NotificationType.general:
        return 'ℹ️';
    }
  }

  // Copy with method for updating
  AppNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? createdAt,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }
}