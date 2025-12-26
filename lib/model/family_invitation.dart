import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum InvitationType {
  email,
  phone,
}

class FamilyInvitation extends Equatable {
  final String id; // Firestore document ID
  final String familyAccountId;
  final String invitedBy; // User ID of the person who sent the invitation
  final String invitedEmail;
  final String? invitedPhone;
  final InvitationType invitationType;
  final String invitationToken; // Unique token for the invitation link
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isAccepted;
  final bool isExpired;
  final String? acceptedByUserId;

  const FamilyInvitation({
    required this.id,
    required this.familyAccountId,
    required this.invitedBy,
    required this.invitedEmail,
    this.invitedPhone,
    required this.invitationType,
    required this.invitationToken,
    required this.createdAt,
    required this.expiresAt,
    this.isAccepted = false,
    this.isExpired = false,
    this.acceptedByUserId,
  });

  // Firestore -> Model
  factory FamilyInvitation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return FamilyInvitation(
      id: doc.id,
      familyAccountId: data['familyAccountId'] ?? '',
      invitedBy: data['invitedBy'] ?? '',
      invitedEmail: data['invitedEmail'] ?? '',
      invitedPhone: data['invitedPhone'],
      invitationType: InvitationType.values.firstWhere(
            (e) => e.name == data['invitationType'],
        orElse: () => InvitationType.email,
      ),
      invitationToken: data['invitationToken'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ??
          DateTime.now().add(Duration(days: 7)),
      isAccepted: data['isAccepted'] ?? false,
      isExpired: data['isExpired'] ?? false,
      acceptedByUserId: data['acceptedByUserId'],
    );
  }

  // Model -> Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'familyAccountId': familyAccountId,
      'invitedBy': invitedBy,
      'invitedEmail': invitedEmail,
      'invitedPhone': invitedPhone,
      'invitationType': invitationType.name,
      'invitationToken': invitationToken,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'isAccepted': isAccepted,
      'isExpired': isExpired,
      'acceptedByUserId': acceptedByUserId,
    };
  }

  // Check if invitation is valid
  bool get isValid => !isAccepted && !isExpired && DateTime.now().isBefore(expiresAt);

  // CopyWith method
  FamilyInvitation copyWith({
    String? id,
    String? familyAccountId,
    String? invitedBy,
    String? invitedEmail,
    String? invitedPhone,
    InvitationType? invitationType,
    String? invitationToken,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isAccepted,
    bool? isExpired,
    String? acceptedByUserId,
  }) {
    return FamilyInvitation(
      id: id ?? this.id,
      familyAccountId: familyAccountId ?? this.familyAccountId,
      invitedBy: invitedBy ?? this.invitedBy,
      invitedEmail: invitedEmail ?? this.invitedEmail,
      invitedPhone: invitedPhone ?? this.invitedPhone,
      invitationType: invitationType ?? this.invitationType,
      invitationToken: invitationToken ?? this.invitationToken,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isAccepted: isAccepted ?? this.isAccepted,
      isExpired: isExpired ?? this.isExpired,
      acceptedByUserId: acceptedByUserId ?? this.acceptedByUserId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    familyAccountId,
    invitedBy,
    invitedEmail,
    invitedPhone,
    invitationType,
    invitationToken,
    createdAt,
    expiresAt,
    isAccepted,
    isExpired,
    acceptedByUserId,
  ];
}