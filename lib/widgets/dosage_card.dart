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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shadowColor: isDarkMode ? Colors.black45 : AppColors.lightGray,
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
                Text(
                  "Dosage: ${dosage.dosage}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDarkMode ? Colors.grey[200] : Colors.black87,
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteDialog(context),
                ),
              ],
            ),

            const SizedBox(height: 4),
            Text(
              "Frequency: ${dosage.frequency}",
              style: TextStyle(
                color: isDarkMode ? Colors.grey[300] : Colors.black87,
              ),
            ),
            Text(
              "Start: ${dosage.startDate.toString().split(' ').first}",
              style: TextStyle(
                color: isDarkMode ? Colors.grey[300] : Colors.black87,
              ),
            ),
            Text(
              "End: ${dosage.endDate?.toString().split(' ').first ?? 'N/A'}",
              style: TextStyle(
                color: isDarkMode ? Colors.grey[300] : Colors.black87,
              ),
            ),

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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: taken
                          ? Colors.green
                          : (isDarkMode ? Color(0xFF3C3C3C) : Colors.grey[300]),
                      disabledBackgroundColor: taken
                          ? Colors.green
                          : (isDarkMode ? Color(0xFF3C3C3C) : Colors.grey[300]),
                    ),
                    child: Text(
                      time.toString(),
                      style: TextStyle(
                        color: taken
                            ? Colors.white
                            : (isDarkMode ? Colors.grey[300] : Colors.black),
                      ),
                    ),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
        backgroundColor: isDarkMode ? Color(0xFF2C2C2C) : Colors.white,
        title: Text(
          "Delete dosage?",
          style: TextStyle(
            color: isDarkMode ? Colors.grey[200] : Colors.black87,
          ),
        ),
        content: Text(
          "Are you sure you want to delete this dosage?",
          style: TextStyle(
            color: isDarkMode ? Colors.grey[300] : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
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