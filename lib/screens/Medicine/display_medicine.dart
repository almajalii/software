import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meditrack/bloc/medicine_bloc/medicine_bloc.dart';
import 'package:meditrack/screens/Medicine/add_medicine.dart';
import 'package:meditrack/screens/Medicine/recycle_bin.dart';
import 'package:meditrack/widgets/MyTextField.dart';
import 'package:meditrack/style/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meditrack/widgets/medicine_card.dart';
import '../../model/medicine.dart';

class DisplayMedicine extends StatefulWidget {
  const DisplayMedicine({super.key});

  @override
  State<DisplayMedicine> createState() => _DisplayMedicineState();
}

class _DisplayMedicineState extends State<DisplayMedicine>
    with AutomaticKeepAliveClientMixin {
  //AutomaticKeepAliveClientMixin ensures that when this screen is part of a BottomNavigationBar tab, it doesn’t rebuild from scratch when you switch tabs.
  List<Medicine> medicinesFiltered = [];
  final myTextField = MyTextField();
  final TextEditingController searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final userId = FirebaseAuth.instance.currentUser!.uid;
    context.read<MedicineBloc>().add(LoadMedicinesEvent(userId));
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      body: BlocBuilder<MedicineBloc, MedicineState>(
        builder: (context, state) {
          if (state is MedicineLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is MedicineErrorState) {
            return Center(child: Text(state.errorMessage));
          }

          if (state is MedicineLoadedState) {
            final medicines = state.medicines;

            // Apply search filter
            final query = searchController.text.toLowerCase();
            medicinesFiltered =
                medicines
                    .where((med) => med.name.toLowerCase().contains(query))
                    .toList();

            return Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.recycling),
                    onPressed: () async {
                      // Open Recycle Bin as a full-screen modal
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (_) => RemovedMedicinesScreen(userId: userId),
                        ),
                      );
                      // Refresh medicines after coming back
                      context.read<MedicineBloc>().add(
                        LoadMedicinesEvent(userId),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search medicines...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none, // removes the border
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      // light gray background
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),
                    ),
                    onChanged: (query) {
                      setState(() {
                        medicinesFiltered =
                            medicines
                                .where(
                                  (med) => med.name.toLowerCase().contains(
                                    query.toLowerCase(),
                                  ),
                                )
                                .toList();
                      });
                    },
                  ),
                ),

                Expanded(
                  child:
                      medicinesFiltered.isEmpty
                          ? const Center(child: Text("No medicines found"))
                          : ListView.builder(
                            itemCount: medicinesFiltered.length,
                            itemBuilder: (context, index) {
                              return MedicineCard(
                                med: medicinesFiltered[index],
                                myTextField: myTextField,
                              );
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
            context,
            MaterialPageRoute(builder: (_) => const AddMedicine()),
          );
        },
        child: Icon(Icons.add, color: AppColors.darkBlue),
      ),
    );
  }
}
