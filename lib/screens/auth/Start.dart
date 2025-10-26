import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meditrack/screens/auth/SignUp.dart';
import 'package:meditrack/screens/auth/login.dart';
import 'package:meditrack/screens/home.dart';

class Start extends StatefulWidget {
  const Start({super.key});

  @override
  State<Start> createState() => _StartState();
}

class _StartState extends State<Start> {
  bool isLoading = true;
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();//called exactly once
    checkAuthState();
  }

  Future<void> checkAuthState() async {
    await Future.delayed(const Duration(seconds: 1)); // delay
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      isLoggedIn = (user != null);
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
    if (isLoggedIn) {
      return home(); // Already logged in
    }

    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 85),
            //Logo
            Image.asset('images/1.png', width: 300, height: 300, fit: BoxFit.cover),
            const SizedBox(height: 130),
            // Sign in
            Container(
              height: 80,
              width: 400,
              padding: EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) =>  Login()),
                  );
                },
                child: Text('LOGIN', style: Theme.of(context).textTheme.titleLarge),
              ),
            ),

            // Sign up
            Container(
              height: 80,
              width: 400,
              padding: EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) =>  Createacc()),
                  );
                },
                child: Text('SIGNUP', style: Theme.of(context).textTheme.titleLarge),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
