import 'package:cloud_firestore/cloud_firestore.dart';
import 'lesson_repository.dart';
import 'models/lesson_model.dart';
import 'models/import_history_model.dart';

class LessonRepositoryImpl implements LessonRepository {
  final FirebaseFirestore _firestore;

  LessonRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _lessonsRef =>
      _firestore.collection('lessons');

  CollectionReference<Map<String, dynamic>> get _importHistoryRef =>
      _firestore.collection('import_history');

  @override
  Stream<List<LessonModel>> getLessons() {
    return _lessonsRef
        .orderBy('week', descending: false)
        .orderBy('day', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => LessonModel.fromJson({...doc.data(), 'lessonId': doc.id}))
          .toList();
    });
  }

  @override
  Future<void> createLesson(LessonModel lesson) async {
    final docId = 'week${lesson.week.toString().padLeft(2, '0')}_day${lesson.day.toString().padLeft(2, '0')}';
    
    // Check if lesson exists
    final doc = await _lessonsRef.doc(docId).get();
    if (doc.exists) {
      throw Exception('Lesson for Week ${lesson.week}, Day ${lesson.day} already exists.');
    }

    final lessonWithId = lesson.copyWith(lessonId: docId);
    await _lessonsRef.doc(docId).set(lessonWithId.toJson());
  }

  @override
  Future<void> updateLesson(LessonModel lesson) async {
    await _lessonsRef.doc(lesson.lessonId).update(lesson.toJson());
  }

  @override
  Future<void> deleteLesson(String lessonId) async {
    await _lessonsRef.doc(lessonId).delete();
  }

  @override
  Future<void> publishLesson(String lessonId, bool isPublished) async {
    await _lessonsRef.doc(lessonId).update({
      'isPublished': isPublished,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> batchImportLessons(List<LessonModel> lessons) async {
    // Firestore batch supports up to 500 operations.
    // We have 60 lessons, so one batch is enough, but let's write it to handle chunking just in case.
    final chunks = <List<LessonModel>>[];
    int chunkSize = 400;
    for (var i = 0; i < lessons.length; i += chunkSize) {
      chunks.add(lessons.sublist(i, i + chunkSize > lessons.length ? lessons.length : i + chunkSize));
    }

    for (var chunk in chunks) {
      final batch = _firestore.batch();
      for (var lesson in chunk) {
        final docId = 'week${lesson.week.toString().padLeft(2, '0')}_day${lesson.day.toString().padLeft(2, '0')}';
        final docRef = _lessonsRef.doc(docId);
        
        // We will just set with merge to update existing ones and create new ones
        final lessonWithId = lesson.copyWith(lessonId: docId);
        final data = lessonWithId.toJson();
        
        // Don't overwrite createdAt if it exists? 
        // With merge: true, if we don't supply createdAt, it won't overwrite it.
        // But if lesson.createdAt is null, toJson doesn't include it. 
        // We can just use set with SetOptions(merge: true).
        batch.set(docRef, data, SetOptions(merge: true));
      }
      await batch.commit();
    }
  }

  @override
  Future<List<String>> getAllLessonIds() async {
    final snapshot = await _lessonsRef.get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }

  @override
  Future<void> saveImportHistory(ImportHistoryModel history) async {
    await _importHistoryRef.doc(history.id).set(history.toJson());
  }

  @override
  Stream<List<ImportHistoryModel>> watchImportHistory() {
    return _importHistoryRef
        .orderBy('importedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ImportHistoryModel.fromJson(doc.data(), doc.id))
            .toList());
  }
}
