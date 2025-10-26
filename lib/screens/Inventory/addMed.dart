import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:meditrack/classes/ExpiryReminder.dart';
import 'package:meditrack/classes/MyAppBar.dart';
import 'package:meditrack/classes/MyTextField.dart';
import 'package:meditrack/classes/Time.dart';
import 'package:meditrack/screens/Inventory/ShowMed.dart';
import 'package:meditrack/style/colors.dart';

class addMed extends StatefulWidget {
  addMed({super.key});

  @override
  State<addMed> createState() => _addMedState();
}

class _addMedState extends State<addMed> {
  GlobalKey<FormState> formKey = GlobalKey();
  TextEditingController MedName = TextEditingController();
  TextEditingController MedNotes = TextEditingController();
  TextEditingController MedType = TextEditingController();
  TextEditingController ExpDate = TextEditingController();
  TextEditingController Quantity = TextEditingController();
  DateTime? selectedDate;
  bool reminderEnabled = false;
  final myTextField = MyTextField();

  User? userCredential = FirebaseAuth.instance.currentUser;

 Future<void> AddMdedicine() async {
  try {
    await FirebaseFirestore.instance.collection('users').doc(userCredential?.uid).collection('medicines').add({
      'userId': userCredential?.uid,
      'name': MedName.text.trim(),
      'type': MedType.text.trim(),
      'notes': MedNotes.text.trim(),
      'quantity': int.tryParse(Quantity.text.trim()) ?? 0,  // <-- convert to int here
      'addedAt': FieldValue.serverTimestamp(),
      'expiryDate': ExpDate.text.trim(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added successfully! Redirecting to home...')),
    );

    await Future.delayed(Duration(milliseconds: 300));
    Navigator.of(context).pop(MaterialPageRoute(builder: (context) => ShowInventory()));
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Adding failed: $e')));
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar.build(context, () => ExpiryReminder()),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Center(
              child: Column(
                children: [
                  SizedBox(height: 20),
                  //Inventory Icon
                  Icon(FontAwesomeIcons.warehouse, color: AppColors.primary, size: 80),
                  SizedBox(height: 50),
                  // Medicine Name
                  SizedBox(
                    width: 300,
                    child: myTextField.buildTextField("Medicine Name", MedName, validator: medValidator),
                  ),
                  SizedBox(height: 20),
                  //Medicine Type
                  SizedBox(
                    width: 300,
                    child: myTextField.buildTextField("Medicine Type", MedType, validator: medValidator),
                  ),
                  SizedBox(height: 20),
                  //Medicine notes
                  SizedBox(width: 300, child: myTextField.buildTextField("Notes", MedNotes)),
                  SizedBox(height: 20),
                  // Medicine Quantity
                  SizedBox(
                    width: 300,
                    child: myTextField.buildTextField(
                      "Quantity",
                      Quantity,
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
                  // Expiry Date->ShowDatePicker
                  SizedBox(
                    width: 300,
                    child: ExpiryDatePicker(
                      controller: ExpDate,
                      labelText: "Expiry Date",
                      onDateChanged: (date) {
                        ExpDate.text =
                            "${date.day.toString().padLeft(2, '0')}-"
                            "${date.month.toString().padLeft(2, '0')}-"
                            "${date.year}";
                      },
                    ),
                  ),
                  SizedBox(height: 20),
                  // Save Button
                  SizedBox(
                    height: 50,
                    width: 300,
                    child: ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          AddMdedicine();
                        }
                      },
                      child: Text('Add', style: Theme.of(context).textTheme.titleLarge),
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

  String? medValidator(value) {
    if (value!.isEmpty) return "*";
    return null;
  }
}
