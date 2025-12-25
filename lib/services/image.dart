import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class LocalImageService {
  final ImagePicker _picker = ImagePicker();

  /// Show dialog to choose between camera and gallery
  Future<File?> showImageSourceDialog(BuildContext context) async {
    print('🎬 Showing image source dialog');

    final result = await showDialog<File?>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Choose Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  print('📷 Camera option tapped');
                  // Pick image FIRST
                  final file = await pickImage(ImageSource.camera);
                  print('📷 Camera returned: ${file?.path ?? "null"}');
                  // Then close dialog WITH the result
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop(file);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  print('🖼️ Gallery option tapped');
                  // Pick image FIRST
                  final file = await pickImage(ImageSource.gallery);
                  print('🖼️ Gallery returned: ${file?.path ?? "null"}');
                  // Then close dialog WITH the result
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop(file);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                print('❌ Dialog cancelled');
                Navigator.of(dialogContext).pop(null);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    print('🎬 Dialog closed with result: ${result?.path ?? "null"}');
    return result;
  }

  /// Pick image from camera or gallery
  Future<File?> pickImage(ImageSource source) async {
    try {
      print('📷 Opening image picker from ${source == ImageSource.camera ? "camera" : "gallery"}...');

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (pickedFile != null) {
        print('✅ Image picked successfully: ${pickedFile.path}');
        final File imageFile = File(pickedFile.path);

        // Verify file exists
        if (await imageFile.exists()) {
          print('✅ Image file exists and is accessible');
          return imageFile;
        } else {
          print('❌ Image file does not exist at path: ${pickedFile.path}');
          return null;
        }
      } else {
        print('❌ No image selected by user');
        return null;
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      return null;
    }
  }

  /// Save image to local app storage
  Future<String?> saveImageLocally({
    required File imageFile,
    required String userId,
    required String medicineName,
  }) async {
    try {
      print('💾 Starting to save image locally...');
      print('📂 Source path: ${imageFile.path}');

      // Verify source file exists
      if (!await imageFile.exists()) {
        print('❌ Source image file does not exist!');
        return null;
      }

      // Get app documents directory
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      print('📁 App documents directory: ${appDocDir.path}');

      // Create a subdirectory for medicine images
      final String userDirPath = '${appDocDir.path}/medicine_images/$userId';
      final Directory medicineImagesDir = Directory(userDirPath);

      // Create directory if it doesn't exist
      if (!await medicineImagesDir.exists()) {
        await medicineImagesDir.create(recursive: true);
        print('📁 Created directory: ${medicineImagesDir.path}');
      } else {
        print('📁 Directory already exists: ${medicineImagesDir.path}');
      }

      // Create unique filename
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String sanitizedName = medicineName.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
      final String extension = path.extension(imageFile.path);
      final String fileName = '${sanitizedName}_$timestamp$extension';
      final String savePath = '${medicineImagesDir.path}/$fileName';

      print('💾 Attempting to save to: $savePath');

      // Copy image to new location
      final File savedImage = await imageFile.copy(savePath);

      // Verify the saved file exists
      if (await savedImage.exists()) {
        final int fileSize = await savedImage.length();
        print('✅ Image saved successfully!');
        print('📍 Final path: ${savedImage.path}');
        print('📏 File size: ${fileSize} bytes');
        return savedImage.path;
      } else {
        print('❌ File copy succeeded but file does not exist at destination!');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Error saving image: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Load image from local storage
  Future<File?> loadImageLocally(String imagePath) async {
    try {
      print('📂 Loading image from: $imagePath');
      final File imageFile = File(imagePath);

      if (await imageFile.exists()) {
        print('✅ Image loaded successfully');
        return imageFile;
      } else {
        print('❌ Image not found at: $imagePath');
        return null;
      }
    } catch (e) {
      print('❌ Error loading image: $e');
      return null;
    }
  }

  /// Delete image from local storage
  Future<bool> deleteImageLocally(String imagePath) async {
    try {
      print('🗑️ Attempting to delete image: $imagePath');
      final File imageFile = File(imagePath);

      if (await imageFile.exists()) {
        await imageFile.delete();
        print('✅ Image deleted successfully');
        return true;
      } else {
        print('❌ Image not found for deletion: $imagePath');
        return false;
      }
    } catch (e) {
      print('❌ Error deleting image: $e');
      return false;
    }
  }

  /// Pick multiple images from gallery
  Future<List<File>> pickMultipleImages() async {
    try {
      print('📷 Opening multiple image picker...');

      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (pickedFiles.isNotEmpty) {
        print('✅ ${pickedFiles.length} images selected');
        return pickedFiles.map((xFile) => File(xFile.path)).toList();
      } else {
        print('❌ No images selected');
        return [];
      }
    } catch (e) {
      print('❌ Error picking images: $e');
      return [];
    }
  }
}