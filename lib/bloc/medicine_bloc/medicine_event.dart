part of 'medicine_bloc.dart';

abstract class MedicineEvent extends Equatable {
  const MedicineEvent();

  @override
  List<Object> get props => [];
}
//load, add, update, delete

final class LoadMedicinesEvent extends MedicineEvent {
  final String userId;
  const LoadMedicinesEvent(this.userId);
}

final class AddMedicineEvent extends MedicineEvent {
  final String userId;
  final Medicine medicine;
  const AddMedicineEvent(this.userId, this.medicine);
}

final class UpdateMedicineEvent extends MedicineEvent {
  final String userId;
  final String medId;
  final Medicine medicine;
  const UpdateMedicineEvent(this.userId, this.medId, this.medicine);
}
//send to the recycle bin
final class RemoveMedicineEvent extends MedicineEvent {
  final String userId;
  final String medId;
  final Medicine medicine;
  const RemoveMedicineEvent(this.userId, this.medId, this.medicine);
}

final class LoadRemovedMedicinesEvent extends MedicineEvent {
  final String userId;
  const LoadRemovedMedicinesEvent(this.userId);
}

//get rid of it in the recycle bin
final class DeleteMedicineEvent extends MedicineEvent {
  final String userId;
  final String medId;
  const DeleteMedicineEvent(this.userId, this.medId);
}

final class FilterMedicinesEvent extends MedicineEvent {
  final String userId;
  final String query;
  const FilterMedicinesEvent(this.userId, this.query);
}

