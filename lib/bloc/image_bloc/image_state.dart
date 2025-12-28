import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class ImageState extends Equatable {
  const ImageState();

  @override
  List<Object?> get props => [];
}

class ImageInitial extends ImageState {}

class ImageLoading extends ImageState {}

class ImageSelected extends ImageState {
  final File image;

  const ImageSelected(this.image);

  @override
  List<Object?> get props => [image];
}

class ImageEmpty extends ImageState {}

class ImageError extends ImageState {
  final String message;

  const ImageError(this.message);

  @override
  List<Object?> get props => [message];
}