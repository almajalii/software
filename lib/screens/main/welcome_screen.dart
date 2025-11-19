import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meditrack/bloc/medicine_bloc/medicine_bloc.dart';
import 'package:meditrack/bloc/dosage_bloc/dosage_bloc.dart';
import 'package:meditrack/model/dosage.dart';
import 'package:meditrack/style/colors.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      context.read<MedicineBloc>().add(LoadMedicinesEvent(user!.uid));
    }
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    if (hour >= 17 && hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(body: Center(child: Text('User not logged in')));
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

            Expanded(
              child: BlocBuilder<MedicineBloc, MedicineState>(
                builder: (context, medState) {
                  if (medState is MedicineLoadingState) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (medState is MedicineErrorState) {
                    return Center(child: Text(medState.errorMessage));
                  }

                  if (medState is MedicineLoadedState) {
                    final medicines = medState.medicines;

                    if (medicines.isEmpty) {
                      return const Center(child: Text('No medicines found'));
                    }

                    // Load all dosages after medicines load
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      for (var med in medicines) {
                        context.read<DosageBloc>().add(LoadDosagesEvent(user!.uid, med.id));
                      }
                    });

                    return BlocBuilder<DosageBloc, DosageState>(
                      builder: (context, dosageState) {
                        if (dosageState is DosageLoadingState) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (dosageState is DosageErrorState) {
                          return Center(child: Text(dosageState.errorMessage));
                        }

                        if (dosageState is DosageLoadedState) {
                          final allByMed = dosageState.dosagesByMedicine;
                          final today = DateTime.now();

                          return ListView(
                            children:
                                medicines.map((med) {
                                  final medDosages = allByMed[med.id] ?? [];

                                  final todayDosages =
                                      medDosages.where((d) {
                                        final start = d.startDate;
                                        final end = d.endDate;
                                        return !start.isAfter(today) && (end == null || !end.isBefore(today));
                                      }).toList();

                                  if (todayDosages.isEmpty) {
                                    return const SizedBox();
                                  }

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        child: Text(
                                          med.name.toUpperCase(),
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: AppColors.darkBlue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      ...todayDosages.map((dosage) => _buildDosageCard(med.id, dosage)),
                                    ],
                                  );
                                }).toList(),
                          );
                        }

                        return const SizedBox();
                      },
                    );
                  }

                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDosageCard(String medId, Dosage dosage) {
    final today = DateTime.now();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dosage: ${dosage.dosage}, Frequency: ${dosage.frequency}'),
            const SizedBox(height: 10),

            ...List.generate(dosage.times.length, (index) {
              final timeData = dosage.times[index];
              final time = timeData['time'];

              DateTime? takenDate;
              final raw = timeData['takenDate'];
              if (raw != null) {
                takenDate = raw is DateTime ? raw : raw.toDate();
              }

              final isTakenToday =
                  takenDate != null &&
                  takenDate.year == today.year &&
                  takenDate.month == today.month &&
                  takenDate.day == today.day;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Time: $time"),
                  TextButton.icon(
                    icon: Icon(
                      isTakenToday ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: isTakenToday ? Colors.green : Colors.grey,
                    ),
                    label: Text(isTakenToday ? "Taken" : "Mark as Taken"),
                    onPressed:
                        isTakenToday
                            ? null
                            : () {
                              context.read<DosageBloc>().add(
                                MarkDosageTimeTakenEvent(user!.uid, medId, dosage.id, index),
                              );
                            },
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
