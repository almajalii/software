import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'medicine.dart';

class Dosage extends Equatable {
  final String id; //firestore id
  final String medicineId; //parent medicine id
  final Medicine? medicine;
  final String dosage;
  final String frequency;
  final List<Map<String, dynamic>> times; // Each map: {'time': '08:00 AM', 'takenDate': Timestamp?}
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime addedAt;

  // NEW: Family notification fields
  final bool notifyFamilyMembers; // Enable/disable family notifications
  final List<String> selectedFamilyMemberIds; // Which family members to notify

  const Dosage({
    required this.id,
    required this.medicineId,
    this.medicine,
    required this.dosage,
    required this.frequency,
    required this.times,
    required this.startDate,
    this.endDate,
    required this.addedAt,
    this.notifyFamilyMembers = false, // Default: disabled
    this.selectedFamilyMemberIds = const [], // Default: empty list
  });

  // Firestore -> Model
  factory Dosage.fromFirestore(DocumentSnapshot doc, {Medicine? parentMedicine}) {
    final data = doc.data() as Map<String, dynamic>;

    // Convert each 'times' entry to ensure 'takenDate' is a Timestamp or null
    final timesData = (data['times'] as List<dynamic>? ?? []).map((e) {
      final map = Map<String, dynamic>.from(e);

      if (map['takenDate'] != null && map['takenDate'] is! Timestamp) {
        try {
          map['takenDate'] = Timestamp.fromDate(DateTime.parse(map['takenDate'].toString()));
        } catch (_) {
          map['takenDate'] = null;
        }
      }
      return map;
    }).toList();

    return Dosage(
      id: doc.id,
      medicineId: data['medicineId'] ?? parentMedicine?.id ?? "",
      medicine: parentMedicine,
      dosage: data['dosage'] ?? '',
      frequency: data['frequency'] ?? '',
      times: timesData,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null ? (data['endDate'] as Timestamp).toDate() : null,
      addedAt: data['addedAt'] != null ? (data['addedAt'] as Timestamp).toDate() : DateTime.now(),
      // NEW: Read family notification fields
      notifyFamilyMembers: data['notifyFamilyMembers'] ?? false,
      selectedFamilyMemberIds: List<String>.from(data['selectedFamilyMemberIds'] ?? []),
    );
  }

  // Convert Dosage object to Firestore-compatible map
  Map<String, dynamic> toFirestore() {
    final timesData = times.map((t) {
      return {
        'time': t['time'],
        'takenDate': t['takenDate'] != null
            ? (t['takenDate'] is Timestamp ? t['takenDate'] : Timestamp.fromDate(t['takenDate']))
            : null,
      };
    }).toList();

    return {
      'medicineId': medicineId,
      'dosage': dosage,
      'frequency': frequency,
      'times': timesData,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'addedAt': Timestamp.fromDate(addedAt),
      // NEW: Save family notification fields
      'notifyFamilyMembers': notifyFamilyMembers,
      'selectedFamilyMemberIds': selectedFamilyMemberIds,
    };
  }

  // CopyWith method
  Dosage copyWith({
    String? id,
    String? medicineId,
    Medicine? medicine,
    String? dosage,
    String? frequency,
    List<Map<String, dynamic>>? times,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? addedAt,
    bool? notifyFamilyMembers,
    List<String>? selectedFamilyMemberIds,
  }) {
    return Dosage(
      id: id ?? this.id,
      medicineId: medicineId ?? this.medicineId,
      medicine: medicine ?? this.medicine,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      times: times ?? this.times,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      addedAt: addedAt ?? this.addedAt,
      notifyFamilyMembers: notifyFamilyMembers ?? this.notifyFamilyMembers,
      selectedFamilyMemberIds: selectedFamilyMemberIds ?? this.selectedFamilyMemberIds,
    );
  }

  @override
  List<Object?> get props => [
    id,
    medicineId,
    medicine,
    dosage,
    frequency,
    times,
    startDate,
    endDate,
    addedAt,
    notifyFamilyMembers,
    selectedFamilyMemberIds,
  ];
}