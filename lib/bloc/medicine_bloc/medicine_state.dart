part of 'medicine_bloc.dart';

abstract class MedicineState extends Equatable {
  const MedicineState();

  @override
  List<Object> get props => [];
}

//1 medicines are still loading
final class MedicineLoadingState extends MedicineState {}

//2 medicines are loaded->can be retrieved
final class MedicineLoadedState extends MedicineState {
  final List<Medicine> medicines;

  const MedicineLoadedState(this.medicines);
  @override
  List<Object> get props => [medicines];
}

//3 error to load
final class MedicineErrorState extends MedicineState {
  final String errorMessage;

  const MedicineErrorState(this.errorMessage);
  @override
  List<Object> get props => [errorMessage];
}
