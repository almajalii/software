import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meditrack/model/dosage.dart';
import 'package:meditrack/repository/dosage_repository.dart';

part 'dosage_event.dart';
part 'dosage_state.dart';

class DosageBloc extends Bloc<DosageEvent, DosageState> {
  //dependency injection
  final DosageRepository dosageRepository;

  DosageBloc({required this.dosageRepository}) : super(DosageLoadingState()) {
    on<LoadDosagesEvent>(_loadDosages);
    on<AddDosageEvent>(_addDosage);
    on<UpdateDosageEvent>(_updateDosage);
    on<DeleteDosageEvent>(_deleteDosage);
    on<MarkDosageTimeTakenEvent>(_onMarkDosageTimeTaken);
  }

  //load the dosages for a single medicine while keeping any already-loaded dosages for other medicines intact in the state.
  Future<void> _loadDosages(LoadDosagesEvent event, Emitter<DosageState> emit) async {
    try {
      //gets the dosages of this specific medicine
      final dosages = await dosageRepository.getDosages(event.userId, event.medId);

      final currentState = state;
      //Updates the map with the new list for this medicine only.
      
      Map<String, List<Dosage>> updated = {};//of all medicines and their dosages
      //we add the dosages of other meds first
      if (currentState is DosageLoadedState) {
        updated.addAll(currentState.dosagesByMedicine);
      }
      //then for this specific med we assign the dosages
      updated[event.medId] = dosages;

      emit(DosageLoadedState(updated));
    } catch (e) {
      emit(DosageErrorState(e.toString()));
    }
  }

  Future<void> _addDosage(AddDosageEvent event, Emitter<DosageState> emit) async {
    try {
      await dosageRepository.addDosage(event.userId, event.medId, event.dosageData);

      final updatedDosages = await dosageRepository.getDosages(event.userId, event.medId);

      final currentState = state;
      Map<String, List<Dosage>> updated = {};

      if (currentState is DosageLoadedState) {
        updated.addAll(currentState.dosagesByMedicine);
      }

      updated[event.medId] = updatedDosages;

      emit(DosageLoadedState(updated));
    } catch (e) {
      emit(DosageErrorState(e.toString()));
    }
  }

  Future<void> _updateDosage(UpdateDosageEvent event, Emitter<DosageState> emit) async {
    try {
      await dosageRepository.updateDosage(event.userId, event.medId, event.dosageId, event.updatedData);

      final updatedDosages = await dosageRepository.getDosages(event.userId, event.medId);

      final currentState = state;
      Map<String, List<Dosage>> updated = {};
      if (currentState is DosageLoadedState) updated.addAll(currentState.dosagesByMedicine);

      updated[event.medId] = updatedDosages;
      emit(DosageLoadedState(updated));
    } catch (e) {
      emit(DosageErrorState(e.toString()));
    }
  }

  Future<void> _deleteDosage(DeleteDosageEvent event, Emitter<DosageState> emit) async {
    try {
      await dosageRepository.deleteDosage(event.userId, event.medId, event.dosageId);

      final updatedDosages = await dosageRepository.getDosages(event.userId, event.medId);

      final currentState = state;
      Map<String, List<Dosage>> updated = {};
      if (currentState is DosageLoadedState) updated.addAll(currentState.dosagesByMedicine);

      updated[event.medId] = updatedDosages;
      emit(DosageLoadedState(updated));
    } catch (e) {
      emit(DosageErrorState(e.toString()));
    }
  }

  Future<void> _onMarkDosageTimeTaken(MarkDosageTimeTakenEvent event, Emitter<DosageState> emit) async {
    try {
      await dosageRepository.markTimeAsTaken(event.userId, event.medId, event.dosageId, event.timeIndex);

      final updatedDosages = await dosageRepository.getDosages(event.userId, event.medId);

      final currentState = state;
      Map<String, List<Dosage>> updated = {};
      if (currentState is DosageLoadedState) updated.addAll(currentState.dosagesByMedicine);

      updated[event.medId] = updatedDosages;
      emit(DosageLoadedState(updated));
    } catch (e) {
      emit(DosageErrorState(e.toString()));
    }
  }
}
