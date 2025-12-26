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
import '../../repository/medicine_constants.dart';

class DisplayMedicine extends StatefulWidget {
  const DisplayMedicine({super.key});

  @override
  State<DisplayMedicine> createState() => _DisplayMedicineState();
}

class _DisplayMedicineState extends State<DisplayMedicine>
    with AutomaticKeepAliveClientMixin {
  List<Medicine> medicinesFiltered = [];
  final myTextField = MyTextField();
  final TextEditingController searchController = TextEditingController();

  String? selectedType;
  String? selectedCategory;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final userId = FirebaseAuth.instance.currentUser!.uid;
    context.read<MedicineBloc>().add(LoadMedicinesEvent(userId));
  }

  List<Medicine> _applyFilters(List<Medicine> medicines) {
    return medicines.where((med) {
      final matchesSearch = searchController.text.isEmpty ||
          med.name.toLowerCase().contains(searchController.text.toLowerCase());
      final matchesType = selectedType == null || med.type == selectedType;
      final matchesCategory = selectedCategory == null || med.category == selectedCategory;

      return matchesSearch && matchesType && matchesCategory;
    }).toList();
  }

  void _clearFilters() {
    setState(() {
      selectedType = null;
      selectedCategory = null;
      searchController.clear();
      medicinesFiltered = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Color(0xFF121212) : Colors.white,
      body: BlocBuilder<MedicineBloc, MedicineState>(
        builder: (context, state) {
          if (state is MedicineLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is MedicineErrorState) {
            return Center(
              child: Text(
                state.errorMessage,
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.black87,
                ),
              ),
            );
          }

          if (state is MedicineLoadedState) {
            final medicines = state.medicines;

            // Apply filters
            medicinesFiltered = _applyFilters(medicines);

            return Column(
              children: [
                // Top bar with recycle bin
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(
                      Icons.recycling,
                      color: isDarkMode ? Colors.grey[400] : Colors.black87,
                    ),
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RemovedMedicinesScreen(userId: userId),
                        ),
                      );
                      context.read<MedicineBloc>().add(LoadMedicinesEvent(userId));
                    },
                  ),
                ),

                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    controller: searchController,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.search,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      hintText: 'Search medicines...',
                      hintStyle: TextStyle(
                        color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDarkMode ? Color(0xFF2C2C2C) : Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),
                    ),
                    onChanged: (query) {
                      setState(() {
                        // Trigger rebuild which will apply filters
                      });
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // Filter chips row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      // Type filter
                      Expanded(
                        child: PopupMenuButton<String>(
                          color: isDarkMode ? Color(0xFF2C2C2C) : Colors.white,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: selectedType != null
                                  ? AppColors.primary.withOpacity(0.2)
                                  : (isDarkMode ? Color(0xFF2C2C2C) : Colors.grey[200]),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selectedType != null
                                    ? AppColors.primary
                                    : (isDarkMode ? Color(0xFF3C3C3C) : Colors.grey[300]!),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.category,
                                  size: 18,
                                  color: selectedType != null
                                      ? AppColors.primary
                                      : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    selectedType ?? 'Type',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: selectedType != null
                                          ? AppColors.primary
                                          : (isDarkMode ? Colors.grey[400] : Colors.grey[700]),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (selectedType != null) const SizedBox(width: 4),
                                if (selectedType != null)
                                  Icon(Icons.close, size: 14, color: AppColors.primary),
                              ],
                            ),
                          ),
                          itemBuilder: (context) => [
                            PopupMenuItem<String>(
                              value: null,
                              child: Text(
                                'All Types',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                            ...medicineTypes.map((type) => PopupMenuItem<String>(
                              value: type,
                              child: Text(
                                type,
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                            )),
                          ],
                          onSelected: (value) {
                            setState(() {
                              selectedType = value;
                            });
                          },
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Category filter
                      Expanded(
                        child: PopupMenuButton<String>(
                          color: isDarkMode ? Color(0xFF2C2C2C) : Colors.white,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: selectedCategory != null
                                  ? AppColors.teal.withOpacity(0.2)
                                  : (isDarkMode ? Color(0xFF2C2C2C) : Colors.grey[200]),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selectedCategory != null
                                    ? AppColors.teal
                                    : (isDarkMode ? Color(0xFF3C3C3C) : Colors.grey[300]!),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.label,
                                  size: 18,
                                  color: selectedCategory != null
                                      ? AppColors.teal
                                      : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    selectedCategory ?? 'Category',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: selectedCategory != null
                                          ? AppColors.teal
                                          : (isDarkMode ? Colors.grey[400] : Colors.grey[700]),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (selectedCategory != null) const SizedBox(width: 4),
                                if (selectedCategory != null)
                                  Icon(Icons.close, size: 14, color: AppColors.teal),
                              ],
                            ),
                          ),
                          itemBuilder: (context) => [
                            PopupMenuItem<String>(
                              value: null,
                              child: Text(
                                'All Categories',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                            ...medicineCategories.map((category) => PopupMenuItem<String>(
                              value: category,
                              child: Text(
                                category,
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                            )),
                          ],
                          onSelected: (value) {
                            setState(() {
                              selectedCategory = value;
                            });
                          },
                        ),
                      ),

                      // Clear filters button
                      if (selectedType != null || selectedCategory != null || searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear_all, color: Colors.red),
                          onPressed: _clearFilters,
                          tooltip: 'Clear all filters',
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Results count
                if (selectedType != null || selectedCategory != null || searchController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      '${medicinesFiltered.length} result(s) found',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // Medicine list
                Expanded(
                  child: medicinesFiltered.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No medicines found',
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        if (selectedType != null || selectedCategory != null || searchController.text.isNotEmpty)
                          TextButton(
                            onPressed: _clearFilters,
                            child: const Text('Clear filters'),
                          ),
                      ],
                    ),
                  )
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
        heroTag: 'medicine_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddMedicine()),
          );
        },
        backgroundColor: AppColors.primary,
        child: Icon(Icons.add, color: AppColors.darkBlue),
      ),
    );
  }
}