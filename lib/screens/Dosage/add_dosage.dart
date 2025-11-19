import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meditrack/bloc/dosage_bloc/dosage_bloc.dart';
import 'package:meditrack/bloc/medicine_bloc/medicine_bloc.dart';
import 'package:meditrack/model/medicine.dart';
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
  final TextEditingController MedDosage = TextEditingController();
  final TextEditingController MedFrequency = TextEditingController();
  final TextEditingController StartDateController = TextEditingController();
  final TextEditingController EndDateController = TextEditingController();
  final MyTextField myTextField = MyTextField();
  final User? userCredential = FirebaseAuth.instance.currentUser;

  bool hasEndDate = false;
  Medicine? selectedMedicine;
  List<String> selectedTimes = [];

  void submitDosage() {
    if (!formKey.currentState!.validate() ||
        selectedMedicine == null ||
        selectedTimes.isEmpty ||
        StartDateController.text.isEmpty ||
        (hasEndDate && EndDateController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please fill all required fields and add at least one time",
          ),
        ),
      );
      return;
    }

    final dosageData = {
      'dosage': MedDosage.text.trim(),
      'frequency': MedFrequency.text.trim(),
      'times':
          selectedTimes
              .map((t) => {'time': t, 'taken': false, 'takenDate': null})
              .toList(),
      'startDate': Timestamp.fromDate(DateTime.parse(StartDateController.text)),
      'endDate':
          hasEndDate
              ? Timestamp.fromDate(DateTime.parse(EndDateController.text))
              : null,
      'addedAt': Timestamp.fromDate(DateTime.now()),
      'medicineId': selectedMedicine!.id,
    };

    // Dispatch AddDosageEvent to DosageBloc
    context.read<DosageBloc>().add(
      AddDosageEvent(
        userCredential?.uid ?? '',
        selectedMedicine!.id,
        dosageData,
      ),
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Dosage added successfully!")));

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar.build(context, () {}),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Center(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Icon(
                    FontAwesomeIcons.pills,
                    color: AppColors.primary,
                    size: 80,
                  ),
                  const SizedBox(height: 20),

                  // Medicine Dropdown
                  BlocBuilder<MedicineBloc, MedicineState>(
                    builder: (context, state) {
                      if (state is MedicineLoadingState) {
                        return const CircularProgressIndicator();
                      } else if (state is MedicineLoadedState) {
                        return SizedBox(
                          width: 300,
                          child: DropdownButtonFormField<Medicine>(

                            value: selectedMedicine,
                            items:
                                state.medicines
                                    .map(
                                      (med) => DropdownMenuItem(
                                        value: med,
                                        child: Text(med.name),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (val) {
                              setState(() => selectedMedicine = val);

                              // Load dosages for selected medicine
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
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              fillColor: AppColors.lightGray,
                              filled: true,
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
                      "Dosage",
                      MedDosage,
                      validator: (value) => value!.isEmpty ? "*" : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Frequency
                  SizedBox(
                    width: 300,
                    child: myTextField.buildTextField(
                      "Frequency",
                      MedFrequency,
                      validator: (value) => value!.isEmpty ? "*" : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Start Date
                  SizedBox(
                    width: 300,
                    child: ExpiryDatePicker(
                      controller: StartDateController,
                      labelText: "Start Date",
                      onDateChanged: (date) {
                        StartDateController.text =
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
                      ),
                      const Text("Has End Date?"),
                    ],
                  ),
                  if (hasEndDate)
                    SizedBox(
                      width: 300,
                      child: ExpiryDatePicker(
                        controller: EndDateController,
                        labelText: "End Date",
                        onDateChanged: (date) {
                          EndDateController.text =
                              "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                        },
                      ),
                    ),
                  const SizedBox(height: 20),
                  // Time Picker
                  SizedBox(width: 150, child: TimePicker(context)),
                  const SizedBox(height: 10),
                  // Show selected times
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        selectedTimes
                            .map(
                              (t) => Chip(
                                label: Text(t),
                                onDeleted:
                                    () =>
                                        setState(() => selectedTimes.remove(t)),
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 20),
                  // Submit Button
                  SizedBox(
                    height: 50,
                    width: 300,
                    child: ElevatedButton(
                      onPressed: submitDosage,
                      child: const Text("Add Dosage"),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  ElevatedButton TimePicker(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (pickedTime != null) {
          final formattedTime = pickedTime.format(context);
          if (!selectedTimes.contains(formattedTime)) {
            setState(() => selectedTimes.add(formattedTime));
          }
        }
      },
      child: const Text("+ Time"),
    );
  }
}
