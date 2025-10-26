import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:meditrack/screens/Dosage/addDosage.dart';
import 'package:meditrack/style/colors.dart';

class Show extends StatefulWidget {
  const Show({super.key});

  @override
  State<Show> createState() => _ShowState();
}

class _ShowState extends State<Show> {
  User? user = FirebaseAuth.instance.currentUser;

  // Confirm delete
  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.lightGray,
            title: const Text("Delete Dosage"),
            content: const Text("Are you sure you want to delete this dosage?"),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Cancel")),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Delete", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(body: Center(child: Text('User not logged in')));
    }

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("users").doc(user!.uid).collection("medicines").snapshots(),
        builder: (context, medicineSnapshot) {
          if (medicineSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (medicineSnapshot.hasError) {
            return const Center(child: Text('Error loading medicines'));
          }

          if (!medicineSnapshot.hasData || medicineSnapshot.data == null) {
            return const Center(child: Text('No medicine data found'));
          }

          final medicines = medicineSnapshot.data!.docs;

          if (medicines.isEmpty) {
            return const Center(child: Text('No medicines found'));
          }

          return ListView.builder(
            itemCount: medicines.length,
            itemBuilder: (context, index) {
              final medicine = medicines[index];
              final medicineId = medicine.id;
              final medicineData = medicine.data() as Map<String, dynamic>;

              return StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection("users")
                        .doc(user!.uid)
                        .collection("medicines")
                        .doc(medicineId)
                        .collection("dosages")
                        .snapshots(),
                builder: (context, dosageSnapshot) {
                  if (dosageSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (dosageSnapshot.hasError) {
                    return const Center(child: Text('Error loading dosages'));
                  }

                  if (!dosageSnapshot.hasData || dosageSnapshot.data == null) {
                    return const SizedBox(height: 10);
                  }

                  final dosages = dosageSnapshot.data!.docs;

                  if (dosages.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          medicineData['name'] ?? 'Unnamed Medicine',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: dosages.length,
                        itemBuilder: (context, index) {
                          final dosage = dosages[index];
                          final data = dosage.data() as Map<String, dynamic>;

                          return Card(
                            color: Colors.white,
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shadowColor: AppColors.lightGray,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                            child: Container(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(FontAwesomeIcons.pills, color: AppColors.primary),
                                      const Spacer(),
                                      IconButton(
                                        color: AppColors.error,
                                        icon: const Icon(Icons.delete),
                                        onPressed: () async {
                                          final confirm = await _confirmDelete(context);
                                          if (confirm == true) {
                                            await FirebaseFirestore.instance
                                                .collection("users")
                                                .doc(user!.uid)
                                                .collection("medicines")
                                                .doc(medicineId)
                                                .collection("dosages")
                                                .doc(dosage.id)
                                                .delete();
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text("Frequency: ${data['frequency'] ?? 'Unknown'}"),
                                  Text(
                                    "Start Date: ${data['startDate'] != null ? (data['startDate'] as Timestamp).toDate().toString().split(' ').first : 'N/A'}",
                                  ),
                                  Text(
                                    "End Date: ${data['endDate'] != null ? (data['endDate'] as Timestamp).toDate().toString().split(' ').first : 'N/A'}",
                                  ),
                                  if (data['times'] != null && data['times'] is List)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        for (var time in data['times'])
                                          Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                                            child: Row(
                                              children: [
                                                const Text('•  '),
                                                Text(time is Map ? time['time'].toString() : time.toString()),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const addDosage()));
        },
        child: Icon(Icons.add, color: AppColors.darkBlue),
      ),
    );
  }
}
