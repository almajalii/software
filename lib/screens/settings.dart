import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:meditrack/classes/MyTextField.dart';
import 'package:meditrack/screens/auth/Start.dart';
import 'package:meditrack/style/colors.dart';

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
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => Start(),));
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
      builder:
          (context) => AlertDialog(
            title: const Text('Log Out'),
            backgroundColor: Colors.white,
            content: const Text('Are you sure you want to log out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false), // Cancel
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true), // Confirm
                child: const Text('Log Out'),
              ),
            ],
          ),
    );

    if (shouldLogout == true) {
      await _auth.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const Start()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading or nothing if user not signed in (should redirect soon)
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
          IconButton(onPressed: logout, icon: const Icon(Icons.logout), color: AppColors.error,),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              colors: [Color(0xFF1A3A6B), Color(0xFF00B9E4)],
            ),
          ),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.person, color: AppColors.primary, size: 80),

                    myTextField.buildTextField(
                      'Display Name',
                      displayNameController,
                    ),
                    myTextField.buildTextField('Email', emailController),
                    myTextField.buildTextField('Phone Number', phoneController),
                    const SizedBox(height: 5),
                    Text(
                      'Further Information: (optional)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 5),
                    myTextField.buildTextField('Allergies', allergiesController),
                    myTextField.buildTextField(
                      'Medical Conditions',
                      medicalConditionsController,
                    ),
                    myTextField.buildTextField(
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
}
