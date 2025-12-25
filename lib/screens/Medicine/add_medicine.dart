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

import '../../bloc/image/image_bloc.dart';
import '../../bloc/image/image_event.dart';
import '../../bloc/image/image_state.dart';
import '../../repository/medicine_constants.dart';
import '../../widgets/MyDropDownField.dart';

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

  bool _isUploadingImage = false;

  String? medicineValidator(value) {
    if (value!.isEmpty) return "*";
    return null;
  }

  void submitMedicine(File? selectedImage) async {
    print('\n🚀 Submit button pressed');

    if (!formKey.currentState!.validate()) {
      print('❌ Form validation failed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields')),
        );
      }
      return;
    }

    print('✅ Form validation passed');
    print('📝 Medicine name: ${MedName.text.trim()}');
    print('🖼️ Selected image: ${selectedImage?.path ?? "No image"}');

    setState(() => _isUploadingImage = true);

    // Save image locally if selected
    String? imagePath;
    if (selectedImage != null) {
      print('\n📸 Image selected, starting save process...');
      print('Source image path: ${selectedImage.path}');

      final bool imageExists = await selectedImage.exists();
      print('Image file exists: $imageExists');

      if (imageExists) {
        imagePath = await _imageService.saveImageLocally(
          imageFile: selectedImage,
          userId: userCredential?.uid ?? '',
          medicineName: MedName.text.trim(),
        );

        if (imagePath != null) {
          print('✅✅✅ Image saved successfully: $imagePath');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image saved successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          print('❌❌❌ Image save returned null');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image save failed. Saving without image.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        print('❌ Image file does not exist at source path!');
      }
    } else {
      print('ℹ️ No image selected to save');
    }

    setState(() => _isUploadingImage = false);

    print('\n📦 Creating medicine object...');
    print('Medicine name: ${MedName.text.trim()}');
    print('Image path to save: $imagePath');

    final newMedicine = Medicine(
      id: '',
      userId: userCredential?.uid ?? '',
      name: MedName.text.trim(),
      type: MedType.text.trim(),
      category: MedCategory.text.trim(),
      notes: MedNotes.text.trim(),
      quantity: int.tryParse(Quantity.text.trim()) ?? 0,
      dateAdded: DateTime.now(),
      dateExpired: ExpDate.text.isNotEmpty
          ? DateTime.tryParse(ExpDate.text.split('-').reversed.join('-')) ??
          DateTime.now()
          : DateTime.now().add(const Duration(days: 365)),
      imageUrl: imagePath,
    );

    print('🎯 Medicine object created with imageUrl: ${newMedicine.imageUrl}');

    if (mounted) {
      print('📤 Dispatching AddMedicineEvent to BLoC...');
      context.read<MedicineBloc>().add(
        AddMedicineEvent(userCredential?.uid ?? '', newMedicine),
      );

      // Clear image from BLoC
      context.read<ImageBloc>().add(const RemoveImageEvent());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medicine added successfully!')),
      );

      print('🔙 Popping navigation...\n');
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickImage() async {
    print('\n📷 Image picker button pressed');

    final file = await _imageService.showImageSourceDialog(context);

    print('📷 Received file from dialog: ${file?.path ?? "null"}');

    if (file != null) {
      print('✅ Image received from picker: ${file.path}');
      final exists = await file.exists();
      print('File exists check: $exists');

      if (exists) {
        // Update BLoC with the image
        print('🖼️ BLoC: Setting image - ${file.path}');
        context.read<ImageBloc>().add(SetImageEvent(file));
        print('✅ Image sent to BLoC');
      } else {
        print('❌ Received file does not exist!');
      }
    } else {
      print('❌ No image received from picker');
    }
  }

  @override
  void dispose() {
    MedName.dispose();
    MedNotes.dispose();
    MedType.dispose();
    MedCategory.dispose();
    ExpDate.dispose();
    Quantity.dispose();
    super.dispose();
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
                  // Image Picker Section - Using BLoC
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

                            // BlocBuilder to display image
                            BlocBuilder<ImageBloc, ImageState>(
                              builder: (context, imageState) {
                                if (imageState is ImageSelected) {
                                  return Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          imageState.image,
                                          height: 150,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            print('❌ Error displaying image: $error');
                                            return Container(
                                              height: 150,
                                              color: Colors.grey,
                                              child: Center(
                                                child: Icon(Icons.error, color: Colors.red),
                                              ),
                                            );
                                          },
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
                                            print('🗑️ Removing image from BLoC');
                                            context.read<ImageBloc>().add(const RemoveImageEvent());
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                }

                                // Default: Show button to add photo
                                return OutlinedButton.icon(
                                  onPressed: _pickImage,
                                  icon: const Icon(Icons.add_a_photo),
                                  label: const Text('Add Photo'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: BorderSide(color: AppColors.primary),
                                  ),
                                );
                              },
                            ),

                            // Show filename when image selected
                            BlocBuilder<ImageBloc, ImageState>(
                              builder: (context, imageState) {
                                if (imageState is ImageSelected) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Column(
                                      children: [
                                        Text(
                                          'Image selected ✓',
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          imageState.image.path.split('/').last,
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 10,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return SizedBox.shrink();
                              },
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
                      onChanged: (value) => MedType.text = value!,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 300,
                    child: MyDropdownField(
                      label: "Medicine Category",
                      value: MedCategory.text,
                      items: medicineCategories,
                      validator: medicineValidator,
                      onChanged: (value) => MedCategory.text = value!,
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
                        ExpDate.text = "${date.day.toString().padLeft(2, '0')}-"
                            "${date.month.toString().padLeft(2, '0')}-"
                            "${date.year}";
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit Button - Gets image from BLoC
                  BlocBuilder<ImageBloc, ImageState>(
                    builder: (context, imageState) {
                      File? selectedImage;
                      if (imageState is ImageSelected) {
                        selectedImage = imageState.image;
                      }

                      return SizedBox(
                        height: 50,
                        width: 300,
                        child: ElevatedButton(
                          onPressed: _isUploadingImage
                              ? null
                              : () => submitMedicine(selectedImage),
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
                              Text('Saving Image...'),
                            ],
                          )
                              : Text(
                            'Add Medicine',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      );
                    },
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