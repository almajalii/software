import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:meditrack/bloc/medicine_bloc/medicine_bloc.dart';
import 'package:meditrack/model/medicine.dart';
import 'package:meditrack/widgets/MyTextField.dart';
import 'package:meditrack/widgets/Time.dart';
import 'package:meditrack/style/colors.dart';
import 'package:meditrack/widgets/MyDropdownField.dart';

import '../repository/medicine_constants.dart';

class MedicineCard extends StatefulWidget {
  const MedicineCard({super.key, required this.med, required this.myTextField});
  final Medicine med;
  final MyTextField myTextField;

  @override
  State<MedicineCard> createState() => _MedicineCardState();
}

class _MedicineCardState extends State<MedicineCard> {
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
        title: Text(widget.med.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20)),
        //type
        subtitle: Text('Type: ${widget.med.type}\nQuantity: ${widget.med.quantity}'),
        leading: Icon(FontAwesomeIcons.capsules, color: AppColors.primary),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Edit
            EditButton(context),
            // Delete
            RemoveButton(context),
          ],
        ),
        onTap: () {
          DisplayMedicineDialog(context);
        },
      ),
    );
  }

  IconButton RemoveButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.delete, color: Colors.red),
      onPressed: () {
        //add event->delete
        context.read<MedicineBloc>().add(RemoveMedicineEvent(widget.med.userId, widget.med.id, widget.med));
      },
    );
  }

  IconButton EditButton(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.edit, color: AppColors.primary),
      onPressed: () {
        TextEditingController nameController = TextEditingController(text: widget.med.name);
        TextEditingController typeController = TextEditingController(text: widget.med.type);
        TextEditingController categoryController = TextEditingController(text: widget.med.category);
        TextEditingController quantityController = TextEditingController(text: widget.med.quantity.toString());
        TextEditingController notesController = TextEditingController(text: widget.med.notes);
        TextEditingController expiryController = TextEditingController(
          text:
              "${widget.med.dateExpired.day.toString().padLeft(2, '0')}-${widget.med.dateExpired.month.toString().padLeft(2, '0')}-${widget.med.dateExpired.year}",
        );

        EditMedicineDialog(
          context,
          nameController,
          typeController,
          categoryController,
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
                Text('Name: ${widget.med.name}'),
                Text('Type: ${widget.med.type}'),
                Text('Category: ${widget.med.category}'),
                Text('Quantity: ${widget.med.quantity}'),
                Text('Notes: ${widget.med.notes}'),
                Text('Expiry Date: ${widget.med.dateExpired.day}-${widget.med.dateExpired.month}-${widget.med.dateExpired.year}'),
              ],
            ),
            actions: [TextButton(child: const Text('Close'), onPressed: () => Navigator.of(context).pop())],
          ),
    );
  }

  Future<dynamic> EditMedicineDialog(BuildContext context,
      TextEditingController nameController,
      TextEditingController typeController,
      TextEditingController categoryController,
      TextEditingController notesController,
      TextEditingController quantityController,
      TextEditingController expiryController,) {
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
                  widget.myTextField.buildTextField('Name', nameController),
                  SizedBox(height: 10),
                  // widget.myTextField.buildTextField('Type', typeController),
                  MyDropdownField(
                    label: "Medicine Type",
                    value: typeController.text,
                    items: medicineTypes,
                    onChanged: (value) => setState(() => typeController.text = value!),
                  ),
                  SizedBox(height: 10),
                  MyDropdownField(
                    label: "Medicine Category",
                    value: categoryController.text,
                    items: medicineCategories,
                    onChanged: (value) => setState(() => categoryController.text = value!),
                  ),
                  // widget.myTextField.buildTextField('Category', categoryController),
                  SizedBox(height: 10),
                  widget.myTextField.buildTextField('Notes', notesController),
                  SizedBox(height: 10),
                  widget.myTextField.buildTextField('Quantity', quantityController),
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
                    id: widget.med.id,
                    userId: widget.med.userId,
                    name: nameController.text.trim(),
                    type: typeController.text.trim(),
                    category: categoryController.text.trim(),
                    notes: notesController.text.trim(),
                    quantity: int.tryParse(quantityController.text) ?? 0,
                    dateAdded: widget.med.dateAdded,
                    dateExpired:
                        DateTime.tryParse(expiryController.text.split('-').reversed.join('-')) ?? widget.med.dateExpired,
                  );
                  //add event-> update
                  context.read<MedicineBloc>().add(UpdateMedicineEvent(widget.med.userId, widget.med.id, updatedMedicine));
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
    );
  }
}
