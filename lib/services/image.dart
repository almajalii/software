import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class LocalImageService {
  final ImagePicker _picker = ImagePicker();

  // Pick image from camera or gallery
  Future<File?> pickImage({required bool fromCamera}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  // Save image to local app storage and return the path
  Future<String?> saveImageLocally({
    required File imageFile,
    required String userId,
    required String medicineName,
  }) async {
    try {
      // Get app's document directory
      final directory = await getApplicationDocumentsDirectory();

      // Create medicine_images folder if it doesn't exist
      final medicineImagesDir = Directory('${directory.path}/medicine_images');
      if (!await medicineImagesDir.exists()) {
        await medicineImagesDir.create(recursive: true);
      }

      // Create unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(imageFile.path);
      final fileName = '${userId}_${medicineName}_$timestamp$extension';
      final savedPath = '${medicineImagesDir.path}/$fileName';

      // Copy image to app storage
      final savedFile = await imageFile.copy(savedPath);

      print('✅ Image saved locally: $savedPath');
      return savedFile.path;
    } catch (e) {
      print('❌ Error saving image locally: $e');
      return null;
    }
  }

  // Delete local image
  Future<void> deleteLocalImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        print('🗑️ Image deleted: $imagePath');
      }
    } catch (e) {
      print('Error deleting image: $e');
    }
  }

  // Check if local image exists
  Future<bool> imageExists(String imagePath) async {
    try {
      final file = File(imagePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  // Show image picker dialog
  Future<File?> showImageSourceDialog(context) async {
    return await showDialog<File?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.pop(context);
                  final file = await pickImage(fromCamera: true);
                  Navigator.pop(context, file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final file = await pickImage(fromCamera: false);
                  Navigator.pop(context, file);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}