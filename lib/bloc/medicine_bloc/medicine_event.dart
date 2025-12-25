part of 'medicine_bloc.dart';

abstract class MedicineEvent extends Equatable {
  const MedicineEvent();

  @override
  List<Object?> get props => [];
}

//1 load medicines
final class LoadMedicinesEvent extends MedicineEvent {
  final String userId;
  const LoadMedicinesEvent(this.userId);
}

//2 add medicine
final class AddMedicineEvent extends MedicineEvent {
  final String userId;
  final Medicine medicine;
  const AddMedicineEvent(this.userId, this.medicine);
}

//3 update medicine
final class UpdateMedicineEvent extends MedicineEvent {
  final String userId;
  final String medId;
  final Medicine medicine;
  const UpdateMedicineEvent(this.userId, this.medId, this.medicine);
}

//4 send to the recycle bin
final class RemoveMedicineEvent extends MedicineEvent {
  final String userId;
  final String medId;
  final Medicine medicine;
  const RemoveMedicineEvent(this.userId, this.medId, this.medicine);
}

//5 load removed medicines
final class LoadRemovedMedicinesEvent extends MedicineEvent {
  final String userId;
  const LoadRemovedMedicinesEvent(this.userId);
}

//6 get rid of it in the recycle bin
final class DeleteMedicineEvent extends MedicineEvent {
  final String userId;
  final String medId;
  const DeleteMedicineEvent(this.userId, this.medId);
}

//7 filter medicines by search query
final class FilterMedicinesEvent extends MedicineEvent {
  final String userId;
  final String query;
  const FilterMedicinesEvent(this.userId, this.query);
}

//8 filter medicines by type
final class FilterByTypeEvent extends MedicineEvent {
  final String userId;
  final String type;
  const FilterByTypeEvent(this.userId, this.type);

  @override
  List<Object?> get props => [userId, type];
}

//9 filter medicines by category
final class FilterByCategoryEvent extends MedicineEvent {
  final String userId;
  final String category;
  const FilterByCategoryEvent(this.userId, this.category);

  @override
  List<Object?> get props => [userId, category];
}

//10 filter medicines by type AND category
final class FilterByTypeAndCategoryEvent extends MedicineEvent {
  final String userId;
  final String type;
  final String category;
  const FilterByTypeAndCategoryEvent(this.userId, this.type, this.category);

  @override
  List<Object?> get props => [userId, type, category];
}

//11 advanced filter - combines all filters
final class AdvancedFilterEvent extends MedicineEvent {
  final String userId;
  final String? searchQuery;
  final String? type;
  final String? category;

  const AdvancedFilterEvent({
    required this.userId,
    this.searchQuery,
    this.type,
    this.category,
  });

  @override
  List<Object?> get props => [userId, searchQuery, type, category];
}