import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meditrack/model/medicine.dart';
import 'package:meditrack/repository/medicine_repository.dart';

part 'medicine_event.dart';
part 'medicine_state.dart';

class MedicineBloc extends Bloc<MedicineEvent, MedicineState> {
  //this is dependency injection
  final MedicineRepository medicineRepository;

  MedicineBloc(this.medicineRepository) : super(MedicineLoadingState()) {
    on<LoadMedicinesEvent>((event, emit) {
      //loading state
      emit(MedicineLoadingState());
      //get the stream of the fireStore
      final stream = medicineRepository.getMedicines(event.userId);
      //emits every time a new stream occures
      emit.forEach(
        stream,
        onData: (medicines) => MedicineLoadedState(medicines),
        onError: (_, __) => MedicineErrorState("Failed to load medicines"),
      );
    });

    on<AddMedicineEvent>((event, emit) async {
      await medicineRepository.addMedicine(event.userId, event.medicine);
    });

    on<UpdateMedicineEvent>((event, emit) async {
      await medicineRepository.updateMedicine(event.userId, event.medId, event.medicine);
    });
    on<DeleteMedicineEvent>((event, emit) async {
      await medicineRepository.deleteMedicine(event.userId, event.medId);
    });
  }
}
