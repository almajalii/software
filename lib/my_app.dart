import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:meditrack/screens/auth/start_screen.dart';

import 'package:meditrack/bloc/medicine_bloc/medicine_bloc.dart';
import 'package:meditrack/bloc/dosage_bloc/dosage_bloc.dart';
import 'package:meditrack/bloc/theme_bloc/theme_bloc.dart';

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
          BlocProvider<ThemeBloc>(
            create: (context) => ThemeBloc(),
          ),
          BlocProvider<MedicineBloc>(
            create: (context) => MedicineBloc(
              context.read<MedicineRepository>(),
            ),
          ),
          BlocProvider<DosageBloc>(
            create: (context) => DosageBloc(
              dosageRepository: context.read<DosageRepository>(),
              medicineRepository: context.read<MedicineRepository>(),
            ),
          ),
        ],
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            return MaterialApp(
              title: 'MediTrack',
              debugShowCheckedModeBanner: false,
              theme: themeState.themeData,
              home: const StartScreen(),
            );
          },
        ),
      ),
    );
  }
}