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
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../bloc/image/image_bloc.dart';
import '../../bloc/image/image_event.dart';
import '../../bloc/image/image_state.dart';
import '../../repository/medicine_constants.dart';
import '../../widgets/MyDropDownField.dart';
import '../../services/medicine_barcode_service.dart';

class AddMedicine extends StatefulWidget {
  const AddMedicine({super.key});

  @override
  State<AddMedicine> createState() => _AddMedicineState();
}

class _AddMedicineState extends State<AddMedicine> {
  final GlobalKey<FormState> formKey = GlobalKey();
  final TextEditingController medName = TextEditingController();
  final TextEditingController medNotes = TextEditingController();
  final TextEditingController medType = TextEditingController();
  final TextEditingController medCategory = TextEditingController();
  final TextEditingController expDate = TextEditingController();
  final TextEditingController quantity = TextEditingController();
  final TextEditingController barcodeController = TextEditingController();
  final myTextField = MyTextField();
  final LocalImageService _imageService = LocalImageService();
  final MedicineBarcodeService _barcodeService = MedicineBarcodeService();

  final User? userCredential = FirebaseAuth.instance.currentUser;

  bool _isUploadingImage = false;
  bool _isProcessingOCR = false;
  bool _isSearchingBarcode = false;

  String? medicineValidator(value) {
    if (value!.isEmpty) return "*";
    return null;
  }

  // Search for medicine by barcode
  Future<void> _searchMedicineByBarcode(String barcode) async {
    setState(() => _isSearchingBarcode = true);

    try {
      print('\n🔍 Searching for medicine with barcode: $barcode');

      final medicineData = await _barcodeService.getMedicineByBarcode(barcode);

      if (medicineData != null) {
        // Auto-fill the form
        setState(() {
          if (medName.text.isEmpty) {
            medName.text = medicineData['name'] ?? '';
          }

          if (medType.text.isEmpty && medicineData['type']!.isNotEmpty) {
            medType.text = medicineData['type']!;
          }

          if (medCategory.text.isEmpty && medicineData['category']!.isNotEmpty) {
            medCategory.text = medicineData['category']!;
          }

          if (medNotes.text.isEmpty && medicineData['dosage']!.isNotEmpty) {
            medNotes.text = medicineData['dosage']!;
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '✅ Found: ${medicineData['name']} (${medicineData['source'] == 'firebase' ? 'Database' : 'API'})'
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Barcode not found. Please fill details manually.\nYour data will be saved for future use!'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error searching barcode: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error searching barcode. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSearchingBarcode = false);
    }
  }

  // OCR Text Extraction Method
  Future<void> _extractTextFromImage(File imageFile) async {
    setState(() => _isProcessingOCR = true);

    try {
      print('\n🔍 Starting OCR text extraction...');

      final inputImage = InputImage.fromFile(imageFile);
      final textRecognizer = TextRecognizer();

      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      final String fullText = recognizedText.text;

      print('📝 Extracted text: $fullText');

      // Parse the extracted text
      final parsedData = _parseMedicineInfo(fullText);

      // Auto-fill the form fields
      setState(() {
        if (parsedData['name'] != null && medName.text.isEmpty) {
          medName.text = parsedData['name']!;
        }

        if (parsedData['dosage'] != null && medNotes.text.isEmpty) {
          medNotes.text = parsedData['dosage']!;
        }

        if (parsedData['expiry'] != null && expDate.text.isEmpty) {
          expDate.text = parsedData['expiry']!;
        }

        if (parsedData['quantity'] != null && quantity.text.isEmpty) {
          quantity.text = parsedData['quantity']!;
        }
      });

      textRecognizer.close();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Auto-filled from image!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      print('✅ OCR extraction completed');
    } catch (e) {
      print('❌ Error during OCR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not extract text. Please fill manually.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      setState(() => _isProcessingOCR = false);
    }
  }

  // Parse medicine information from extracted text
  Map<String, String> _parseMedicineInfo(String text) {
    final Map<String, String> info = {};
    final lines = text.split('\n');

    // Look for medicine name (usually in first few lines, capitalized)
    for (int i = 0; i < lines.length && i < 5; i++) {
      final line = lines[i].trim();
      if (line.length > 3 && line.length < 50 && RegExp(r'^[A-Z]').hasMatch(line)) {
        info['name'] = line;
        break;
      }
    }

    // Look for expiry date patterns
    final expiryPatterns = [
      RegExp(r'exp[iry]*[:\s]*(\d{2}[/\-]\d{2}[/\-]\d{2,4})', caseSensitive: false),
      RegExp(r'(\d{2}[/\-]\d{2}[/\-]\d{2,4})', caseSensitive: false),
      RegExp(r'mfg[:\s]*\d{2}[/\-]\d{2}[/\-]\d{2,4}[^\d]*exp[:\s]*(\d{2}[/\-]\d{2}[/\-]\d{2,4})', caseSensitive: false),
    ];

    for (final pattern in expiryPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        String dateStr = match.group(1) ?? match.group(0)!;
        info['expiry'] = _formatExpiryDate(dateStr);
        break;
      }
    }

    // Look for dosage information
    final dosagePatterns = [
      RegExp(r'(\d+\s*mg)', caseSensitive: false),
      RegExp(r'(\d+\s*ml)', caseSensitive: false),
      RegExp(r'(\d+\s*g)', caseSensitive: false),
      RegExp(r'(\d+\s*mcg)', caseSensitive: false),
    ];

    for (final pattern in dosagePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        info['dosage'] = match.group(1) ?? '';
        break;
      }
    }

    // Look for quantity (tablets, capsules, etc.)
    final quantityPatterns = [
      RegExp(r'(\d+)\s*tablets?', caseSensitive: false),
      RegExp(r'(\d+)\s*capsules?', caseSensitive: false),
      RegExp(r'(\d+)\s*pills?', caseSensitive: false),
      RegExp(r'qty[:\s]*(\d+)', caseSensitive: false),
    ];

    for (final pattern in quantityPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        info['quantity'] = match.group(1) ?? '';
        break;
      }
    }

    print('🎯 Parsed info: $info');
    return info;
  }

  // Format expiry date to dd-mm-yyyy
  String _formatExpiryDate(String dateStr) {
    try {
      dateStr = dateStr.replaceAll(RegExp(r'[^\d/\-]'), '');

      final parts = dateStr.split(RegExp(r'[/\-]'));
      if (parts.length != 3) return dateStr;

      int day, month, year;

      if (parts[2].length == 4) {
        if (int.parse(parts[0]) > 12) {
          day = int.parse(parts[0]);
          month = int.parse(parts[1]);
        } else if (int.parse(parts[1]) > 12) {
          day = int.parse(parts[1]);
          month = int.parse(parts[0]);
        } else {
          day = int.parse(parts[0]);
          month = int.parse(parts[1]);
        }
        year = int.parse(parts[2]);
      } else {
        if (int.parse(parts[0]) > 12) {
          day = int.parse(parts[0]);
          month = int.parse(parts[1]);
        } else if (int.parse(parts[1]) > 12) {
          day = int.parse(parts[1]);
          month = int.parse(parts[0]);
        } else {
          day = int.parse(parts[0]);
          month = int.parse(parts[1]);
        }
        year = 2000 + int.parse(parts[2]);
      }

      return '${day.toString().padLeft(2, '0')}-${month.toString().padLeft(2, '0')}-$year';
    } catch (e) {
      print('Error formatting date: $e');
      return dateStr;
    }
  }

  Future<void> _scanBarcode() async {
    print('\n📷 Barcode scanner button pressed');

    final String? barcode = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _BarcodeScannerScreen(
          onBarcodeScanned: (scannedBarcode) {
            print('✅ Barcode scanned: $scannedBarcode');
          },
        ),
      ),
    );

    if (barcode != null && barcode.isNotEmpty) {
      setState(() {
        barcodeController.text = barcode;
      });

      // Automatically search for the medicine
      await _searchMedicineByBarcode(barcode);
    }
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
    print('📝 Medicine name: ${medName.text.trim()}');
    print('🖼️ Selected image: ${selectedImage?.path ?? "No image"}');

    setState(() => _isUploadingImage = true);

    // Save barcode data to Firebase if barcode was scanned
    if (barcodeController.text.isNotEmpty) {
      await _barcodeService.saveUserMedicineBarcode(
        barcode: barcodeController.text,
        name: medName.text.trim(),
        type: medType.text.trim(),
        category: medCategory.text.trim(),
        dosage: medNotes.text.trim(),
      );
    }

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
          medicineName: medName.text.trim(),
        );

        if (imagePath != null) {
          print('✅✅✅ Image saved successfully: $imagePath');
        } else {
          print('❌❌❌ Image save returned null');
        }
      } else {
        print('❌ Image file does not exist at source path!');
      }
    } else {
      print('ℹ️ No image selected to save');
    }

    setState(() => _isUploadingImage = false);

    print('\n📦 Creating medicine object...');
    print('Medicine name: ${medName.text.trim()}');
    print('Image path to save: $imagePath');

    final newMedicine = Medicine(
      id: '',
      userId: userCredential?.uid ?? '',
      name: medName.text.trim(),
      type: medType.text.trim(),
      category: medCategory.text.trim(),
      notes: medNotes.text.trim(),
      quantity: int.tryParse(quantity.text.trim()) ?? 0,
      dateAdded: DateTime.now(),
      dateExpired: expDate.text.isNotEmpty
          ? DateTime.tryParse(expDate.text.split('-').reversed.join('-')) ??
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

        // Extract text from image using OCR
        await _extractTextFromImage(file);
      } else {
        print('❌ Received file does not exist!');
      }
    } else {
      print('❌ No image received from picker');
    }
  }

  @override
  void dispose() {
    medName.dispose();
    medNotes.dispose();
    medType.dispose();
    medCategory.dispose();
    expDate.dispose();
    quantity.dispose();
    barcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      appBar: MyAppBar.build(context, () => ExpiryReminder()),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Center(
              child: Column(
                children: [
                  // Pill Icon at the top
                  const SizedBox(height: 30),
                  const Icon(
                    FontAwesomeIcons.pills,
                    color: AppColors.primary,
                    size: 80,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Add New Medicine',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.grey[200] : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Medicine Name
                  SizedBox(
                    width: 300,
                    child: myTextField.buildTextField(
                      "Medicine Name",
                      medName,
                      validator: medicineValidator,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Type and Category
                  SizedBox(
                    width: 300,
                    child: MyDropdownField(
                      label: "Medicine Type",
                      value: medType.text,
                      items: medicineTypes,
                      validator: medicineValidator,
                      onChanged: (value) => medType.text = value!,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 300,
                    child: MyDropdownField(
                      label: "Medicine Category",
                      value: medCategory.text,
                      items: medicineCategories,
                      validator: medicineValidator,
                      onChanged: (value) => medCategory.text = value!,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Notes
                  SizedBox(
                    width: 300,
                    child: myTextField.buildTextField("Notes / Dosage", medNotes),
                  ),
                  const SizedBox(height: 20),

                  // Quantity
                  SizedBox(
                    width: 300,
                    child: TextFormField(
                      controller: quantity,
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
                        fillColor: isDarkMode ? const Color(0xFF2C2C2C) : AppColors.lightGray,
                        filled: true,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDarkMode ? const Color(0xFF3C3C3C) : const Color(0xFFC8D1DC),
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
                      validator: medicineValidator,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Expiry Date
                  SizedBox(
                    width: 300,
                    child: ExpiryDatePicker(
                      controller: expDate,
                      labelText: "Expiry Date",
                      onDateChanged: (date) {
                        expDate.text = "${date.day.toString().padLeft(2, '0')}-"
                            "${date.month.toString().padLeft(2, '0')}-"
                            "${date.year}";
                      },
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Barcode Scanner - Simple compact design with loading indicator
                  SizedBox(
                    width: 300,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: barcodeController,
                            readOnly: true,
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                              fontSize: 13,
                            ),
                            decoration: InputDecoration(
                              labelText: "Barcode (Auto-fill)",
                              labelStyle: TextStyle(
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                              ),
                              hintText: _isSearchingBarcode ? "Searching..." : "Scan to auto-fill",
                              hintStyle: TextStyle(fontSize: 12, color: Colors.grey[500]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              fillColor: isDarkMode ? const Color(0xFF2C2C2C) : AppColors.lightGray,
                              filled: true,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDarkMode ? const Color(0xFF3C3C3C) : const Color(0xFFC8D1DC),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                              suffixIcon: barcodeController.text.isNotEmpty
                                  ? IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  setState(() {
                                    barcodeController.clear();
                                  });
                                },
                              )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _isSearchingBarcode ? null : _scanBarcode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSearchingBarcode
                              ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : const Icon(Icons.qr_code_scanner, size: 24),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Photo Section - Smaller and compact
                  BlocBuilder<ImageBloc, ImageState>(
                    builder: (context, imageState) {
                      File? selectedImage;
                      if (imageState is ImageSelected) {
                        selectedImage = imageState.image;
                      }

                      return SizedBox(
                        width: 300,
                        child: Column(
                          children: [
                            if (selectedImage != null) ...[
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      selectedImage,
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white, size: 18),
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        padding: const EdgeInsets.all(4),
                                      ),
                                      onPressed: () {
                                        context.read<ImageBloc>().add(const RemoveImageEvent());
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                            OutlinedButton.icon(
                              onPressed: _isProcessingOCR ? null : _pickImage,
                              icon: _isProcessingOCR
                                  ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                                  : const Icon(Icons.camera_alt, size: 18),
                              label: Text(
                                selectedImage != null
                                    ? (_isProcessingOCR ? 'Scanning...' : 'Change Photo')
                                    : (_isProcessingOCR ? 'Scanning...' : 'Add Photo (OCR)'),
                                style: const TextStyle(fontSize: 13),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            if (!_isProcessingOCR && selectedImage == null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Photo extracts name, expiry & dosage',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // Submit Button
                  BlocBuilder<ImageBloc, ImageState>(
                    builder: (context, imageState) {
                      File? selectedImage;
                      if (imageState is ImageSelected) {
                        selectedImage = imageState.image;
                      }

                      return SizedBox(
                        width: 300,
                        child: ElevatedButton(
                          onPressed: _isUploadingImage || _isProcessingOCR || _isSearchingBarcode
                              ? null
                              : () {
                            submitMedicine(selectedImage);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isUploadingImage
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : const Text(
                            'Add Medicine',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
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
}

// Barcode Scanner Screen
class _BarcodeScannerScreen extends StatefulWidget {
  final Function(String barcode) onBarcodeScanned;

  const _BarcodeScannerScreen({
    required this.onBarcodeScanned,
  });

  @override
  State<_BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<_BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isScanning = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture barcodeCapture) {
    if (!_isScanning) return;

    final barcode = barcodeCapture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    setState(() => _isScanning = false);

    widget.onBarcodeScanned(barcode!.rawValue!);
    Navigator.pop(context, barcode.rawValue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: AppColors.primary,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onBarcodeDetected,
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              color: Colors.black54,
              child: const Text(
                'Point camera at medicine barcode',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }
}