import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meditrack/model/app_notification.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get notifications stream for a user
  Stream<List<AppNotification>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AppNotification.fromFirestore(doc.id, doc.data());
      }).toList();
    });
  }

  // Get unread count
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Create a new notification
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) async {
    final notification = AppNotification(
      id: '', // Firestore will generate
      userId: userId,
      title: title,
      message: message,
      type: type,
      createdAt: DateTime.now(),
      isRead: false,
      data: data,
    );

    await _firestore.collection('notifications').add(notification.toFirestore());
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  // Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    final batch = _firestore.batch();
    
    final notifications = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in notifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  // Delete all notifications for a user
  Future<void> deleteAllNotifications(String userId) async {
    final batch = _firestore.batch();
    
    final notifications = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .get();

    for (var doc in notifications.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // Create sample notifications for testing
  Future<void> createSampleNotifications(String userId) async {
    // Medicine expiry notification
    await createNotification(
      userId: userId,
      title: 'Medicine Expiring Soon',
      message: 'Your Aspirin will expire in 3 days. Please check your medicine cabinet.',
      type: NotificationType.medicineExpiry,
      data: {'medicineId': 'sample_medicine_id'},
    );

    // Dosage reminder
    await createNotification(
      userId: userId,
      title: 'Time to Take Your Medicine',
      message: 'Don\'t forget to take your evening dose of Paracetamol.',
      type: NotificationType.dosageReminder,
      data: {'dosageId': 'sample_dosage_id'},
    );

    // Family update
    await createNotification(
      userId: userId,
      title: 'Family Account Update',
      message: 'You have been added to the Johnson Family account.',
      type: NotificationType.familyUpdate,
    );

    // App update
    await createNotification(
      userId: userId,
      title: 'New Feature Available',
      message: 'Check out the new Pharmacy Search feature!',
      type: NotificationType.appUpdate,
    );
  }
}