import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meditrack/model/dosage.dart';
import 'package:meditrack/style/colors.dart';
import 'package:meditrack/bloc/dosage_bloc/dosage_bloc.dart';

class DosageCard extends StatelessWidget {
  final Dosage dosage;
  final String medId; // <-- REQUIRED for delete

  const DosageCard({super.key, required this.dosage, required this.medId});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shadowColor: AppColors.lightGray,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- TITLE + DELETE BUTTON ----------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Dosage: ${dosage.dosage}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),

                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteDialog(context),
                ),
              ],
            ),

            const SizedBox(height: 4),
            Text("Frequency: ${dosage.frequency}"),
            Text("Start: ${dosage.startDate.toString().split(' ').first}"),
            Text("End: ${dosage.endDate?.toString().split(' ').first ?? 'N/A'}"),

            const SizedBox(height: 8),

            if (dosage.times.isNotEmpty)
              Wrap(
                spacing: 8,
                children:
                    dosage.times.map((t) {
                      final time = t['time'] ?? '';
                      final taken = t['taken'] ?? false;

                      return ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(backgroundColor: taken ? Colors.green : Colors.grey[300]),
                        child: Text(time.toString(), style: TextStyle(color: taken ? Colors.white : Colors.black)),
                      );
                    }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  // ------------------- DELETE CONFIRMATION -------------------
  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Delete dosage?"),
            content: const Text("Are you sure you want to delete this dosage?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              TextButton(
                onPressed: () {
                  final userId = FirebaseAuth.instance.currentUser!.uid;

                  context.read<DosageBloc>().add(
                    DeleteDosageEvent(
                      userId,
                      medId, // <-- FIXED: using medId passed from parent
                      dosage.id,
                    ),
                  );

                  Navigator.pop(context);
                },
                child: const Text("Delete", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }
}
