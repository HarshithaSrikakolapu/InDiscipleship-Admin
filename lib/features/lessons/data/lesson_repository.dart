import 'models/lesson_model.dart';
import 'models/import_history_model.dart';

abstract class LessonRepository {
  Stream<List<LessonModel>> getLessons();
  Future<void> createLesson(LessonModel lesson);
  Future<void> updateLesson(LessonModel lesson);
  Future<void> deleteLesson(String lessonId);
  Future<void> publishLesson(String lessonId, bool isPublished);
  Future<void> batchImportLessons(List<LessonModel> lessons);
  Future<List<String>> getAllLessonIds();
  Future<void> saveImportHistory(ImportHistoryModel history);
  Stream<List<ImportHistoryModel>> watchImportHistory();
}
