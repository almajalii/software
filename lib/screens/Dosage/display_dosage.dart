import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meditrack/bloc/medicine_bloc/medicine_bloc.dart';
import 'package:meditrack/bloc/dosage_bloc/dosage_bloc.dart';
import 'package:meditrack/style/colors.dart';
import 'package:meditrack/widgets/dosage_card.dart';
import 'package:meditrack/screens/Dosage/add_dosage.dart';

class DisplayDosage extends StatefulWidget {
  const DisplayDosage({super.key});

  @override
  State<DisplayDosage> createState() => _DisplayDosageState();
}

class _DisplayDosageState extends State<DisplayDosage> {
  final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    //loads the medicines
    context.read<MedicineBloc>().add(LoadMedicinesEvent(userId));
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Color(0xFF121212) : Colors.white,
      body: BlocBuilder<MedicineBloc, MedicineState>(
        builder: (context, medState) {
          if (medState is MedicineLoadingState) {
            return const Center(child: CircularProgressIndicator());
          } else if (medState is MedicineErrorState) {
            return Center(
              child: Text(
                medState.errorMessage,
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.black87,
                ),
              ),
            );
          } else if (medState is MedicineLoadedState) {
            final medicines = medState.medicines;
            if (medicines.isEmpty) {
              return Center(
                child: Text(
                  'No medicines found',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.black87,
                  ),
                ),
              );
            }

            // Load dosages once
            WidgetsBinding.instance.addPostFrameCallback((_) {
              //load dosages of each medicine.
              for (var med in medicines) {
                context.read<DosageBloc>().add(LoadDosagesEvent(userId, med.id));
              }
            });

            return BlocBuilder<DosageBloc, DosageState>(
              builder: (context, dosageState) {
                if (dosageState is DosageLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                } else if (dosageState is DosageErrorState) {
                  return Center(
                    child: Text(
                      dosageState.errorMessage,
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.black87,
                      ),
                    ),
                  );
                } else if (dosageState is DosageLoadedState) {
                  final allDosages = dosageState.dosagesByMedicine;

                  return ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children:
                    medicines.map((med) {
                      final medDosages = allDosages[med.id] ?? [];
                      if (medDosages.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(
                              med.name.toUpperCase(),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.grey[200] : AppColors.darkBlue,
                              ),
                            ),
                          ),
                          ...medDosages.map((d) => DosageCard(dosage: d, medId: med.id)),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddDosage()));
        },
        backgroundColor: AppColors.primary,
        child: Icon(Icons.add, color: AppColors.darkBlue),
      ),
    );
  }
}