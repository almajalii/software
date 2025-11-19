import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:meditrack/bloc/medicine_bloc/medicine_bloc.dart';
import 'package:meditrack/model/medicine.dart';
import 'package:meditrack/widgets/MyTextField.dart';
import 'package:meditrack/widgets/Time.dart';
import 'package:meditrack/style/colors.dart';

class MedicineCard extends StatelessWidget {
  const MedicineCard({super.key, required this.med, required this.myTextField});
  final Medicine med;
  final MyTextField myTextField;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.all(20),
      shadowColor: AppColors.lightGray,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ListTile(
        //name
        title: Text(med.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20)),
        //type
        subtitle: Text('Type: ${med.type}\nQuantity: ${med.quantity}'),
        leading: Icon(FontAwesomeIcons.capsules, color: AppColors.primary),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Edit
            EditButton(context),
            // Delete
            DeleteButton(context),
          ],
        ),
        onTap: () {
          DisplayMedicineDialog(context);
        },
      ),
    );
  }

  IconButton DeleteButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.delete, color: Colors.red),
      onPressed: () {
        //add event->delete
        context.read<MedicineBloc>().add(DeleteMedicineEvent(med.userId, med.id));
      },
    );
  }

  IconButton EditButton(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.edit, color: AppColors.primary),
      onPressed: () {
        TextEditingController nameController = TextEditingController(text: med.name);
        TextEditingController typeController = TextEditingController(text: med.type);
        TextEditingController quantityController = TextEditingController(text: med.quantity.toString());
        TextEditingController notesController = TextEditingController(text: med.notes);
        TextEditingController expiryController = TextEditingController(
          text:
              "${med.dateExpired.day.toString().padLeft(2, '0')}-${med.dateExpired.month.toString().padLeft(2, '0')}-${med.dateExpired.year}",
        );

        EditMedicineDialog(
          context,
          nameController,
          typeController,
          notesController,
          quantityController,
          expiryController,
        );
      },
    );
  }

  Future<dynamic> DisplayMedicineDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: AppColors.white,
            title: const Text('Medicine Details'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${med.name}'),
                Text('Type: ${med.type}'),
                Text('Quantity: ${med.quantity}'),
                Text('Notes: ${med.notes}'),
                Text('Expiry Date: ${med.dateExpired.day}-${med.dateExpired.month}-${med.dateExpired.year}'),
              ],
            ),
            actions: [TextButton(child: const Text('Close'), onPressed: () => Navigator.of(context).pop())],
          ),
    );
  }

  Future<dynamic> EditMedicineDialog(
    BuildContext context,
    TextEditingController nameController,
    TextEditingController typeController,
    TextEditingController notesController,
    TextEditingController quantityController,
    TextEditingController expiryController,
  ) {
    return showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: AppColors.white,
            title: const Text('Edit Medicine'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  myTextField.buildTextField('Name', nameController),
                  SizedBox(height: 10),
                  myTextField.buildTextField('Type', typeController),
                  SizedBox(height: 10),
                  myTextField.buildTextField('Notes', notesController),
                  SizedBox(height: 10),
                  myTextField.buildTextField('Quantity', quantityController),
                  SizedBox(height: 10),
                  ExpiryDatePicker(
                    controller: expiryController,
                    labelText: "Expiry Date",
                    onDateChanged: (date) {
                      expiryController.text =
                          "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop()),
              ElevatedButton(
                child: const Text('Save'),
                onPressed: () {
                  final updatedMedicine = Medicine(
                    id: med.id,
                    userId: med.userId,
                    name: nameController.text.trim(),
                    type: typeController.text.trim(),
                    notes: notesController.text.trim(),
                    quantity: int.tryParse(quantityController.text) ?? 0,
                    dateAdded: med.dateAdded,
                    dateExpired:
                        DateTime.tryParse(expiryController.text.split('-').reversed.join('-')) ?? med.dateExpired,
                  );
                  //add event-> update
                  context.read<MedicineBloc>().add(UpdateMedicineEvent(med.userId, med.id, updatedMedicine));
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
    );
  }
}
