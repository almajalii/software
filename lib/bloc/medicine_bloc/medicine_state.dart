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

//3 medicines are in the recycle bin
final class MedicineRemovedState extends MedicineState {
  final List<Medicine> medicines;

  const MedicineRemovedState(this.medicines);
  @override
  List<Object> get props => [medicines];
}

//load medicines in recycle bin
final class RemovedMedicinesLoadedState extends MedicineState {
  final List<Medicine> removedMedicines;

  const RemovedMedicinesLoadedState(this.removedMedicines);

  @override
  List<Object> get props => [removedMedicines];
}

final class RemovedMedicinesState extends MedicineState {

  const RemovedMedicinesState();

  @override
  List<Object> get props => [];
}
//for search
final class FilteredMedicineState extends MedicineState {
  final List<Medicine> medicines;
  const FilteredMedicineState(this.medicines);

  @override
  List<Object> get props => [medicines];
}




