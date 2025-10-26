import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meditrack/style/colors.dart';

class Mainhome extends StatefulWidget {
  const Mainhome({super.key});

  @override
  State<Mainhome> createState() => _MainhomeState();
}

class _MainhomeState extends State<Mainhome> {
  final user = FirebaseAuth.instance.currentUser;
  final hour = DateTime.now().hour;

  String getGreeting() {
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    if (hour >= 17 && hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  Widget buildTimeRow(String medId, QueryDocumentSnapshot dosage, int index) {
    final timeData = (dosage['times'] as List)[index];

    final time = timeData['time'];
    final takenDate = (timeData['takenDate'] as Timestamp?)?.toDate();

    final now = DateTime.now();
    final isTakenToday = takenDate != null &&
        takenDate.year == now.year &&
        takenDate.month == now.month &&
        takenDate.day == now.day;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Time: $time'),
        TextButton.icon(
          icon: Icon(
            isTakenToday ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isTakenToday ? Colors.green : Colors.grey,
          ),
          label: Text(isTakenToday ? 'Taken' : 'Mark as Taken'),
          onPressed: isTakenToday
              ? null
              : () async {
                  try {
                    final updatedTimes = List<Map<String, dynamic>>.from(
                        dosage['times'].cast<Map<String, dynamic>>());
                    updatedTimes[index]['takenDate'] = Timestamp.now();

                    final medRef = FirebaseFirestore.instance
                        .collection('users')
                        .doc(user!.uid)
                        .collection('medicines')
                        .doc(medId);

                    final dosageRef = medRef.collection('dosages').doc(dosage.id);

                    print('Updating medicine quantity and marking time as taken...');

                    await FirebaseFirestore.instance.runTransaction((transaction) async {
                      final medSnap = await transaction.get(medRef);
                      final data = medSnap.data();

                      if (data == null) {
                        throw Exception('Medicine document does not exist');
                      }

                      final currentQuantity = data['quantity'];
                      if (currentQuantity == null || currentQuantity is! int) {
                        throw Exception('Invalid quantity field');
                      }

                      print('Current quantity before update: $currentQuantity');

                      if (currentQuantity > 0) {
                        transaction.update(medRef, {'quantity': currentQuantity - 1});
                        print('Quantity updated to: ${currentQuantity - 1}');
                      } else {
                        print('Quantity is zero or less, not updating');
                      }

                      transaction.update(dosageRef, {'times': updatedTimes});
                    });

                    print('Transaction completed successfully.');
                  } catch (e, stackTrace) {
                    print('Error in marking as taken: $e');
                    print(stackTrace);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to mark as taken: $e')),
                      );
                    }
                  }
                },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Center(child: Text('No user logged in'));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${getGreeting()}, ',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.darkBlue),
                  ),
                  TextSpan(
                    text: '${user?.displayName ?? 'User'}!',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Section Title
            Row(
              children: [
                Icon(Icons.medication, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Medicines To Take Today:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Medicine List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user!.uid)
                    .collection('medicines')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final medicines = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: medicines.length,
                    itemBuilder: (context, index) {
                      final med = medicines[index];
                      final medId = med.id;
                      final medName = med['name'] ?? 'Unnamed';

                      // Dosages
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(user!.uid)
                            .collection('medicines')
                            .doc(medId)
                            .collection('dosages')
                            .snapshots(),
                        builder: (context, dosageSnapshot) {
                          if (!dosageSnapshot.hasData) {
                            return const SizedBox();
                          }

                          final dosages = dosageSnapshot.data!.docs;
                          final now = DateTime.now();
                          final validDosages = <QueryDocumentSnapshot>[];

                          // Filter dosages for today
                          for (var d in dosages) {
                            final start = (d['startDate'] as Timestamp).toDate();
                            final end = (d['endDate'] as Timestamp?)?.toDate();

                            if (start.isBefore(now) && (end == null || now.isBefore(end))) {
                              validDosages.add(d);
                            }
                          }

                          if (validDosages.isEmpty) return const SizedBox();

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    medName.toString().toUpperCase(),
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: AppColors.darkBlue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 10),

                                  // Loop through valid dosages
                                  for (var dosage in validDosages)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Dosage: ${dosage['dosage']}, Frequency: ${dosage['frequency']}'),
                                        const SizedBox(height: 6),

                                        // mark times as taken
                                        if (dosage['times'] != null && dosage['times'] is List)
                                          Column(
                                            children: [
                                              for (int i = 0; i < (dosage['times'] as List).length; i++)
                                                buildTimeRow(medId, dosage, i),
                                            ],
                                          ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
