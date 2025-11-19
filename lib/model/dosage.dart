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
  });

  // Firestore -> Model
  factory Dosage.fromFirestore(DocumentSnapshot doc, {Medicine? parentMedicine}) {
    final data = doc.data() as Map<String, dynamic>; //reads the doc data

    // Convert each 'times' entry to ensure 'takenDate' is a Timestamp or null
    final timesData =
        (data['times'] as List<dynamic>? ?? []).map((e) {
          //times->list (go through each item in the list)
          final map = Map<String, dynamic>.from(e);

          if (map['takenDate'] != null && map['takenDate'] is! Timestamp) {
            // Try to convert string to Timestamp
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
      endDate: data['endDate'] != null ? (data['endDate'] as Timestamp).toDate() : null, //optional
      addedAt: data['addedAt'] != null ? (data['addedAt'] as Timestamp).toDate() : DateTime.now(), //optional
    );
  }

  // Convert Dosage object to Firestore-compatible map
  Map<String, dynamic> toFirestore() {
    final timesData =
        times.map((t) {
          //go through each entry in the list and convert it for Firestore
          return {
            'time': t['time'],
            'takenDate':
                t['takenDate'] != null
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
    );
  }

  @override
  List<Object?> get props => [id, medicineId, medicine, dosage, frequency, times, startDate, endDate, addedAt];
}
