import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum FeedbackCategory {
  bugReport,
  featureRequest,
  general,
  complaint,
  praise,
}

class UserFeedback extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final FeedbackCategory category;
  final String subject;
  final String message;
  final DateTime submittedAt;
  final String? status; // pending, reviewed, resolved
  final String? adminNotes;

  const UserFeedback({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.category,
    required this.subject,
    required this.message,
    required this.submittedAt,
    this.status,
    this.adminNotes,
  });

  // Firestore -> Model
  factory UserFeedback.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserFeedback(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      category: FeedbackCategory.values.firstWhere(
            (e) => e.name == data['category'],
        orElse: () => FeedbackCategory.general,
      ),
      subject: data['subject'] ?? '',
      message: data['message'] ?? '',
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'pending',
      adminNotes: data['adminNotes'],
    );
  }

  // Model -> Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'category': category.name,
      'subject': subject,
      'message': message,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'status': status ?? 'pending',
      'adminNotes': adminNotes,
    };
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    userName,
    userEmail,
    category,
    subject,
    message,
    submittedAt,
    status,
    adminNotes,
  ];
}

// Helper to get display text for categories
extension FeedbackCategoryExtension on FeedbackCategory {
  String get displayName {
    switch (this) {
      case FeedbackCategory.bugReport:
        return 'Bug Report';
      case FeedbackCategory.featureRequest:
        return 'Feature Request';
      case FeedbackCategory.general:
        return 'General Feedback';
      case FeedbackCategory.complaint:
        return 'Complaint';
      case FeedbackCategory.praise:
        return 'Praise';
    }
  }

  String get icon {
    switch (this) {
      case FeedbackCategory.bugReport:
        return '🐛';
      case FeedbackCategory.featureRequest:
        return '💡';
      case FeedbackCategory.general:
        return '💬';
      case FeedbackCategory.complaint:
        return '😞';
      case FeedbackCategory.praise:
        return '⭐';
    }
  }
}