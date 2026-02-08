import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/gesture_model.dart';
import '../../../data/repositories/gesture_repository.dart';

// Events
abstract class GestureEvent {}
class LoadGestures extends GestureEvent {}
class AddGestureEvent extends GestureEvent {
  final GestureModel gesture;
  AddGestureEvent(this.gesture);
}
class DeleteGestureEvent extends GestureEvent {
  final String id;
  DeleteGestureEvent(this.id);
}

// States
abstract class GestureState {}
class GestureLoading extends GestureState {}
class GestureLoaded extends GestureState {
  final List<GestureModel> gestures;
  GestureLoaded(this.gestures);
}
class GestureError extends GestureState {
    final String message;
    GestureError(this.message);
}

class GestureBloc extends Bloc<GestureEvent, GestureState> {
  final GestureRepository repository;

  GestureBloc(this.repository) : super(GestureLoading()) {
    on<LoadGestures>((event, emit) async {
      try {
        // Instant load from local
        emit(GestureLoaded(repository.getGestures()));
        
        // Background sync
        await repository.pullGestures();
        
        // Update with synced data
        emit(GestureLoaded(repository.getGestures()));
      } catch (e) {
        emit(GestureError(e.toString()));
      }
    });

    on<AddGestureEvent>((event, emit) async {
       await repository.addGesture(event.gesture);
       add(LoadGestures());
    });

    on<DeleteGestureEvent>((event, emit) async {
       await repository.deleteGesture(event.id);
       add(LoadGestures());
    });
  }
}
