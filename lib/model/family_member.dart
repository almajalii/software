import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum MemberRole {
  owner,
  member,
}

enum InvitationStatus {
  pending,
  accepted,
  declined,
}

class FamilyMember extends Equatable {
  final String id; // Firestore document ID
  final String familyAccountId;
  final String userId; // Reference to the user's main account
  final String displayName;
  final String email;
  final String? phoneNumber;
  final MemberRole role;
  final InvitationStatus invitationStatus;
  final DateTime invitedAt;
  final DateTime? acceptedAt;

  const FamilyMember({
    required this.id,
    required this.familyAccountId,
    required this.userId,
    required this.displayName,
    required this.email,
    this.phoneNumber,
    required this.role,
    required this.invitationStatus,
    required this.invitedAt,
    this.acceptedAt,
  });

  // Firestore -> Model
  factory FamilyMember.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return FamilyMember(
      id: doc.id,
      familyAccountId: data['familyAccountId'] ?? '',
      userId: data['userId'] ?? '',
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'],
      role: MemberRole.values.firstWhere(
            (e) => e.name == data['role'],
        orElse: () => MemberRole.member,
      ),
      invitationStatus: InvitationStatus.values.firstWhere(
            (e) => e.name == data['invitationStatus'],
        orElse: () => InvitationStatus.pending,
      ),
      invitedAt: (data['invitedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      acceptedAt: (data['acceptedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Model -> Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'familyAccountId': familyAccountId,
      'userId': userId,
      'displayName': displayName,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role.name,
      'invitationStatus': invitationStatus.name,
      'invitedAt': Timestamp.fromDate(invitedAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
    };
  }

  // CopyWith method
  FamilyMember copyWith({
    String? id,
    String? familyAccountId,
    String? userId,
    String? displayName,
    String? email,
    String? phoneNumber,
    MemberRole? role,
    InvitationStatus? invitationStatus,
    DateTime? invitedAt,
    DateTime? acceptedAt,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      familyAccountId: familyAccountId ?? this.familyAccountId,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      invitationStatus: invitationStatus ?? this.invitationStatus,
      invitedAt: invitedAt ?? this.invitedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    familyAccountId,
    userId,
    displayName,
    email,
    phoneNumber,
    role,
    invitationStatus,
    invitedAt,
    acceptedAt,
  ];
}