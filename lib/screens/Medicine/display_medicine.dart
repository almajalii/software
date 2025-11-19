/* import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meditrack/bloc/medicine_bloc/medicine_bloc.dart';
import 'package:meditrack/screens/Medicine/add_medicine.dart';
import 'package:meditrack/widgets/MyTextField.dart';
import 'package:meditrack/style/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meditrack/widgets/medicine_card.dart';

class DisplayMedicine extends StatefulWidget {
  const DisplayMedicine({super.key});

  @override
  State<DisplayMedicine> createState() => _DisplayMedicineState();
}

class _DisplayMedicineState extends State<DisplayMedicine> {
  @override
  void initState() {
    super.initState();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    // Load medicines when the screen starts
    context.read<MedicineBloc>().add(LoadMedicinesEvent(userId));
  }

  @override
  Widget build(BuildContext context) {
    final myTextField = MyTextField();

    return Scaffold(
      body: BlocBuilder<MedicineBloc, MedicineState>(
        builder: (context, state) {
          if (state is MedicineLoadingState) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is MedicineErrorState) {
            return Center(child: Text(state.errorMessage));
          } else if (state is MedicineLoadedState) {
            final medicines = state.medicines;

            if (medicines.isEmpty) {
              return const Center(child: Text('No medicines found'));
            }

            return ListView.builder(
              itemCount: medicines.length,
              itemBuilder: (context, index) {
                final med = medicines[index];
                return MedicineCard(med: med, myTextField: myTextField);
              },
            );
          }
          return const SizedBox();
        },
      ),
      //add medicine button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddMedicine()));
        },
        child: Icon(Icons.add, color: AppColors.darkBlue),
      ),
    );
  }
}
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meditrack/bloc/medicine_bloc/medicine_bloc.dart';
import 'package:meditrack/screens/Medicine/add_medicine.dart';
import 'package:meditrack/widgets/MyTextField.dart';
import 'package:meditrack/style/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meditrack/widgets/medicine_card.dart';

class DisplayMedicine extends StatefulWidget {
  const DisplayMedicine({super.key});

  @override
  State<DisplayMedicine> createState() => _DisplayMedicineState();
}

class _DisplayMedicineState extends State<DisplayMedicine> {
  List medicinesFiltered = [];
  final myTextField = MyTextField();

  @override
  void initState() {
    super.initState();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    // Load medicines when the screen starts
    context.read<MedicineBloc>().add(LoadMedicinesEvent(userId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<MedicineBloc, MedicineState>(
        builder: (context, state) {
          if (state is MedicineLoadingState) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is MedicineErrorState) {
            return Center(child: Text(state.errorMessage));
          } else if (state is MedicineLoadedState) {
            final medicines = state.medicines;

            // Initially filtered = all medicines
            medicinesFiltered = medicines;

            if (medicines.isEmpty) {
              return const Center(child: Text('No medicines found'));
            }

            return Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SearchAnchor(
                    builder: (context, controller) {
                      return SearchBar(
                        controller: controller,
                        onTap: () => controller.openView(),
                        onChanged: (query) {
                          controller.openView();
                          setState(() {
                            medicinesFiltered = medicines
                                .where((med) => med.name
                                    .toLowerCase()
                                    .contains(query.toLowerCase()))
                                .toList();
                          });
                        },
                        leading: const Icon(Icons.search),
                        hintText: 'Search medicines...',
                        padding: const WidgetStatePropertyAll(
                          EdgeInsets.symmetric(horizontal: 16),
                        ),
                      );
                    },
                    suggestionsBuilder: (context, controller) {
                      return medicinesFiltered.map((med) {
                        return ListTile(
                          title: Text(med.name),
                          onTap: () {
                            setState(() {
                              controller.closeView(med.name);
                            });
                          },
                        );
                      }).toList();
                    },
                  ),
                ),

                // Medicine list
                Expanded(
                  child: ListView.builder(
                    itemCount: medicinesFiltered.length,
                    itemBuilder: (context, index) {
                      final med = medicinesFiltered[index];
                      return MedicineCard(med: med, myTextField: myTextField);
                    },
                  ),
                ),
              ],
            );
          }
          return const SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const AddMedicine()));
        },
        child: Icon(Icons.add, color: AppColors.darkBlue),
      ),
    );
  }
}
