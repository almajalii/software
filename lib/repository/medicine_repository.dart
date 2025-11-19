//middle layer between your Firestore database and your BLoC
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meditrack/model/medicine.dart';

class MedicineRepository {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  //1 getMedicines
  Stream<List<Medicine>> getMedicines(String userId) {
    return firestore
        .collection('users')
        .doc(userId)
        .collection('medicines')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Medicine.fromFirestore(doc)).toList());
    //Converts each Firestore document into a Medicine object
  }

  //2 addMedicines
  Future<void> addMedicine(String userId, Medicine medicine) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('medicines')
        .add(medicine.toFirestore());
    //Converts the Medicine object into a Firestore-friendly Map<String, dynamic>
  }

  //3 updateMedicines
  Future<void> updateMedicine(String userId, String medId, Medicine medicine) async {
    //Uses the medId to locate the document.
    await firestore.collection('users').doc(userId).collection('medicines').doc(medId).update(medicine.toFirestore());
  }

  //4 delete medicines
  Future<void> deleteMedicine(String userId, String medId) async {
    await firestore.collection('users').doc(userId).collection('medicines').doc(medId).delete();
  }
}
