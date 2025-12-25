import 'dart:io';
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
import 'package:meditrack/services/image.dart';

import '../../repository/medicine_constants.dart';
import '../../widgets/MyDropDownField.dart';

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
  final TextEditingController MedCategory = TextEditingController();
  final TextEditingController ExpDate = TextEditingController();
  final TextEditingController Quantity = TextEditingController();
  final myTextField = MyTextField();
  final LocalImageService _imageService = LocalImageService();

  final User? userCredential = FirebaseAuth.instance.currentUser;

  File? _selectedImage;
  bool _isUploadingImage = false;

  String? medicineValidator(value) {
    if (value!.isEmpty) return "*";
    return null;
  }

  void submitMedicine() async {
    if (!formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isUploadingImage = true);

    // Save image locally if selected
    String? imagePath;
    if (_selectedImage != null) {
      print('📸 Saving image locally...');
      imagePath = await _imageService.saveImageLocally(
        imageFile: _selectedImage!,
        userId: userCredential?.uid ?? '',
        medicineName: MedName.text.trim(),
      );

      if (imagePath != null) {
        print('✅ Image saved locally: $imagePath');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image saved successfully!')),
        );
      } else {
        print('❌ Image save failed');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image save failed. Saving without image.')),
        );
      }
    }

    setState(() => _isUploadingImage = false);

    final newMedicine = Medicine(
      id: '',
      userId: userCredential?.uid ?? '',
      name: MedName.text.trim(),
      type: MedType.text.trim(),
      category: MedCategory.text.trim(),
      notes: MedNotes.text.trim(),
      quantity: int.tryParse(Quantity.text.trim()) ?? 0,
      dateAdded: DateTime.now(),
      dateExpired:
      ExpDate.text.isNotEmpty
          ? DateTime.tryParse(ExpDate.text.split('-').reversed.join('-')) ??
          DateTime.now()
          : DateTime.now().add(const Duration(days: 365)),
      imageUrl: imagePath, // Save LOCAL path instead of Firebase URL
    );

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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Color(0xFF121212) : Colors.white,
      appBar: MyAppBar.build(context, () => ExpiryReminder()),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Center(
              child: Column(
                children: [
                  // Image Picker Section
                  SizedBox(
                    width: 300,
                    child: Card(
                      color: isDarkMode ? Color(0xFF2C2C2C) : Colors.grey[100],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              'Medicine Photo (Optional)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.grey[300] : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (_selectedImage != null)
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      _selectedImage!,
                                      height: 150,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white),
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _selectedImage = null;
                                          print('🗑️ Image removed from preview');
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              )
                            else
                              OutlinedButton.icon(
                                onPressed: () async {
                                  print('📷 Opening image picker...');
                                  final file = await _imageService.showImageSourceDialog(context);
                                  if (file != null) {
                                    print('✅ Image selected: ${file.path}');
                                    setState(() => _selectedImage = file);
                                  } else {
                                    print('❌ No image selected');
                                  }
                                },
                                icon: const Icon(Icons.add_a_photo),
                                label: const Text('Add Photo'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: BorderSide(color: AppColors.primary),
                                ),
                              ),
                            if (_selectedImage != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Image selected ✓',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Icon(
                    FontAwesomeIcons.warehouse,
                    color: AppColors.primary,
                    size: 80,
                  ),
                  const SizedBox(height: 50),
                  SizedBox(
                    width: 300,
                    child: myTextField.buildTextField(
                      "Medicine Name",
                      MedName,
                      validator: medicineValidator,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 300,
                    child: MyDropdownField(
                      label: "Medicine Type",
                      value: MedType.text,
                      items: medicineTypes,
                      validator: medicineValidator,
                      onChanged: (value) => setState(() => MedType.text = value!),
                    ),
                  ),

                  SizedBox(
                    width: 300,
                    child: MyDropdownField(
                      label: "Medicine Category",
                      value: MedCategory.text,
                      items: medicineCategories,
                      validator: medicineValidator,
                      onChanged: (value) => setState(() => MedCategory.text = value!),
                    ),
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: 300,
                    child: myTextField.buildTextField("Notes", MedNotes),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 300,
                    child: TextFormField(
                      controller: Quantity,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        labelText: "Quantity",
                        labelStyle: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        fillColor: isDarkMode ? Color(0xFF2C2C2C) : AppColors.lightGray,
                        filled: true,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDarkMode ? Color(0xFF3C3C3C) : Color(0xFFC8D1DC),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return "*";
                        if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                          return "Please enter only numbers";
                        }
                        return null;
                      },
                    ),
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
                    child: ElevatedButton(
                      onPressed: _isUploadingImage ? null : submitMedicine,
                      child: _isUploadingImage
                          ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text('Uploading...'),
                        ],
                      )
                          : Text(
                        'Add',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
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