import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meditrack/widgets/MyTextField.dart';
import 'package:meditrack/screens/auth/start_screen.dart';
import 'package:meditrack/style/colors.dart';
import 'package:meditrack/bloc/theme_bloc/theme_bloc.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final myTextField = MyTextField();

  User? user;

  TextEditingController displayNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController allergiesController = TextEditingController();
  TextEditingController medicalConditionsController = TextEditingController();
  TextEditingController emergencyContactController = TextEditingController();

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    if (user == null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => StartScreen(),
        ),
      );
    } else {
      loadUserData();
    }
  }

  Future<void> loadUserData() async {
    if (user == null) return;

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

    setState(() {
      isLoading = false;
    });
  }

  Future<void> saveUserData() async {
    if (user == null) return;

    await _firestore.collection('users').doc(user!.uid).set({
      'displayName': displayNameController.text.trim(),
      'email': emailController.text.trim(),
      'phonenumber': phoneController.text.trim(),
      'allergies': allergiesController.text.trim(),
      'medicalConditions': medicalConditionsController.text.trim(),
      'emergencyContact': emergencyContactController.text.trim(),
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile updated')));
  }

  void logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _auth.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const StartScreen()),
            (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Container(
          height: 70,
          width: 70,
          child: Image.asset('images/1.png'),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
            color: AppColors.error,
          ),
        ],
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
            // Theme Toggle Card at the top
            Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: BlocBuilder<ThemeBloc, ThemeState>(
                builder: (context, themeState) {
                  return SwitchListTile(
                    title: const Text(
                      'Dark Mode',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      themeState.isDarkMode
                          ? 'Dark theme enabled'
                          : 'Light theme enabled',
                    ),
                    value: themeState.isDarkMode,
                    onChanged: (value) {
                      context.read<ThemeBloc>().add(ToggleThemeEvent());
                    },
                    secondary: Icon(
                      themeState.isDarkMode
                          ? Icons.dark_mode
                          : Icons.light_mode,
                      color: AppColors.primary,
                    ),
                    activeColor: AppColors.primary,
                  );
                },
              ),
            ),

            const SizedBox(height: 30),

            // Profile Icon and Section
            Icon(Icons.person, color: AppColors.primary, size: 80),
            const SizedBox(height: 10),
            Text(
              'Edit Profile',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            _buildThemedTextField(
              context,
              'Display Name',
              displayNameController,
            ),
            _buildThemedTextField(context, 'Email', emailController),
            _buildThemedTextField(context, 'Phone Number', phoneController),
            const SizedBox(height: 5),
            Text(
              'Additional Information (optional)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            _buildThemedTextField(context, 'Allergies', allergiesController),
            _buildThemedTextField(
              context,
              'Medical Conditions',
              medicalConditionsController,
            ),
            _buildThemedTextField(
              context,
              'Emergency Contact',
              emergencyContactController,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: saveUserData,
              child: const Text('Save Changes'),
            ),
          ],
        ),
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
      padding: const EdgeInsets.only(bottom: 16),
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
          fillColor: isDarkMode ? Color(0xFF2C2C2C) : Color(0xFFF2F4F8),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDarkMode ? Color(0xFF3C3C3C) : Color(0xFFC8D1DC),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDarkMode ? Color(0xFF3C3C3C) : Color(0xFFC8D1DC),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Color(0xFF00B9E4),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}