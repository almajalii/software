import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:meditrack/screens/auth/start_screen.dart';
import 'package:meditrack/style/colors.dart';

import 'package:meditrack/bloc/medicine_bloc/medicine_bloc.dart';
import 'package:meditrack/bloc/dosage_bloc/dosage_bloc.dart';

import 'package:meditrack/repository/medicine_repository.dart';
import 'package:meditrack/repository/dosage_repository.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<MedicineRepository>(
          create: (_) => MedicineRepository(),
        ),
        RepositoryProvider<DosageRepository>(
          create: (_) => DosageRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<MedicineBloc>(
            create: (context) => MedicineBloc(
              context.read<MedicineRepository>(),
            ),
          ),
          BlocProvider<DosageBloc>(
            create: (context) => DosageBloc(
              dosageRepository: context.read<DosageRepository>(), medicineRepository: context.read<MedicineRepository>(),
            ),
          ),
        ],
        child: MaterialApp(
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
              titleLarge: TextStyle(
                  color: AppColors.darkBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 25),
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
                textStyle:
                    const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: AppColors.teal,
              iconTheme: IconThemeData(color: AppColors.white),
              titleTextStyle:
                  const TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
          home: const StartScreen(),
        ),
      ),
    );
  }
}
