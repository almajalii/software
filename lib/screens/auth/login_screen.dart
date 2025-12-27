import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:meditrack/widgets/MyTextField.dart';
import 'package:meditrack/screens/auth/signup_screen.dart';
import 'package:meditrack/screens/main/navigation_main.dart';
import 'package:meditrack/services/account_manager.dart';
import 'package:meditrack/style/colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> formKey = GlobalKey();
  final MyTextField myTextField = MyTextField();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final LocalAuthentication localAuth = LocalAuthentication();
  final AccountManager _accountManager = AccountManager();

  bool isLoading = false;

  Future<void> signIn() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Save account to account manager
      await _accountManager.saveCurrentAccount();

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
        await storage.write(key: 'email', value: emailController.text.trim());
        await storage.write(key: 'password', value: passwordController.text.trim());
      }

      // Ask if user wants to save password for quick account switching
      final savePassword = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Quick Account Switching'),
          content: const Text(
            'Save your password for quick switching between accounts?\n\n'
                'This allows you to switch accounts without re-entering your password.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No Thanks'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ) ?? false;

      if (savePassword) {
        await _accountManager.saveAccountPassword(
          emailController.text.trim(),
          passwordController.text.trim(),
        );
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const NavigationMain()),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${e.message}')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> resetPassword() async {
    if (emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent!')),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error sending reset email')),
      );
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
                SizedBox(height: 200, width: 200, child: Image.asset('images/1.png')),
                const SizedBox(height: 50),
                Text(
                  'Welcome Back!',
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(fontSize: 30),
                ),
                const SizedBox(height: 50),
                SizedBox(
                  width: 300,
                  child: myTextField.buildTextField(
                    'Email',
                    emailController,
                    prefixIcon: Icons.person,
                    validator: (v) => v!.isEmpty ? "Email can't be empty" : null,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 300,
                  child: myTextField.buildTextField(
                    'Password',
                    passwordController,
                    prefixIcon: Icons.password,
                    obscureText: true,
                    validator: (v) => v!.isEmpty ? "Password can't be empty" : null,
                  ),
                ),
                Container(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: resetPassword,
                    child: const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 300,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : signIn,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('LOGIN'),
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account?", style: TextStyle(color: AppColors.darkGray)),
                    TextButton(
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      ),
                      child: const Text('SIGNUP'),
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