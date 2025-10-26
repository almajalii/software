import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:meditrack/classes/ExpiryReminder.dart';
import 'package:meditrack/classes/MyAppBar.dart';
import 'package:meditrack/classes/MyTextField.dart';
import 'package:meditrack/classes/Time.dart';
import 'package:meditrack/style/colors.dart';
import 'package:meditrack/screens/Dosage/ShowDosage.dart';

class addDosage extends StatefulWidget {
  const addDosage({super.key});

  @override
  State<addDosage> createState() => _addDosageState();
}

class _addDosageState extends State<addDosage> {
  GlobalKey<FormState> formKey = GlobalKey();
  TextEditingController MedDosage = TextEditingController();
  TextEditingController MedFrequency = TextEditingController();
  TextEditingController StartDateController = TextEditingController();
  TextEditingController EndDateController = TextEditingController();
  final myTextField = MyTextField();
  List<String> selectedTimes = [];
  bool hasEndDate = false;
  String? selectedMedId;
  String? selectedMedName;
  User? userCredential = FirebaseAuth.instance.currentUser;

  Future<void> AddDosage() async {
    try {
      // Convert StartDate and EndDate strings to DateTime
      DateTime? startDate = DateTime.tryParse(StartDateController.text);
      DateTime? endDate = hasEndDate ? DateTime.tryParse(EndDateController.text) : null;

      if (startDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invalid start date")));
        return;
      }
      // Convert selectedTimes to list of maps with 'time' and 'taken' fields
      final timesWithTaken = selectedTimes.map((time) => {'time': time, 'taken': false}).toList();

      await FirebaseFirestore.instance
          .collection("users")
          .doc(userCredential?.uid)
          .collection("medicines")
          .doc(selectedMedId)
          .collection("dosages")
          .add({
            'dosage': MedDosage.text.trim(),
            'frequency': MedFrequency.text.trim(),
            'times': timesWithTaken, // <-- Save as list of maps with taken status
            'startDate': Timestamp.fromDate(startDate), // <-- Save as Timestamp
            'endDate': endDate != null ? Timestamp.fromDate(endDate) : null, // <-- Save as Timestamp or null
            'addedAt': FieldValue.serverTimestamp(),
          });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Added successfully!")));

      Navigator.of(context).pop(MaterialPageRoute(builder: (context) => Show()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Add failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar.build(context, () => ExpiryReminder.showExpiredMedsSheet(context)),
      body: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Form(
            key: formKey,
            child: Center(
              child: Column(
                children: [
                  SizedBox(height: 20),
                  //Icon
                  Icon(FontAwesomeIcons.capsules, color: AppColors.primary, size: 80),
                  SizedBox(height: 20),
                  // Medicine Dropdown
                  StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(userCredential?.uid)
                            .collection('medicines')
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return CircularProgressIndicator();
                      final medicines = snapshot.data!.docs;
                      //add items To the list
                      List<DropdownMenuItem<String>> items = [];
                      for (var med in medicines) {
                        final name = med['name'] ?? 'Unnamed';
                        items.add(DropdownMenuItem(value: med.id, child: Text(name)));
                      }
                      String? getMedicineNameById(List medicines, String? id) {
                        for (var med in medicines) {
                          if (med.id == id) return med['name'];
                        }
                        return null;
                      }

                      return Container(
                        width: 300,
                        color: Colors.white,
                        //the dropdown after the addition of medicines
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: "Select Medicine",
                            fillColor: AppColors.lightGray,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          value: selectedMedId,
                          onChanged: (val) {
                            setState(() {
                              selectedMedId = val;
                              selectedMedName = getMedicineNameById(medicines, val);
                            });
                          },
                          validator: (value) {
                            if (value==null) {
                              return "*";
                            }
                            return null;
                          },
                          items: items,
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 20),
                  // Dosage
                  SizedBox(
                    width: 300,
                    child: myTextField.buildTextField(
                      "Medicine Dosage",
                      MedDosage,
                      validator: (value) {
                        if (value!.isEmpty) return "*";
                        final numericRegex = RegExp(r'^[0-9]+$');
                        if (!numericRegex.hasMatch(value)) {
                          return "Please enter only numbers";
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: 20),
                  // Frequency
                  SizedBox(
                    width: 300,
                    child: myTextField.buildTextField(
                      "Medicine Frequency",
                      MedFrequency,
                      validator: (value) {
                        if (value!.isEmpty) return "*";
                        final numericRegex = RegExp(r'^[0-9]+$');
                        if (!numericRegex.hasMatch(value)) {
                          return "Please enter only numbers";
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: 20),
                  // Start Date
                  SizedBox(
                    width: 300,
                    child: ExpiryDatePicker(
                      controller: StartDateController,
                      labelText: "Start Date",
                      dateFormat: "yyyy-mm-dd",
                      onDateChanged: (date) {
                        EndDateController.text =
                            "${date.year}-"
                            "${date.month.toString().padLeft(2, '0')}-"
                            "${date.day.toString().padLeft(2, '0')}";
                      },
                    ),
                  ),
                  SizedBox(height: 20),
                  // Has End Date?->checkBox
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Checkbox(value: hasEndDate, onChanged: (value) => setState(() => hasEndDate = value!)),
                      Text("Has End Date?"),
                    ],
                  ),
                  // End Date
                  if (hasEndDate)
                    SizedBox(
                      width: 300,
                      child: TextFormField(
                        controller: EndDateController,
                        decoration: InputDecoration(
                          labelText: "End Date",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          fillColor: AppColors.lightGray,
                          filled: true,
                        ),
                        readOnly: true, //
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            EndDateController.text =
                                "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                            setState(() {}); // update UI if needed
                          }
                        },
                      ),
                    ),

                  if (hasEndDate) SizedBox(height: 10),
                  // Add Time Button
                  SizedBox(
                    width:150,
                    child: ElevatedButton(
                      onPressed: () async {
                        TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                        if (pickedTime != null) {
                          String formattedTime = pickedTime.format(context);
                          if (!selectedTimes.contains(formattedTime)) {
                            //if not already there
                            setState(() => selectedTimes.add(formattedTime));
                          }
                        }
                      },
                      child: Text("+ Time", style: TextStyle(fontSize: 20, color: Colors.white)),
                    ),
                  ),
                  SizedBox(height: 10),
                  // Show selected times with Chip UI
                  Wrap(
                    spacing: 8, //between chips
                    runSpacing: 8, //bewteen lines
                    children: [
                      for (var time in selectedTimes)
                        Chip(
                          label: Text(time),
                          deleteIcon: Icon(Icons.close),
                          onDeleted: () {
                            setState(() => selectedTimes.remove(time));
                          },
                        ),
                    ],
                  ),
                  // Submit Button
                  SizedBox(
                    height: 50,
                    width: 300,
                    child: ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate() && selectedMedId != null && selectedTimes.isNotEmpty) {
                          AddDosage();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Please fill all required fields and add at least one time")),
                          );
                        }
                      },
                      child: Text('Add Dosage', style: Theme.of(context).textTheme.titleLarge),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
