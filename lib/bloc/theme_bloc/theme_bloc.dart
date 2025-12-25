import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:meditrack/style/colors.dart';

part 'theme_event.dart';
part 'theme_state.dart';

class ThemeBloc extends HydratedBloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(ThemeState(themeData: _lightTheme, isDarkMode: false)) {
    on<ToggleThemeEvent>(_onToggleTheme);
    on<SetThemeEvent>(_onSetTheme);
  }

  void _onToggleTheme(ToggleThemeEvent event, Emitter<ThemeState> emit) {
    emit(ThemeState(
      themeData: state.isDarkMode ? _lightTheme : _darkTheme,
      isDarkMode: !state.isDarkMode,
    ));
  }

  void _onSetTheme(SetThemeEvent event, Emitter<ThemeState> emit) {
    emit(ThemeState(
      themeData: event.isDarkMode ? _darkTheme : _lightTheme,
      isDarkMode: event.isDarkMode,
    ));
  }

  @override
  ThemeState? fromJson(Map<String, dynamic> json) {
    try {
      final isDarkMode = json['isDarkMode'] as bool? ?? false;
      return ThemeState(
        themeData: isDarkMode ? _darkTheme : _lightTheme,
        isDarkMode: isDarkMode,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(ThemeState state) {
    try {
      return {'isDarkMode': state.isDarkMode};
    } catch (_) {
      return null;
    }
  }

  static final ThemeData _lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.white,
    canvasColor: AppColors.lightGray,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.teal,
      surface: AppColors.skyBlue,
      onPrimary: AppColors.white,
      onSecondary: AppColors.white,
      onSurface: AppColors.darkBlue,
      error: AppColors.error,
      onError: AppColors.white,
    ),
    cardColor: Colors.white,
    textTheme: TextTheme(
      titleLarge: TextStyle(
        color: AppColors.darkBlue,
        fontWeight: FontWeight.bold,
        fontSize: 25,
      ),
      titleMedium: TextStyle(color: AppColors.indigoGray),
      bodyMedium: TextStyle(color: AppColors.darkGray),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightGray,
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
        textStyle: const TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.teal,
      iconTheme: IconThemeData(color: AppColors.white),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
    ),
  );

  static final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: Color(0xFF121212),
    canvasColor: Color(0xFF1E1E1E),
    colorScheme: ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.teal,
      surface: Color(0xFF1E1E1E),
      onPrimary: AppColors.darkBlue,
      onSecondary: AppColors.white,
      onSurface: AppColors.white,
      error: AppColors.error,
      onError: AppColors.white,
    ),
    cardColor: Color(0xFF1E1E1E),
    textTheme: TextTheme(
      titleLarge: TextStyle(
        color: AppColors.white,
        fontWeight: FontWeight.bold,
        fontSize: 25,
      ),
      titleMedium: TextStyle(color: Colors.grey[300]),
      bodyMedium: TextStyle(color: Colors.grey[400]),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF2C2C2C),
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF3C3C3C)),
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
        textStyle: const TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      iconTheme: IconThemeData(color: AppColors.white),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
    ),
  );
}