import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meditrack/bloc/medicine_bloc/medicine_bloc.dart';
import 'package:meditrack/bloc/dosage_bloc/dosage_bloc.dart';
import 'package:meditrack/bloc/family_bloc/family_bloc.dart';
import 'package:meditrack/model/dosage.dart';
import 'package:meditrack/style/colors.dart';
import 'package:meditrack/widgets/family_members_widget.dart';
import '../../../widgets/nerby_pharmacies_widget.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with AutomaticKeepAliveClientMixin, RouteAware {
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (user != null) {
      context.read<FamilyBloc>().add(LoadFamilyAccountEvent(user!.uid));
    }
  }

  void _loadData() {
    if (user != null) {
      context.read<MedicineBloc>().add(LoadMedicinesEvent(user!.uid));
      context.read<FamilyBloc>().add(LoadFamilyAccountEvent(user!.uid));
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
    super.build(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('User not logged in')));
    }

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      body: SingleChildScrollView(
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: isDarkMode ? Colors.grey.shade300 : AppColors.darkBlue,
                    ),
                  ),
                  TextSpan(
                    text: '${user?.displayName ?? 'User'}!',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Section 1: Medicines To Take Today
            Row(
              children: [
                Icon(
                  Icons.medication,
                  color: isDarkMode ? AppColors.primary.withOpacity(0.8) : AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Medicines To Take Today:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.grey.shade300 : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Dosage Cards
            BlocBuilder<MedicineBloc, MedicineState>(
              builder: (context, medState) {
                if (medState is MedicineLoadingState) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );
                }

                if (medState is MedicineErrorState) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        medState.errorMessage,
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey.shade400 : Colors.black87,
                        ),
                      ),
                    ),
                  );
                }

                if (medState is MedicineLoadedState) {
                  final medicines = medState.medicines;

                  if (medicines.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'No medicines found',
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey.shade400 : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  }

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    for (var med in medicines) {
                      context.read<DosageBloc>().add(LoadDosagesEvent(user!.uid, med.id));
                    }
                  });

                  return BlocBuilder<DosageBloc, DosageState>(
                    builder: (context, dosageState) {
                      if (dosageState is DosageLoadingState) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(color: AppColors.primary),
                          ),
                        );
                      }

                      if (dosageState is DosageErrorState) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              dosageState.errorMessage,
                              style: TextStyle(
                                color: isDarkMode ? Colors.grey.shade400 : Colors.black87,
                              ),
                            ),
                          ),
                        );
                      }

                      if (dosageState is DosageLoadedState) {
                        final allByMed = dosageState.dosagesByMedicine;
                        final today = DateTime.now();
                        final dosageWidgets = <Widget>[];

                        for (var med in medicines) {
                          final medDosages = allByMed[med.id] ?? [];
                          final todayDosages = medDosages.where((d) {
                            final start = d.startDate;
                            final end = d.endDate;
                            return !start.isAfter(today) && (end == null || !end.isBefore(today));
                          }).toList();

                          if (todayDosages.isEmpty) continue;

                          dosageWidgets.add(
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                              child: Text(
                                med.name.toUpperCase(),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: isDarkMode ? Colors.grey.shade300 : AppColors.darkBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );

                          for (var dosage in todayDosages) {
                            dosageWidgets.add(_buildDosageCard(med.id, dosage, isDarkMode));
                          }
                        }

                        if (dosageWidgets.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 48,
                                    color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No dosages scheduled for today',
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: dosageWidgets,
                        );
                      }

                      return const SizedBox();
                    },
                  );
                }

                return const SizedBox();
              },
            ),

            const SizedBox(height: 30),

            // Section 2: EXPIRED MEDICINES
            BlocBuilder<MedicineBloc, MedicineState>(
              builder: (context, medState) {
                if (medState is MedicineLoadedState) {
                  final now = DateTime.now();
                  final expiredMedicines = medState.medicines
                      .where((med) => med.dateExpired.isBefore(now))
                      .toList();

                  if (expiredMedicines.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.red.shade700,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Expired Medicines:',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.red.withOpacity(0.1),
                                Colors.orange.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${expiredMedicines.length}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      expiredMedicines.length == 1
                                          ? '1 medicine has expired'
                                          : '${expiredMedicines.length} medicines have expired',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...expiredMedicines.map((med) {
                                final daysExpired = now.difference(med.dateExpired).inDays;
                                return Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.red.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.medication,
                                        color: Colors.red.shade700,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              med.name,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: isDarkMode ? Colors.grey.shade300 : Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Expired $daysExpired day${daysExpired == 1 ? '' : 's'} ago',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.red.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    );
                  }
                }
                return const SizedBox.shrink();
              },
            ),

            // Section 3: Family Members
            const FamilyMembersWidget(),

            const SizedBox(height: 30),

            // Section 4: Nearby Pharmacies
            const NearbyPharmaciesWidget(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDosageCard(String medId, Dosage dosage, bool isDarkMode) {
    final today = DateTime.now();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dosage: ${dosage.dosage}, Frequency: ${dosage.frequency}',
              style: TextStyle(
                color: isDarkMode ? Colors.grey.shade300 : Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            ...List.generate(dosage.times.length, (index) {
              final timeData = dosage.times[index];
              final time = timeData['time'];

              DateTime? takenDate;
              final raw = timeData['takenDate'];
              if (raw != null) {
                takenDate = raw is DateTime ? raw : (raw as Timestamp).toDate();
              }

              final isTakenToday = takenDate != null &&
                  takenDate.year == today.year &&
                  takenDate.month == today.month &&
                  takenDate.day == today.day;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isTakenToday
                      ? Colors.green.withOpacity(0.1)
                      : (isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isTakenToday
                        ? Colors.green
                        : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isTakenToday ? Icons.check_circle : Icons.access_time,
                      color: isTakenToday ? Colors.green : AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        time,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.grey.shade300 : Colors.black87,
                        ),
                      ),
                    ),
                    if (isTakenToday)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Taken',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                    // Mark as Taken button
                      InkWell(
                        onTap: () => _markAsTaken(medId, dosage, index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Mark as Taken',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _markAsTaken(String medId, Dosage dosage, int timeIndex) async {
    try {
      // Get the medicine to check current quantity
      final medState = context.read<MedicineBloc>().state;
      if (medState is! MedicineLoadedState) return;

      final medicine = medState.medicines.firstWhere((m) => m.id == medId);

      // Check if medicine is in stock
      if (medicine.quantity <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${medicine.name} is out of stock!'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Mark the dosage as taken in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('medicines')
          .doc(medId)
          .collection('dosages')
          .doc(dosage.id)
          .update({
        'times': dosage.times.asMap().entries.map((entry) {
          if (entry.key == timeIndex) {
            return {
              'time': entry.value['time'],
              'takenDate': Timestamp.now(),
            };
          }
          return entry.value;
        }).toList(),
      });

      // Reduce medicine quantity by 1
      final newQuantity = medicine.quantity - 1;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('medicines')
          .doc(medId)
          .update({'quantity': newQuantity});

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${medicine.name} marked as taken! Quantity: $newQuantity'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Reload data to reflect changes
        context.read<MedicineBloc>().add(LoadMedicinesEvent(user!.uid));
        context.read<DosageBloc>().add(LoadDosagesEvent(user!.uid, medId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}