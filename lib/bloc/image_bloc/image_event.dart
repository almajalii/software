import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class ImageEvent extends Equatable {
  const ImageEvent();

  @override
  List<Object?> get props => [];
}

class PickImageEvent extends ImageEvent {
  const PickImageEvent();
}

class RemoveImageEvent extends ImageEvent {
  const RemoveImageEvent();
}

class SetImageEvent extends ImageEvent {
  final File? image;

  const SetImageEvent(this.image);

  @override
  List<Object?> get props => [image];
}