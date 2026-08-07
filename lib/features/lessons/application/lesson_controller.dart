import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import '../data/lesson_repository.dart';
import '../data/models/lesson_model.dart';
import '../data/models/import_history_model.dart';
import 'lesson_state.dart';
import 'lesson_providers.dart';
import '../../../core/utils/web_download_helper.dart';

class LessonController extends Notifier<LessonState> {
  late final LessonRepository _repository;

  @override
  LessonState build() {
    _repository = ref.watch(lessonRepositoryProvider);
    return const LessonState();
  }

  void _setLoading(bool value) =>
      state = state.copyWith(isLoading: value, error: null);
  void _setError(String message) => state = LessonState(
    isLoading: false,
    error: message,
    isImporting: state.isImporting,
    importProgress: state.importProgress,
  );

  Future<void> createLesson(LessonModel lesson) async {
    _setLoading(true);
    try {
      // Validate
      _validateLesson(lesson);
      await _repository.createLesson(lesson);
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> updateLesson(LessonModel lesson) async {
    _setLoading(true);
    try {
      _validateLesson(lesson);
      await _repository.updateLesson(lesson);
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> deleteLesson(String lessonId) async {
    _setLoading(true);
    try {
      await _repository.deleteLesson(lessonId);
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> togglePublish(String lessonId, bool isPublished) async {
    _setLoading(true);
    try {
      await _repository.publishLesson(lessonId, isPublished);
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
    }
  }

  void _validateLesson(LessonModel lesson) {
    if (lesson.lessonTitle.trim().isEmpty) {
      throw Exception('Lesson Title is required');
    }
    if (lesson.bibleVerse.trim().isEmpty) {
      throw Exception('Bible Verse is required');
    }
    if (lesson.connect.isEmpty ||
        lesson.connect.every((e) => e.trim().isEmpty)) {
      throw Exception('At least one Connect item is required');
    }
    if (lesson.discover.isEmpty ||
        lesson.discover.every((e) => e.trim().isEmpty)) {
      throw Exception('At least one Discover item is required');
    }
    if (lesson.challenge.isEmpty ||
        lesson.challenge.every((e) => e.trim().isEmpty)) {
      throw Exception('At least one Challenge item is required');
    }
    if (lesson.stillThirsty.isEmpty ||
        lesson.stillThirsty.every((e) => e.trim().isEmpty)) {
      throw Exception('At least one Still Thirsty item is required');
    }
  }

  Future<void> importLessons() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'csv'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        state = state.copyWith(
          isImporting: true,
          importProgress: 0.1,
          error: null,
        );
        final startMs = DateTime.now().millisecondsSinceEpoch;
        final bytes = result.files.single.bytes!;
        final fileName = result.files.single.name;
        final extension =
            result.files.single.extension?.toLowerCase() ?? 'unknown';

        List<LessonModel> lessonsToImport = [];

        if (extension == 'json') {
          final jsonString = utf8.decode(bytes);
          final dynamic jsonData = jsonDecode(jsonString);
          if (jsonData is List) {
            lessonsToImport = jsonData
                .map((e) => LessonModel.fromJson(e))
                .toList();
          } else if (jsonData is Map<String, dynamic> &&
              jsonData.containsKey('lessons')) {
            lessonsToImport = (jsonData['lessons'] as List)
                .map((e) => LessonModel.fromJson(e))
                .toList();
          } else {
            throw Exception('Invalid JSON format. Expected a list of lessons.');
          }
        } else if (extension == 'csv') {
          final csvString = utf8.decode(bytes);
          List<List<dynamic>> rowsAsListOfValues = Csv().decode(csvString);

          if (rowsAsListOfValues.isEmpty) throw Exception('CSV is empty');

          final headers = rowsAsListOfValues.first
              .map((e) => e.toString().toLowerCase())
              .toList();

          for (int i = 1; i < rowsAsListOfValues.length; i++) {
            final row = rowsAsListOfValues[i];
            Map<String, dynamic> jsonMap = {};
            for (int j = 0; j < headers.length; j++) {
              if (j < row.length) {
                jsonMap[headers[j]] = row[j];
              }
            }

            List<String> parseList(dynamic value) {
              if (value == null || value.toString().isEmpty) return [];
              if (value is String) {
                return value
                    .split('|')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
              }
              return [value.toString()];
            }

            lessonsToImport.add(
              LessonModel(
                lessonId: jsonMap['lessonid']?.toString() ?? '',
                week: int.tryParse(jsonMap['week']?.toString() ?? '1') ?? 1,
                day: int.tryParse(jsonMap['day']?.toString() ?? '1') ?? 1,
                lessonTitle: jsonMap['lessontitle']?.toString() ?? '',
                topic: jsonMap['topic']?.toString() ?? '',
                bibleVerse: jsonMap['bibleverse']?.toString() ?? '',
                connect: parseList(jsonMap['connect']),
                discover: parseList(jsonMap['discover']),
                challenge: parseList(jsonMap['challenge']),
                stillThirsty: parseList(jsonMap['stillthirsty']),
                estimatedMinutes:
                    int.tryParse(
                      jsonMap['estimatedminutes']?.toString() ?? '12',
                    ) ??
                    12,
                isPublished:
                    jsonMap['ispublished']?.toString().toLowerCase() == 'true',
              ),
            );
          }
        } else {
          throw Exception('Unsupported file type');
        }

        state = state.copyWith(importProgress: 0.3);

        if (lessonsToImport.isEmpty) {
          throw Exception('No valid lessons found in the file');
        }

        // Fetch existing IDs to calculate stats
        final existingIds = await _repository.getAllLessonIds();

        int created = 0;
        int updated = 0;
        int skipped = 0;
        int failed =
            0; // Set to 0 since batch import will fail wholesale if one fails, or we can just assume all succeed.

        for (var lesson in lessonsToImport) {
          // If we don't have a reliable lessonId locally yet, the repository will generate it as 'week01_day01'.
          // Let's generate it here to check accurately.
          final docId =
              'week${lesson.week.toString().padLeft(2, '0')}_day${lesson.day.toString().padLeft(2, '0')}';
          if (existingIds.contains(docId)) {
            updated++;
          } else {
            created++;
          }
        }

        state = state.copyWith(importProgress: 0.6);

        await _repository.batchImportLessons(lessonsToImport);

        state = state.copyWith(importProgress: 0.9);

        final endMs = DateTime.now().millisecondsSinceEpoch;

        // Save audit log
        try {
          // We need authProvider to get current user, but since we are in a notifier, we might not have direct access.
          // Let's just use 'Admin' for now, or read it if we can.
          // For simplicity in refactor, we use 'Admin' as requested for now.
          await _repository.saveImportHistory(
            ImportHistoryModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              fileName: fileName,
              fileType: extension.toUpperCase(),
              importedBy: 'Admin', // In a real app, inject auth state
              totalRecords: lessonsToImport.length,
              createdRecords: created,
              updatedRecords: updated,
              skippedRecords: skipped,
              failedRecords: failed,
              durationMs: endMs - startMs,
              status: 'Success',
            ),
          );
        } catch (e) {
          // Failed to save import history
        }

        state = state.copyWith(isImporting: false, importProgress: 1.0);
      }
    } catch (e) {
      state = LessonState(
        isLoading: false,
        error: 'Import Failed: ${e.toString()}',
        isImporting: false,
        importProgress: 0.0,
      );
    }
  }

  Future<void> exportLessons(List<LessonModel> lessons, String format) async {
    try {
      if (format == 'json') {
        final List<Map<String, dynamic>> jsonList = lessons
            .map((l) => l.toJson())
            .toList();

        final encoder = JsonEncoder.withIndent('  ', (dynamic item) {
          if (item is Timestamp) {
            return item.toDate().toIso8601String();
          }
          return item.toString();
        });

        final jsonString = encoder.convert(jsonList);

        WebDownloadHelper.downloadStringAsFile(
          jsonString,
          'lessons_export.json',
        );
      } else if (format == 'csv') {
        List<List<dynamic>> rows = [];
        // Header
        rows.add([
          'LessonId',
          'Week',
          'Day',
          'LessonTitle',
          'Topic',
          'BibleVerse',
          'Connect',
          'Discover',
          'Challenge',
          'StillThirsty',
          'EstimatedMinutes',
          'IsPublished',
        ]);

        for (final lesson in lessons) {
          rows.add([
            lesson.lessonId,
            lesson.week,
            lesson.day,
            lesson.lessonTitle,
            lesson.topic,
            lesson.bibleVerse,
            lesson.connect.join('|'),
            lesson.discover.join('|'),
            lesson.challenge.join('|'),
            lesson.stillThirsty.join('|'),
            lesson.estimatedMinutes,
            lesson.isPublished,
          ]);
        }

        final csvString = rows
            .map((row) {
              return row
                  .map((item) {
                    String str = item.toString();
                    if (str.contains(',') ||
                        str.contains('"') ||
                        str.contains('\n')) {
                      str = '"${str.replaceAll('"', '""')}"';
                    }
                    return str;
                  })
                  .join(',');
            })
            .join('\n');

        WebDownloadHelper.downloadStringAsFile(csvString, 'lessons_export.csv');
      }
    } catch (e) {
      _setError('Export Failed: ${e.toString()}');
    }
  }
}
