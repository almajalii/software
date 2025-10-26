import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:meditrack/classes/MyTextField.dart';
import 'package:meditrack/screens/home.dart';
import 'package:meditrack/screens/auth/LogIn.dart';
import 'package:meditrack/style/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Createacc extends StatefulWidget {
  Createacc({super.key});

  @override
  State<Createacc> createState() => _CreateaccState();
}

class _CreateaccState extends State<Createacc> {
  GlobalKey<FormState> formKey = GlobalKey();

  TextEditingController username = TextEditingController();
  TextEditingController mail = TextEditingController();
  TextEditingController phonenumber = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController confirmPassword = TextEditingController();
  final myTextField = MyTextField();
  Future<void> signUp() async {
    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: mail.text.trim(),
            password: password.text.trim(),
          );
      await userCredential.user?.updateDisplayName(username.text.trim());
      // Save user data to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'uid': userCredential.user!.uid,
            'email': mail.text.trim(),
            'phonenumber': phonenumber.text.trim(),
            'displayName': username.text.trim(),
            'allergies': '',
            'medicalConditions': '',
            'emergencyContact': '',
          });

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup successful! Redirecting to home...')),
      );

      // Small delay to ensure context is still valid before navigation
      await Future.delayed(Duration(milliseconds: 300));

      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (context) => home()));
    } catch (e) {
      // Optional: show error to user
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Signup failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width,
          child: Form(
            key: formKey,
            child: Column(
              children: [
                SizedBox(height: 40),
                //logo
                SizedBox(
                  height: 200,
                  width: 200,
                  child: Image.asset('images/1.png'),
                ),
                //text
                Text(
                  'Create Your Account!',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge!.copyWith(fontSize: 30),
                ),
                SizedBox(height: 10),
                // Username
                Container(
                  width: 300,
                  color: Colors.white,
                  child: myTextField.buildTextField(
                    'Username',
                    username,
                    prefixIcon: Icons.person,
                    validator: (value) {
                      if (value!.isEmpty) return "*";
                      if (value.length < 6) {
                        return "Username must be at least 6 chars";
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 10),
                // Email
                Container(
                  width: 300,
                  color: Colors.white,
                  child: myTextField.buildTextField(
                    'Email',
                    mail,
                    prefixIcon: Icons.email,
                    validator: (value) {
                      if (value!.isEmpty) return "*";
                      if (!value.contains("@")) return "Enter a valid email";
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 10),
                // Phone Number
                SizedBox(
                  width: 300,
                  child: myTextField.buildTextField(
                    'Phone Number',
                    phonenumber,
                    prefixIcon: Icons.phone,
                    validator: (value) {
                      if (value!.isEmpty) return "*";
                      final numericRegex = RegExp(r'^[0-9]+$');
                      if (!numericRegex.hasMatch(value)) {
                        return "Please enter only numbers";
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 10),
                // Password
                SizedBox(
                  width: 300,
                  child: myTextField.buildTextField(
                    'Password',
                    password,
                    prefixIcon: Icons.password,
                      validator: (value) {
                      if (value!.isEmpty) return "*";
                      if (value.length < 6) {
                        return "Password must be at least 6 characters";
                      }
                      if (!RegExp(r'[!@#\$&*~]').hasMatch(value)) {
                        return "Password must be Stronger";
                      }
                      return null;
                    },
                    obscureText: true
                  ),
                ),
                SizedBox(height: 10),
                // Confirm Password
                SizedBox(
                  width: 300,
                  child: myTextField.buildTextField(
                    'Confirm Password',
                    confirmPassword,
                    prefixIcon: Icons.password,
                    validator: (value) {
                      if (value!.isEmpty) return "*";
                      if (value != password.text) {
                        return "Passwords do not match";
                      }
                      return null;
                    },
                     obscureText: true,
                  ),
                ),
                SizedBox(height: 10),
                // Register Button
                SizedBox(
                  height: 50,
                  width: 300,
                  child: ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        signUp();
                      }
                    },
                    child: Text(
                      'REGISTER',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                // Already have account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account?",
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        color: AppColors.darkGray,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => Login()),
                        );
                      },
                      child: Text('LOGIN'),
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
