import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meditrack/bloc/dosage_bloc/dosage_bloc.dart';
import 'package:meditrack/bloc/medicine_bloc/medicine_bloc.dart';
import 'package:meditrack/bloc/family_bloc/family_bloc.dart';
import 'package:meditrack/model/medicine.dart';
import 'package:meditrack/model/family_member.dart';
import 'package:meditrack/style/colors.dart';
import 'package:meditrack/widgets/MyTextField.dart';
import 'package:meditrack/widgets/Time.dart';
import 'package:meditrack/widgets/app_bar.dart';

class AddDosage extends StatefulWidget {
  const AddDosage({super.key});

  @override
  State<AddDosage> createState() => _AddDosageState();
}

class _AddDosageState extends State<AddDosage> {
  final GlobalKey<FormState> formKey = GlobalKey();
  final TextEditingController medDosage = TextEditingController();
  final TextEditingController medFrequency = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final MyTextField myTextField = MyTextField();
  final User? userCredential = FirebaseAuth.instance.currentUser;

  bool hasEndDate = false;
  Medicine? selectedMedicine;
  List<String> selectedTimes = [];

  // NEW: Family notification variables
  bool notifyFamily = false;
  List<String> selectedFamilyMemberIds = [];
  List<FamilyMember> availableFamilyMembers = [];

  @override
  void initState() {
    super.initState();
    // Load family account to check if user has family
    if (userCredential != null) {
      context.read<FamilyBloc>().add(LoadFamilyAccountEvent(userCredential!.uid));
    }
  }

  void submitDosage() {
    if (!formKey.currentState!.validate() ||
        selectedMedicine == null ||
        selectedTimes.isEmpty ||
        startDateController.text.isEmpty ||
        (hasEndDate && endDateController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please fill all required fields and add at least one time",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final dosageData = {
      'dosage': medDosage.text.trim(),
      'frequency': medFrequency.text.trim(),
      'times': selectedTimes
          .map((t) => {'time': t, 'taken': false, 'takenDate': null})
          .toList(),
      'startDate': Timestamp.fromDate(DateTime.parse(startDateController.text)),
      'endDate': hasEndDate
          ? Timestamp.fromDate(DateTime.parse(endDateController.text))
          : null,
      'addedAt': Timestamp.fromDate(DateTime.now()),
      'medicineId': selectedMedicine!.id,
      // NEW: Add family notification fields
      'notifyFamilyMembers': notifyFamily,
      'selectedFamilyMemberIds': selectedFamilyMemberIds,
    };

    // Dispatch AddDosageEvent to DosageBloc
    context.read<DosageBloc>().add(
      AddDosageEvent(
        userCredential?.uid ?? '',
        selectedMedicine!.id,
        dosageData,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          notifyFamily && selectedFamilyMemberIds.isNotEmpty
              ? "✓ Dosage added! Family members will be notified"
              : "✓ Dosage added successfully!",
        ),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.of(context).pop();
  }

  Future<void> _addTime(BuildContext context) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      final formattedTime = pickedTime.format(context);
      if (!selectedTimes.contains(formattedTime)) {
        setState(() => selectedTimes.add(formattedTime));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This time is already added'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _showFamilyMemberSelector(BuildContext context, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      const Icon(Icons.family_restroom, color: AppColors.primary),
                      const SizedBox(width: 12),
                      const Text(
                        'Select Family Members to Notify',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Family members list
                  if (availableFamilyMembers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No family members available'),
                    )
                  else
                    ...availableFamilyMembers.map((member) {
                      // Don't show current user
                      if (member.userId == userCredential?.uid) {
                        return const SizedBox.shrink();
                      }

                      final isSelected = selectedFamilyMemberIds.contains(member.id);

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (checked) {
                          setModalState(() {
                            if (checked == true) {
                              selectedFamilyMemberIds.add(member.id);
                            } else {
                              selectedFamilyMemberIds.remove(member.id);
                            }
                          });
                          setState(() {}); // Update parent state too
                        },
                        title: Text(member.displayName),
                        subtitle: Text(member.email),
                        secondary: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Text(
                            member.displayName.isNotEmpty
                                ? member.displayName[0].toUpperCase()
                                : 'F',
                            style: const TextStyle(color: AppColors.primary),
                          ),
                        ),
                        activeColor: AppColors.primary,
                      );
                    }),

                  const SizedBox(height: 16),

                  // Done button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Done (${selectedFamilyMemberIds.length} selected)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      appBar: MyAppBar.build(context, () {}),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Center(
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Pill icon
                  const Icon(
                    FontAwesomeIcons.pills,
                    color: AppColors.primary,
                    size: 80,
                  ),
                  const SizedBox(height: 10),

                  Text(
                    'Add Dosage Schedule',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.grey[200] : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Medicine Dropdown
                  BlocBuilder<MedicineBloc, MedicineState>(
                    builder: (context, state) {
                      if (state is MedicineLoadingState) {
                        return const CircularProgressIndicator(
                          color: AppColors.primary,
                        );
                      } else if (state is MedicineLoadedState) {
                        return SizedBox(
                          width: 300,
                          child: DropdownButtonFormField<Medicine>(
                            value: selectedMedicine,
                            dropdownColor: isDarkMode
                                ? const Color(0xFF2C2C2C)
                                : Colors.white,
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                            items: state.medicines
                                .map(
                                  (med) => DropdownMenuItem(
                                value: med,
                                child: Text(
                                  med.name,
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            )
                                .toList(),
                            onChanged: (val) {
                              setState(() => selectedMedicine = val);

                              if (val != null) {
                                context.read<DosageBloc>().add(
                                  LoadDosagesEvent(
                                    userCredential?.uid ?? '',
                                    val.id,
                                  ),
                                );
                              }
                            },
                            validator: (value) => value == null ? "*" : null,
                            decoration: InputDecoration(
                              labelText: "Select Medicine",
                              labelStyle: TextStyle(
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[700],
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              fillColor: isDarkMode
                                  ? const Color(0xFF2C2C2C)
                                  : AppColors.lightGray,
                              filled: true,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDarkMode
                                      ? const Color(0xFF3C3C3C)
                                      : const Color(0xFFC8D1DC),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  const SizedBox(height: 20),

                  // Dosage
                  SizedBox(
                    width: 300,
                    child: myTextField.buildTextField(
                      "Dosage (e.g., 500mg, 2 tablets)",
                      medDosage,
                      validator: (value) => value!.isEmpty ? "*" : null,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Frequency
                  SizedBox(
                    width: 300,
                    child: myTextField.buildTextField(
                      "Frequency (e.g., 3x daily, Twice a day)",
                      medFrequency,
                      validator: (value) => value!.isEmpty ? "*" : null,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Start Date
                  SizedBox(
                    width: 300,
                    child: ExpiryDatePicker(
                      controller: startDateController,
                      labelText: "Start Date",
                      onDateChanged: (date) {
                        startDateController.text =
                        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // End Date Checkbox
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: hasEndDate,
                        onChanged: (val) => setState(() => hasEndDate = val!),
                        activeColor: AppColors.primary,
                      ),
                      Text(
                        "Has End Date?",
                        style: TextStyle(
                          color: isDarkMode
                              ? Colors.grey[300]
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),

                  if (hasEndDate)
                    SizedBox(
                      width: 300,
                      child: ExpiryDatePicker(
                        controller: endDateController,
                        labelText: "End Date",
                        onDateChanged: (date) {
                          endDateController.text =
                          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                        },
                      ),
                    ),

                  const SizedBox(height: 30),

                  // Times section
                  Text(
                    'Times',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.grey[300] : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),

                  OutlinedButton.icon(
                    onPressed: () => _addTime(context),
                    icon: const Icon(Icons.access_time, size: 18),
                    label: const Text('Add Time'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Selected times
                  if (selectedTimes.isNotEmpty)
                    Container(
                      width: 300,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF2C2C2C)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDarkMode
                              ? const Color(0xFF3C3C3C)
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: selectedTimes.map((time) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primary,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.schedule,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  time,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () {
                                    setState(() => selectedTimes.remove(time));
                                  },
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  const SizedBox(height: 30),

                  // NEW: Family Notifications Section
                  BlocBuilder<FamilyBloc, FamilyState>(
                    builder: (context, familyState) {
                      bool hasFamilyAccount = false;

                      if (familyState is FamilyAccountLoadedState) {
                        hasFamilyAccount = true;
                        availableFamilyMembers = familyState.members;
                      }

                      if (!hasFamilyAccount) {
                        return const SizedBox.shrink(); // Hide if no family
                      }

                      return Container(
                        width: 300,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF2C2C2C)
                              : Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with switch
                            Row(
                              children: [
                                const Icon(
                                  Icons.family_restroom,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Notify Family Members',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode
                                          ? Colors.grey[200]
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                                Switch(
                                  value: notifyFamily,
                                  onChanged: (value) {
                                    setState(() => notifyFamily = value);
                                    if (!value) {
                                      selectedFamilyMemberIds.clear();
                                    }
                                  },
                                  activeColor: AppColors.primary,
                                ),
                              ],
                            ),

                            if (notifyFamily) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Family members will receive notifications when it\'s time to take this medication.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Select members button
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _showFamilyMemberSelector(context, isDarkMode),
                                icon: const Icon(Icons.people, size: 18),
                                label: Text(
                                  selectedFamilyMemberIds.isEmpty
                                      ? 'Select Family Members'
                                      : '${selectedFamilyMemberIds.length} member(s) selected',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(color: AppColors.primary),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  // Submit Button
                  SizedBox(
                    height: 50,
                    width: 300,
                    child: ElevatedButton(
                      onPressed: submitDosage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Add Dosage",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    medDosage.dispose();
    medFrequency.dispose();
    startDateController.dispose();
    endDateController.dispose();
    super.dispose();
  }
}