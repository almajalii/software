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
        .map(
          (snapshot) =>
          snapshot.docs.map((doc) => Medicine.fromFirestore(doc)).toList(),
    );
  }

  //2 addMedicines
  Future<void> addMedicine(String userId, Medicine medicine) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('medicines')
        .add(medicine.toFirestore());
  }

  //3 updateMedicines
  Future<void> updateMedicine(
      String userId,
      String medId,
      Medicine medicine,
      ) async {
    await firestore
        .collection('users')
        .doc(userId)
        .collection('medicines')
        .doc(medId)
        .update(medicine.toFirestore());
  }

  //4 Remove medicine (move to recycle bin)
  Future<void> removeMedicine(
      String userId,
      String medId,
      Medicine medicine,
      ) async {
    final medRef = firestore
        .collection('users')
        .doc(userId)
        .collection('medicines')
        .doc(medId);

    // 1. Move to recycle bin (top-level history collection)
    await firestore
        .collection('users')
        .doc(userId)
        .collection('history')
        .doc(medId)
        .set(medicine.toFirestore());

    // 2. Delete from main list
    await medRef.delete();
  }

  //5 Get removed medicines from recycle bin
  Stream<List<Medicine>> getRemovedMedicines(String userId) {
    return firestore
        .collection('users')
        .doc(userId)
        .collection('history')
        .snapshots()
        .map(
          (snapshot) =>
          snapshot.docs.map((doc) => Medicine.fromFirestore(doc)).toList(),
    );
  }

  //6 Permanently delete from recycle bin
  Future<void> deleteMedicine(String userId, String medId) async {
    await firestore
        .collection('users')
        .doc(userId)
        .collection('history')
        .doc(medId)
        .delete();
  }

  //7 decrement quantity by one
  Future<void> decrementMedicineQuantity(String userId, String medId) async {
    final docRef = firestore
        .collection('users')
        .doc(userId)
        .collection('medicines')
        .doc(medId);

    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final currentQty = snapshot['quantity'] ?? 0;

      if (currentQty > 0) {
        transaction.update(docRef, {'quantity': currentQty - 1});
      }
    });
  }

  //8 Search medicines by name
  Stream<List<Medicine>> searchMedicines(String userId, String query) {
    return firestore
        .collection('users')
        .doc(userId)
        .collection('medicines')
        .snapshots()
        .map((snapshot) {
      final allMeds =
      snapshot.docs.map((doc) => Medicine.fromFirestore(doc)).toList();
      if (query.isEmpty) return allMeds;
      return allMeds
          .where(
            (med) => med.name.toLowerCase().contains(query.toLowerCase()),
      )
          .toList();
    });
  }

  //9 Filter medicines by type
  Stream<List<Medicine>> getMedicinesByType(String userId, String type) {
    return firestore
        .collection('users')
        .doc(userId)
        .collection('medicines')
        .where('type', isEqualTo: type)
        .snapshots()
        .map(
          (snapshot) =>
          snapshot.docs.map((doc) => Medicine.fromFirestore(doc)).toList(),
    );
  }

  //10 Filter medicines by category
  Stream<List<Medicine>> getMedicinesByCategory(String userId, String category) {
    return firestore
        .collection('users')
        .doc(userId)
        .collection('medicines')
        .where('category', isEqualTo: category)
        .snapshots()
        .map(
          (snapshot) =>
          snapshot.docs.map((doc) => Medicine.fromFirestore(doc)).toList(),
    );
  }

  //11 Filter medicines by type AND category
  Stream<List<Medicine>> getMedicinesByTypeAndCategory(
      String userId, String type, String category) {
    return firestore
        .collection('users')
        .doc(userId)
        .collection('medicines')
        .where('type', isEqualTo: type)
        .where('category', isEqualTo: category)
        .snapshots()
        .map(
          (snapshot) =>
          snapshot.docs.map((doc) => Medicine.fromFirestore(doc)).toList(),
    );
  }

  //12 Advanced filter - combines search, type, and category
  Stream<List<Medicine>> filterMedicines({
    required String userId,
    String? searchQuery,
    String? type,
    String? category,
  }) {
    return firestore
        .collection('users')
        .doc(userId)
        .collection('medicines')
        .snapshots()
        .map((snapshot) {
      var allMeds = snapshot.docs.map((doc) => Medicine.fromFirestore(doc)).toList();

      // Apply search filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        allMeds = allMeds
            .where((med) =>
            med.name.toLowerCase().contains(searchQuery.toLowerCase()))
            .toList();
      }

      // Apply type filter
      if (type != null && type.isNotEmpty) {
        allMeds = allMeds.where((med) => med.type == type).toList();
      }

      // Apply category filter
      if (category != null && category.isNotEmpty) {
        allMeds = allMeds.where((med) => med.category == category).toList();
      }

      return allMeds;
    });
  }
}