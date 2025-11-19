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
    //1
    on<LoadMedicinesEvent>((event, emit) async {
      emit(MedicineLoadingState());

      final stream = medicineRepository.getMedicines(event.userId);

      await emit.forEach(
        stream,
        onData: (medicines) => MedicineLoadedState(medicines),
        onError: (_, __) => MedicineErrorState("Failed to load medicines"),
      );
    });

    //2
    on<AddMedicineEvent>((event, emit) async {
      await medicineRepository.addMedicine(event.userId, event.medicine);
      add(LoadMedicinesEvent(event.userId));
    });
    //3
    on<UpdateMedicineEvent>((event, emit) async {
      await medicineRepository.updateMedicine(
          event.userId, event.medId, event.medicine);
    });
    //4
    on<RemoveMedicineEvent>((event, emit) async {
      emit(MedicineLoadingState());
      await medicineRepository.removeMedicine(
          event.userId, event.medId, event.medicine);
    });
    //5
    on<DeleteMedicineEvent>((event, emit) async {
      await medicineRepository.deleteMedicine(event.userId, event.medId);
    });
    //6
    on<LoadRemovedMedicinesEvent>((event, emit) async {
      emit(MedicineLoadingState());

      final stream = medicineRepository.getRemovedMedicines(event.userId);

      await emit.forEach(
        stream,
        onData: (medicines) => RemovedMedicinesLoadedState(medicines),
        onError: (_, __) =>
            MedicineErrorState("Failed to load removed medicines"),
      );
    });

    //7. Search / filter medicines (without emit.forEach)
    on<FilterMedicinesEvent>((event, emit) {
      try {
        // Get the current loaded medicines from state
        List<Medicine> currentMeds = [];
        if (state is MedicineLoadedState) {
          currentMeds = (state as MedicineLoadedState).medicines;
        } else if (state is FilteredMedicineState) {
          currentMeds = (state as FilteredMedicineState).medicines;
        }

        // Filter locally based on query
        final filtered = currentMeds
            .where((med) =>
            med.name.toLowerCase().contains(event.query.toLowerCase()))
            .toList();

        emit(FilteredMedicineState(filtered));
      } catch (e) {
        emit(MedicineErrorState(e.toString()));
      }
    });
  }
  }