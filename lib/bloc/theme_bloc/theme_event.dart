part of 'theme_bloc.dart';

abstract class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object> get props => [];
}

class ToggleThemeEvent extends ThemeEvent {}

class SetThemeEvent extends ThemeEvent {
  final bool isDarkMode;

  const SetThemeEvent(this.isDarkMode);

  @override
  List<Object> get props => [isDarkMode];
}