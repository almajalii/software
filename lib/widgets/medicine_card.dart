import 'dart:io';
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
      elevation: 2,
      margin: const EdgeInsets.all(20),
      shadowColor: isDarkMode ? Colors.black45 : AppColors.lightGray,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ListTile(
        //name
        title: Text(
          widget.med.name,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 20,
            color: isDarkMode ? Colors.grey[200] : AppColors.darkBlue,
          ),
        ),
        //type
        subtitle: Text(
          'Type: ${widget.med.type}\nQuantity: ${widget.med.quantity}',
          style: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.black87,
          ),
        ),
        leading: Icon(
          FontAwesomeIcons.capsules,
          color: isDarkMode ? AppColors.primary.withOpacity(0.8) : AppColors.primary,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Edit
            EditButton(context, isDarkMode),
            // Delete
            RemoveButton(context),
          ],
        ),
        onTap: () {
          DisplayMedicineDialog(context, isDarkMode);
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

  IconButton EditButton(BuildContext context, bool isDarkMode) {
    return IconButton(
      icon: Icon(
        Icons.edit,
        color: isDarkMode ? AppColors.primary.withOpacity(0.8) : AppColors.primary,
      ),
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
          isDarkMode,
        );
      },
    );
  }

  Future<dynamic> DisplayMedicineDialog(BuildContext context, bool isDarkMode) {
    // Debug: Print image URL/path
    print('🖼️ Medicine: ${widget.med.name}');
    print('🖼️ Image URL/Path: ${widget.med.imageUrl}');

    return showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
        backgroundColor: isDarkMode ? Color(0xFF2C2C2C) : AppColors.white,
        title: Text(
          'Medicine Details',
          style: TextStyle(
            color: isDarkMode ? Colors.grey[200] : Colors.black87,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display image if available (from LOCAL storage)
              if (widget.med.imageUrl != null && widget.med.imageUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(widget.med.imageUrl!),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: isDarkMode ? Color(0xFF1E1E1E) : Colors.grey[200],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  size: 48,
                                  color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Image not found',
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              Text(
                'Name: ${widget.med.name}',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[300] : Colors.black87,
                ),
              ),
              Text(
                'Type: ${widget.med.type}',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[300] : Colors.black87,
                ),
              ),
              Text(
                'Category: ${widget.med.category}',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[300] : Colors.black87,
                ),
              ),
              Text(
                'Quantity: ${widget.med.quantity}',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[300] : Colors.black87,
                ),
              ),
              Text(
                'Notes: ${widget.med.notes}',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[300] : Colors.black87,
                ),
              ),
              Text(
                'Expiry Date: ${widget.med.dateExpired.day}-${widget.med.dateExpired.month}-${widget.med.dateExpired.year}',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[300] : Colors.black87,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('View Alternatives'),
            onPressed: () {
              Navigator.of(context).pop();
              _showAlternativesDialog(context, isDarkMode);
            },
          ),
          TextButton(
            child: const Text('Close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showAlternativesDialog(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (_) => BlocBuilder<MedicineBloc, MedicineState>(
        builder: (context, state) {
          List<Medicine> alternatives = [];

          if (state is MedicineLoadedState) {
            // Find medicines with same category, excluding current medicine
            alternatives = state.medicines.where((med) =>
            med.id != widget.med.id &&
                med.category == widget.med.category
            ).toList();
          }

          return AlertDialog(
            backgroundColor: isDarkMode ? Color(0xFF2C2C2C) : AppColors.white,
            title: Row(
              children: [
                Icon(Icons.medical_services, color: AppColors.primary, size: 24),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Alternative Medicines',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[200] : Colors.black87,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            content: Container(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: AppColors.primary,
                            size: 20
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Category: ${widget.med.category}',
                            style: TextStyle(
                              color: isDarkMode ? Colors.grey[300] : Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Similar medicines in your inventory:',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 12),
                  alternatives.isEmpty
                      ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 48,
                            color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No alternatives found',
                            style: TextStyle(
                              color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'No other medicines in this category',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      : Container(
                    constraints: BoxConstraints(maxHeight: 300),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: alternatives.length,
                      itemBuilder: (context, index) {
                        final alt = alternatives[index];
                        return Card(
                          color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
                          margin: EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(
                              FontAwesomeIcons.pills,
                              color: AppColors.teal,
                              size: 20,
                            ),
                            title: Text(
                              alt.name,
                              style: TextStyle(
                                color: isDarkMode ? Colors.grey[200] : Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${alt.type} • Qty: ${alt.quantity}',
                              style: TextStyle(
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            trailing: Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: alt.quantity > 0
                                    ? AppColors.success.withOpacity(0.2)
                                    : AppColors.error.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                alt.quantity > 0 ? 'Available' : 'Out of stock',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: alt.quantity > 0
                                      ? AppColors.success
                                      : AppColors.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Close'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<dynamic> EditMedicineDialog(
      BuildContext context,
      TextEditingController nameController,
      TextEditingController typeController,
      TextEditingController categoryController,
      TextEditingController notesController,
      TextEditingController quantityController,
      TextEditingController expiryController,
      bool isDarkMode,
      ) {
    return showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
        backgroundColor: isDarkMode ? Color(0xFF2C2C2C) : AppColors.white,
        title: Text(
          'Edit Medicine',
          style: TextStyle(
            color: isDarkMode ? Colors.grey[200] : Colors.black87,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildThemedTextField(context, 'Name', nameController),
              SizedBox(height: 10),
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
              SizedBox(height: 10),
              _buildThemedTextField(context, 'Notes', notesController),
              SizedBox(height: 10),
              _buildThemedTextField(context, 'Quantity', quantityController),
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
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
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

  Widget _buildThemedTextField(
      BuildContext context,
      String label,
      TextEditingController controller,
      ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: controller,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
          ),
          fillColor: isDarkMode ? Color(0xFF1E1E1E) : Color(0xFFF2F4F8),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}