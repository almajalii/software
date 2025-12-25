import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meditrack/model/medicine.dart';
import 'package:meditrack/repository/medicine_repository.dart';

part 'medicine_event.dart';
part 'medicine_state.dart';

class MedicineBloc extends Bloc<MedicineEvent, MedicineState> {
  final MedicineRepository medicineRepository;

  MedicineBloc(this.medicineRepository) : super(MedicineLoadingState()) {

    //1 Load all medicines
    on<LoadMedicinesEvent>((event, emit) async {
      emit(MedicineLoadingState());

      final stream = medicineRepository.getMedicines(event.userId);

      await emit.forEach(
        stream,
        onData: (medicines) => MedicineLoadedState(medicines),
        onError: (_, __) => MedicineErrorState("Failed to load medicines"),
      );
    });

    //2 Add medicine
    on<AddMedicineEvent>((event, emit) async {
      await medicineRepository.addMedicine(event.userId, event.medicine);
      add(LoadMedicinesEvent(event.userId));
    });

    //3 Update medicine
    on<UpdateMedicineEvent>((event, emit) async {
      await medicineRepository.updateMedicine(
          event.userId, event.medId, event.medicine);
    });

    //4 Remove medicine (move to recycle bin)
    on<RemoveMedicineEvent>((event, emit) async {
      emit(MedicineLoadingState());
      await medicineRepository.removeMedicine(
          event.userId, event.medId, event.medicine);
    });

    //5 Delete medicine permanently
    on<DeleteMedicineEvent>((event, emit) async {
      await medicineRepository.deleteMedicine(event.userId, event.medId);
    });

    //6 Load removed medicines
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

    //7 Search/filter medicines by name (local filtering)
    on<FilterMedicinesEvent>((event, emit) {
      try {
        List<Medicine> currentMeds = [];
        if (state is MedicineLoadedState) {
          currentMeds = (state as MedicineLoadedState).medicines;
        } else if (state is FilteredMedicineState) {
          currentMeds = (state as FilteredMedicineState).medicines;
        }

        final filtered = currentMeds
            .where((med) =>
            med.name.toLowerCase().contains(event.query.toLowerCase()))
            .toList();

        emit(FilteredMedicineState(filtered));
      } catch (e) {
        emit(MedicineErrorState(e.toString()));
      }
    });

    //8 Filter by type
    on<FilterByTypeEvent>((event, emit) async {
      emit(MedicineLoadingState());

      final stream = medicineRepository.getMedicinesByType(
        event.userId,
        event.type,
      );

      await emit.forEach(
        stream,
        onData: (medicines) => FilteredMedicineState(medicines),
        onError: (_, __) => MedicineErrorState("Failed to filter by type"),
      );
    });

    //9 Filter by category
    on<FilterByCategoryEvent>((event, emit) async {
      emit(MedicineLoadingState());

      final stream = medicineRepository.getMedicinesByCategory(
        event.userId,
        event.category,
      );

      await emit.forEach(
        stream,
        onData: (medicines) => FilteredMedicineState(medicines),
        onError: (_, __) => MedicineErrorState("Failed to filter by category"),
      );
    });

    //10 Filter by type AND category
    on<FilterByTypeAndCategoryEvent>((event, emit) async {
      emit(MedicineLoadingState());

      final stream = medicineRepository.getMedicinesByTypeAndCategory(
        event.userId,
        event.type,
        event.category,
      );

      await emit.forEach(
        stream,
        onData: (medicines) => FilteredMedicineState(medicines),
        onError: (_, __) =>
            MedicineErrorState("Failed to filter by type and category"),
      );
    });

    //11 Advanced filter - combines search, type, and category
    on<AdvancedFilterEvent>((event, emit) async {
      emit(MedicineLoadingState());

      final stream = medicineRepository.filterMedicines(
        userId: event.userId,
        searchQuery: event.searchQuery,
        type: event.type,
        category: event.category,
      );

      await emit.forEach(
        stream,
        onData: (medicines) => FilteredMedicineState(medicines),
        onError: (_, __) => MedicineErrorState("Failed to apply filters"),
      );
    });
  }
}