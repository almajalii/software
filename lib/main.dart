import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:meditrack/screens/auth/start.dart';
import 'package:meditrack/style/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());  
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.white,
        canvasColor: AppColors.lightGray,
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.teal,
          background: AppColors.lightGray,
          surface: AppColors.skyBlue,
          onPrimary: AppColors.white,
          onSecondary: AppColors.white,
          onBackground: AppColors.darkGray,
          onSurface: AppColors.darkBlue,
          error: AppColors.error,
          onError: AppColors.white,
        ),
        textTheme: TextTheme(
          titleLarge: TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.bold, fontSize: 25),
          titleMedium: TextStyle(color: AppColors.indigoGray),
          bodyMedium: TextStyle(color: AppColors.darkGray),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.mediumGray,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.mediumGray),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 5,
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.darkBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.teal,
          iconTheme: IconThemeData(color: AppColors.white),
          titleTextStyle: TextStyle(color: AppColors.white, fontSize: 20),
        ),
      ),
      home: const Start(),
    );
  }
}
