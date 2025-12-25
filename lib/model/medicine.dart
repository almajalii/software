import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Medicine extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String type;
  final String category;
  final String notes;
  final int quantity;
  final DateTime dateAdded;
  final DateTime dateExpired;
  final String? imageUrl;

  const Medicine({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.category,
    required this.notes,
    required this.quantity,
    required this.dateAdded,
    required this.dateExpired,
    this.imageUrl,
  });

  factory Medicine.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Medicine(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      category: data['category'] ?? '',
      notes: data['notes'] ?? '',
      quantity: data['quantity'] ?? 0,
      dateAdded: (data['dateAdded'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateExpired: (data['dateExpired'] as Timestamp?)?.toDate() ?? DateTime.now().add(Duration(days: 365)),
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'type': type,
      'category': category,
      'notes': notes,
      'quantity': quantity,
      'dateAdded': Timestamp.fromDate(dateAdded),
      'dateExpired': Timestamp.fromDate(dateExpired),
      'imageUrl': imageUrl,
    };
  }

  Medicine copyWith({
    String? id,
    String? userId,
    String? name,
    String? type,
    String? category,
    String? notes,
    int? quantity,
    DateTime? dateAdded,
    DateTime? dateExpired,
    String? imageUrl,
  }) {
    return Medicine(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      quantity: quantity ?? this.quantity,
      dateAdded: dateAdded ?? this.dateAdded,
      dateExpired: dateExpired ?? this.dateExpired,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  List<Object?> get props => [id, userId, name, type, category, notes, quantity, dateAdded, dateExpired, imageUrl];
}