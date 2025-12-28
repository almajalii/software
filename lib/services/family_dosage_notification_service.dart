import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meditrack/model/app_notification.dart';
import 'package:meditrack/services/notification_service.dart';

class FamilyDosageNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  /// Send dosage reminder notification to selected family members
  Future<void> sendDosageReminderToFamily({
    required String familyAccountId,
    required List<String> familyMemberIds,
    required String medicineName,
    required String dosage,
    required String time,
    required String patientName,
    String? patientUserId,
  }) async {
    try {
      print('📤 Sending dosage reminder to ${familyMemberIds.length} family members...');

      for (String memberId in familyMemberIds) {
        // Get family member details
        final memberSnapshot = await _firestore
            .collection('familyAccounts')
            .doc(familyAccountId)
            .collection('members')
            .doc(memberId)
            .get();

        if (!memberSnapshot.exists) continue;

        final memberData = memberSnapshot.data();
        final memberUserId = memberData?['userId'];

        // Don't send notification to the patient themselves
        if (memberUserId == null || memberUserId == patientUserId) continue;

        // Create notification for this family member
        await _notificationService.createNotification(
          userId: memberUserId,
          title: '💊 Dosage Reminder for $patientName',
          message: '$patientName needs to take $dosage of $medicineName at $time',
          type: NotificationType.dosageReminder,
          data: {
            'medicineName': medicineName,
            'dosage': dosage,
            'time': time,
            'patientName': patientName,
            'patientUserId': patientUserId,
            'familyAccountId': familyAccountId,
          },
        );

        print('✅ Notification sent to family member: ${memberData?['displayName']}');
      }

      print('✅ All notifications sent successfully!');
    } catch (e) {
      print('❌ Error sending family notifications: $e');
      throw Exception('Failed to send family notifications: $e');
    }
  }

  /// Send notification when dosage is taken
  Future<void> notifyFamilyDosageTaken({
    required String familyAccountId,
    required List<String> familyMemberIds,
    required String medicineName,
    required String dosage,
    required String time,
    required String patientName,
    String? patientUserId,
  }) async {
    try {
      print('📤 Sending "dosage taken" notification to family...');

      for (String memberId in familyMemberIds) {
        final memberSnapshot = await _firestore
            .collection('familyAccounts')
            .doc(familyAccountId)
            .collection('members')
            .doc(memberId)
            .get();

        if (!memberSnapshot.exists) continue;

        final memberData = memberSnapshot.data();
        final memberUserId = memberData?['userId'];

        if (memberUserId == null || memberUserId == patientUserId) continue;

        await _notificationService.createNotification(
          userId: memberUserId,
          title: '✅ Dosage Taken - $patientName',
          message: '$patientName has taken $dosage of $medicineName at $time',
          type: NotificationType.dosageReminder,
          data: {
            'medicineName': medicineName,
            'dosage': dosage,
            'time': time,
            'patientName': patientName,
            'patientUserId': patientUserId,
            'familyAccountId': familyAccountId,
            'status': 'taken',
          },
        );
      }

      print('✅ "Dosage taken" notifications sent!');
    } catch (e) {
      print('❌ Error sending dosage taken notifications: $e');
    }
  }

  /// Send notification when new dosage schedule is created
  Future<void> notifyFamilyNewDosageSchedule({
    required String familyAccountId,
    required List<String> familyMemberIds,
    required String medicineName,
    required String dosage,
    required String frequency,
    required String patientName,
    String? patientUserId,
  }) async {
    try {
      print('📤 Notifying family about new dosage schedule...');

      for (String memberId in familyMemberIds) {
        final memberSnapshot = await _firestore
            .collection('familyAccounts')
            .doc(familyAccountId)
            .collection('members')
            .doc(memberId)
            .get();

        if (!memberSnapshot.exists) continue;

        final memberData = memberSnapshot.data();
        final memberUserId = memberData?['userId'];

        if (memberUserId == null || memberUserId == patientUserId) continue;

        await _notificationService.createNotification(
          userId: memberUserId,
          title: '🔔 New Medication Schedule - $patientName',
          message: '$patientName started taking $dosage of $medicineName - $frequency',
          type: NotificationType.familyUpdate,
          data: {
            'medicineName': medicineName,
            'dosage': dosage,
            'frequency': frequency,
            'patientName': patientName,
            'patientUserId': patientUserId,
            'familyAccountId': familyAccountId,
          },
        );
      }

      print('✅ New dosage schedule notifications sent!');
    } catch (e) {
      print('❌ Error sending new schedule notifications: $e');
    }
  }

  /// Get user's display name
  Future<String> getUserDisplayName(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.data()?['displayName'] ?? 'Family Member';
    } catch (e) {
      return 'Family Member';
    }
  }
}