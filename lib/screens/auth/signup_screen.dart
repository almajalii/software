import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:meditrack/widgets/MyTextField.dart';
import 'package:meditrack/screens/main/home/navigation_main.dart';
import 'package:meditrack/screens/auth/login_screen.dart';
import 'package:meditrack/style/colors.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final GlobalKey<FormState> formKey = GlobalKey();
  final MyTextField myTextField = MyTextField();
  final TextEditingController username = TextEditingController();
  final TextEditingController mail = TextEditingController();
  final TextEditingController phonenumber = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController confirmPassword = TextEditingController();
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final LocalAuthentication localAuth = LocalAuthentication();

  Future<void> signUp() async {
    if (!formKey.currentState!.validate()) return;

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: mail.text.trim(),
        password: password.text.trim(),
      );

      await userCredential.user?.updateDisplayName(username.text.trim());

      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': mail.text.trim(),
        'phonenumber': phonenumber.text.trim(),
        'displayName': username.text.trim(),
        'allergies': '',
        'medicalConditions': '',
        'emergencyContact': '',
      });

      bool enableBiometrics = false;
      final canCheck = await localAuth.canCheckBiometrics;
      final available = await localAuth.getAvailableBiometrics();
      if (canCheck && available.isNotEmpty) {
        enableBiometrics = await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Enable Biometric Login?'),
            content: const Text('Use fingerprint or face ID next time?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
            ],
          ),
        ) ?? false;
      }

      if (enableBiometrics) {
        await storage.write(key: 'biometric_enabled', value: 'true');
        await storage.write(key: 'email', value: mail.text.trim());
        await storage.write(key: 'password', value: password.text.trim());
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signup successful! Redirecting...')));
      await Future.delayed(const Duration(milliseconds: 300));
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const NavigationMain()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Signup failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                const SizedBox(height: 40),
                SizedBox(height: 200, width: 200, child: Image.asset('images/1.png')),
                const SizedBox(height: 10),
                Text('Create Your Account!', style: Theme.of(context).textTheme.titleLarge!.copyWith(fontSize: 30)),
                const SizedBox(height: 20),
                SizedBox(width: 300, child: myTextField.buildTextField('Username', username, prefixIcon: Icons.person)),
                const SizedBox(height: 10),
                SizedBox(width: 300, child: myTextField.buildTextField('Email', mail, prefixIcon: Icons.email)),
                const SizedBox(height: 10),
                SizedBox(width: 300, child: myTextField.buildTextField('Phone Number', phonenumber, prefixIcon: Icons.phone)),
                const SizedBox(height: 10),
                SizedBox(width: 300, child: myTextField.buildTextField('Password', password, prefixIcon: Icons.password, obscureText: true)),
                const SizedBox(height: 10),
                SizedBox(width: 300, child: myTextField.buildTextField('Confirm Password', confirmPassword, prefixIcon: Icons.password, obscureText: true)),
                const SizedBox(height: 20),
                SizedBox(
                  width: 300,
                  height: 50,
                  child: ElevatedButton(onPressed: signUp, child: const Text('REGISTER')),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an account?", style: TextStyle(color: AppColors.darkGray)),
                    TextButton(
                      onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen())),
                      child: const Text('LOGIN'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
