import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meditrack/model/dosage.dart';
import 'package:meditrack/style/colors.dart';
import 'package:meditrack/bloc/dosage_bloc/dosage_bloc.dart';

class DosageCard extends StatelessWidget {
  final Dosage dosage;
  final String medId;

  const DosageCard({super.key, required this.dosage, required this.medId});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shadowColor: isDarkMode ? Colors.black45 : AppColors.lightGray,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with dosage info and delete button
            Row(
              children: [
                // Dosage pill icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.medication,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Dosage info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dosage.dosage,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDarkMode ? Colors.grey[200] : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dosage.frequency,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: Colors.red[400],
                  onPressed: () => _showDeleteDialog(context),
                  tooltip: 'Delete dosage',
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Date range
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Text(
                  '${dosage.startDate.toString().split(' ').first} - ${dosage.endDate?.toString().split(' ').first ?? 'Ongoing'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Times section
            if (dosage.times.isNotEmpty) ...[
              Text(
                'Times',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),

              // Time chips - SMALLER AND CLEANER
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: dosage.times.asMap().entries.map((entry) {
                  final index = entry.key;
                  final t = entry.value;
                  final time = t['time'] ?? '';
                  final taken = t['taken'] ?? false;

                  return _buildTimeChip(
                    context,
                    time,
                    taken,
                    index,
                    isDarkMode,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeChip(
      BuildContext context,
      String time,
      bool taken,
      int index,
      bool isDarkMode,
      ) {
    return InkWell(
      onTap: taken
          ? null
          : () => _markAsTaken(context, index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: taken
              ? (isDarkMode ? Colors.green[900]?.withOpacity(0.3) : Colors.green[50])
              : (isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[100]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: taken
                ? (isDarkMode ? Colors.green[700]! : Colors.green[300]!)
                : (isDarkMode ? const Color(0xFF3C3C3C) : Colors.grey[300]!),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              taken ? Icons.check_circle : Icons.schedule,
              size: 14,
              color: taken
                  ? (isDarkMode ? Colors.green[400] : Colors.green[700])
                  : (isDarkMode ? Colors.grey[500] : Colors.grey[600]),
            ),
            const SizedBox(width: 6),
            Text(
              time,
              style: TextStyle(
                fontSize: 12,
                fontWeight: taken ? FontWeight.w600 : FontWeight.normal,
                color: taken
                    ? (isDarkMode ? Colors.green[300] : Colors.green[800])
                    : (isDarkMode ? Colors.grey[300] : Colors.grey[800]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _markAsTaken(BuildContext context, int timeIndex) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    context.read<DosageBloc>().add(
      MarkDosageTimeTakenEvent(userId, medId, dosage.id, timeIndex),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Marked as taken'),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
        title: Text(
          'Delete Dosage?',
          style: TextStyle(
            color: isDarkMode ? Colors.grey[200] : Colors.black87,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this dosage schedule?',
          style: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final userId = FirebaseAuth.instance.currentUser?.uid;
              if (userId != null) {
                context.read<DosageBloc>().add(
                  DeleteDosageEvent(userId, medId, dosage.id),
                );
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}