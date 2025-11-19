import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:meditrack/screens/auth/login_screen.dart';
import 'package:meditrack/screens/main/navigation_main.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  bool isLoading = true;
  bool isLoggedIn = false;

  final storage = const FlutterSecureStorage();
  final localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    checkAuthState();
  }

  Future<void> checkAuthState() async {
    await Future.delayed(const Duration(seconds: 1));

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        isLoggedIn = true;
        isLoading = false;
      });
      return;
    }

    final biometricEnabled = await storage.read(key: 'biometric_enabled');

    if (biometricEnabled == 'true') {
      try {
        final canCheck = await localAuth.canCheckBiometrics;
        final availableBiometrics = await localAuth.getAvailableBiometrics();

        if (canCheck && availableBiometrics.isNotEmpty) {
          final authenticated = await localAuth.authenticate(
            localizedReason: 'Login using biometrics',
            options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
          );

          if (authenticated) {
            final email = await storage.read(key: 'email');
            final password = await storage.read(key: 'password');

            if (email != null && password != null) {
              await FirebaseAuth.instance.signInWithEmailAndPassword(
                  email: email, password: password);

              setState(() {
                isLoggedIn = true;
                isLoading = false;
              });
              return;
            }
          }
        }
      } catch (e) {
        debugPrint("Biometric login error: $e");
      }
    }

    setState(() {
      isLoggedIn = false;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (isLoggedIn) return const NavigationMain();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 200, width: 200, child: Image.asset("images/1.png")),
                const SizedBox(height: 40),
                Text(
                  "Welcome to MediTrack",
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(fontSize: 26),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),
                SizedBox(
                  width: 300,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
                    },
                    child: const Text("LOGIN"),
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: 300,
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text("SIGNUP"),
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
