import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

//represent a medicine item exactly the way it exists inside Firestore
class Medicine extends Equatable {
  final String id; //Firestore doc ID
  final String userId; //owner
  final String name;
  final String type;
  final String category;
  final String notes;
  final int quantity;
  final DateTime dateAdded;
  final DateTime dateExpired;

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
  });

  //firestore->model
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
      //timestamps -> dateTime
    );
  }

  //model->firestore
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
      //datetime ->timestamps
    };
  }

  @override
  List<Object> get props => [id, userId, name, type, category, notes, quantity, dateAdded, dateExpired];
}
