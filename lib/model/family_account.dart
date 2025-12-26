import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class FamilyAccount extends Equatable {
  final String id; // Firestore document ID
  final String familyName;
  final String ownerId; // The user who created the family account
  final String primaryContactEmail;
  final String? primaryContactPhone;
  final DateTime createdAt;
  final List<String> memberIds; // List of user IDs who are members

  const FamilyAccount({
    required this.id,
    required this.familyName,
    required this.ownerId,
    required this.primaryContactEmail,
    this.primaryContactPhone,
    required this.createdAt,
    required this.memberIds,
  });

  // Firestore -> Model
  factory FamilyAccount.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return FamilyAccount(
      id: doc.id,
      familyName: data['familyName'] ?? '',
      ownerId: data['ownerId'] ?? '',
      primaryContactEmail: data['primaryContactEmail'] ?? '',
      primaryContactPhone: data['primaryContactPhone'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      memberIds: List<String>.from(data['memberIds'] ?? []),
    );
  }

  // Model -> Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'familyName': familyName,
      'ownerId': ownerId,
      'primaryContactEmail': primaryContactEmail,
      'primaryContactPhone': primaryContactPhone,
      'createdAt': Timestamp.fromDate(createdAt),
      'memberIds': memberIds,
    };
  }

  // CopyWith method
  FamilyAccount copyWith({
    String? id,
    String? familyName,
    String? ownerId,
    String? primaryContactEmail,
    String? primaryContactPhone,
    DateTime? createdAt,
    List<String>? memberIds,
  }) {
    return FamilyAccount(
      id: id ?? this.id,
      familyName: familyName ?? this.familyName,
      ownerId: ownerId ?? this.ownerId,
      primaryContactEmail: primaryContactEmail ?? this.primaryContactEmail,
      primaryContactPhone: primaryContactPhone ?? this.primaryContactPhone,
      createdAt: createdAt ?? this.createdAt,
      memberIds: memberIds ?? this.memberIds,
    );
  }

  @override
  List<Object?> get props => [
    id,
    familyName,
    ownerId,
    primaryContactEmail,
    primaryContactPhone,
    createdAt,
    memberIds,
  ];
}