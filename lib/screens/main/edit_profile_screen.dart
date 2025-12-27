import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meditrack/services/account_manager.dart';
import 'package:meditrack/style/colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AccountManager _accountManager = AccountManager();

  User? user;

  TextEditingController displayNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController allergiesController = TextEditingController();
  TextEditingController medicalConditionsController = TextEditingController();
  TextEditingController emergencyContactController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    loadUserData();
  }

  Future<void> loadUserData() async {
    if (user == null) return;

    setState(() => isLoading = true);

    final uid = user!.uid;
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data();

    if (data != null) {
      displayNameController.text = data['displayName'] ?? '';
      emailController.text = data['email'] ?? '';
      phoneController.text = data['phonenumber'] ?? '';
      allergiesController.text = data['allergies'] ?? '';
      medicalConditionsController.text = data['medicalConditions'] ?? '';
      emergencyContactController.text = data['emergencyContact'] ?? '';
    }

    setState(() => isLoading = false);
  }

  Future<void> saveUserData() async {
    if (user == null) return;

    setState(() => isSaving = true);

    try {
      await _firestore.collection('users').doc(user!.uid).set({
        'displayName': displayNameController.text.trim(),
        'email': emailController.text.trim(),
        'phonenumber': phoneController.text.trim(),
        'allergies': allergiesController.text.trim(),
        'medicalConditions': medicalConditionsController.text.trim(),
        'emergencyContact': emergencyContactController.text.trim(),
      }, SetOptions(merge: true));

      // Update saved account info
      await _accountManager.saveCurrentAccount();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Go back to settings
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              colors: [Color(0xFF1A3A6B), Color(0xFF00B9E4)],
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Profile Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: AppColors.primary,
                size: 80,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              user?.displayName ?? 'User',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.grey[300] : Colors.black87,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              user?.email ?? '',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
              ),
            ),

            const SizedBox(height: 40),

            // Basic Information Section
            _buildSectionHeader(
              context,
              'Basic Information',
              Icons.person_outline,
              isDarkMode,
            ),

            const SizedBox(height: 16),

            _buildThemedTextField(
              context,
              'Display Name',
              displayNameController,
              Icons.badge,
              isDarkMode,
            ),

            _buildThemedTextField(
              context,
              'Email',
              emailController,
              Icons.email,
              isDarkMode,
            ),

            _buildThemedTextField(
              context,
              'Phone Number',
              phoneController,
              Icons.phone,
              isDarkMode,
            ),

            const SizedBox(height: 32),

            // Medical Information Section
            _buildSectionHeader(
              context,
              'Medical Information (Optional)',
              Icons.medical_information,
              isDarkMode,
            ),

            const SizedBox(height: 16),

            _buildThemedTextField(
              context,
              'Allergies',
              allergiesController,
              Icons.healing,
              isDarkMode,
              maxLines: 3,
            ),

            _buildThemedTextField(
              context,
              'Medical Conditions',
              medicalConditionsController,
              Icons.local_hospital,
              isDarkMode,
              maxLines: 3,
            ),

            const SizedBox(height: 32),

            // Emergency Contact Section
            _buildSectionHeader(
              context,
              'Emergency Contact',
              Icons.emergency,
              isDarkMode,
            ),

            const SizedBox(height: 16),

            _buildThemedTextField(
              context,
              'Emergency Contact',
              emergencyContactController,
              Icons.contact_phone,
              isDarkMode,
            ),

            const SizedBox(height: 40),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isSaving ? null : saveUserData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                child: isSaving
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context,
      String title,
      IconData icon,
      bool isDarkMode,
      ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.grey[300] : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildThemedTextField(
      BuildContext context,
      String label,
      TextEditingController controller,
      IconData icon,
      bool isDarkMode, {
        int maxLines = 1,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primary),
          labelStyle: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
          ),
          fillColor: isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFF2F4F8),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDarkMode ? const Color(0xFF3C3C3C) : const Color(0xFFC8D1DC),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDarkMode ? const Color(0xFF3C3C3C) : const Color(0xFFC8D1DC),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF00B9E4),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    displayNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    allergiesController.dispose();
    medicalConditionsController.dispose();
    emergencyContactController.dispose();
    super.dispose();
  }
}