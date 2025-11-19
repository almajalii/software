import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:meditrack/my_app.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

