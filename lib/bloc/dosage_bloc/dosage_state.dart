part of 'dosage_bloc.dart';

abstract class DosageState extends Equatable {
  const DosageState();

  @override
  List<Object?> get props => [];
}
//lodaing, loaded, error
class DosageLoadingState extends DosageState {}

class DosageLoadedState extends DosageState {
  final Map<String, List<Dosage>> dosagesByMedicine; // medicineId -> dosages
  const DosageLoadedState(this.dosagesByMedicine);

  @override
  List<Object?> get props => [dosagesByMedicine];
}

class DosageErrorState extends DosageState {
  final String errorMessage;
  const DosageErrorState(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
