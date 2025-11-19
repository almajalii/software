import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:meditrack/bloc/medicine_bloc/medicine_bloc.dart';
import 'package:meditrack/model/medicine.dart';
import 'package:meditrack/widgets/ExpiryReminder.dart';
import 'package:meditrack/widgets/app_bar.dart';
import 'package:meditrack/widgets/MyTextField.dart';
import 'package:meditrack/widgets/Time.dart';
import 'package:meditrack/style/colors.dart';
//User Input → Form Validation → Bloc Event → Repository → Firestore → UI Update
class AddMedicine extends StatefulWidget {
  const AddMedicine({super.key});

  @override
  State<AddMedicine> createState() => _AddMedicineState();
}

class _AddMedicineState extends State<AddMedicine> {
  final GlobalKey<FormState> formKey = GlobalKey();
  final TextEditingController MedName = TextEditingController();
  final TextEditingController MedNotes = TextEditingController();
  final TextEditingController MedType = TextEditingController();
  final TextEditingController ExpDate = TextEditingController();
  final TextEditingController Quantity = TextEditingController();
  final myTextField = MyTextField();

  final User? userCredential = FirebaseAuth.instance.currentUser;

  String? medicineValidator(value) {
    if (value!.isEmpty) return "*";
    return null;
  }

  void submitMedicine() {
  if (!formKey.currentState!.validate()){
    ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Medicine added successfully!')),
  );
  return ;
  }

  final newMedicine = Medicine(
    id: '', // Firestore generates ID
    userId: userCredential?.uid ?? '',
    name: MedName.text.trim(),
    type: MedType.text.trim(),
    notes: MedNotes.text.trim(),
    quantity: int.tryParse(Quantity.text.trim()) ?? 0,
    dateAdded: DateTime.now(),
    dateExpired: ExpDate.text.isNotEmpty
        ? DateTime.tryParse(ExpDate.text.split('-').reversed.join('-')) ??
            DateTime.now()
        : DateTime.now().add(const Duration(days: 365)),
  );
  //ADDS EVENT -> ADDMEDICINE
  context.read<MedicineBloc>().add(
    AddMedicineEvent(userCredential?.uid ?? '', newMedicine),
  );

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Medicine added successfully!')),
  );

  Navigator.of(context).pop();
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
                  const SizedBox(height: 20),
                  const Icon(FontAwesomeIcons.warehouse,
                      color: AppColors.primary, size: 80),
                  const SizedBox(height: 50),
                  SizedBox(
                    width: 300,
                    child: myTextField.buildTextField(
                        "Medicine Name", MedName,
                        validator: medicineValidator),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 300,
                    child: myTextField.buildTextField(
                        "Medicine Type", MedType,
                        validator: medicineValidator),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                      width: 300,
                      child: myTextField.buildTextField("Notes", MedNotes)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 300,
                    child: myTextField.buildTextField("Quantity", Quantity,
                        validator: (value) {
                      if (value!.isEmpty) return "*";
                      if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                        return "Please enter only numbers";
                      }
                      return null;
                    }),
                  ),
                  const SizedBox(height: 20),
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
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 50,
                    width: 300,
                    //BUTTON
                    child: ElevatedButton(
                      onPressed: submitMedicine,
                      child: Text('Add',
                          style: Theme.of(context).textTheme.titleLarge),
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
}
