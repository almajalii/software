import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'image_event.dart';
import 'image_state.dart';


class ImageBloc extends Bloc<ImageEvent, ImageState> {
  ImageBloc() : super(ImageInitial()) {
    on<SetImageEvent>(_onSetImage);
    on<RemoveImageEvent>(_onRemoveImage);
  }

  void _onSetImage(SetImageEvent event, Emitter<ImageState> emit) {
    if (event.image != null) {
      print('🖼️ BLoC: Image set - ${event.image!.path}');
      emit(ImageSelected(event.image!));
    } else {
      print('🖼️ BLoC: No image provided');
      emit(ImageEmpty());
    }
  }

  void _onRemoveImage(RemoveImageEvent event, Emitter<ImageState> emit) {
    print('🗑️ BLoC: Image removed');
    emit(ImageEmpty());
  }
}