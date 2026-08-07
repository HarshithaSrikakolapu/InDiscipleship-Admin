import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/lesson_repository.dart';
import '../data/lesson_repository_impl.dart';
import '../data/models/lesson_model.dart';
import 'lesson_controller.dart';
import 'lesson_state.dart';

final lessonRepositoryProvider = Provider<LessonRepository>((ref) {
  return LessonRepositoryImpl();
});

final lessonControllerProvider =
    NotifierProvider<LessonController, LessonState>(() {
      return LessonController();
    });

final lessonsStreamProvider = StreamProvider<List<LessonModel>>((ref) {
  final repository = ref.watch(lessonRepositoryProvider);
  return repository.getLessons();
});
