import 'package:cloud_firestore/cloud_firestore.dart';

class LessonModel {
  final String lessonId;
  final int week;
  final int day;
  final String lessonTitle;
  final String topic;
  final String bibleVerse;
  final List<String> connect;
  final List<String> discover;
  final List<String> challenge;
  final List<String> stillThirsty;
  final int estimatedMinutes;
  final bool isPublished;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;

  LessonModel({
    required this.lessonId,
    required this.week,
    required this.day,
    required this.lessonTitle,
    required this.topic,
    required this.bibleVerse,
    required this.connect,
    required this.discover,
    required this.challenge,
    required this.stillThirsty,
    required this.estimatedMinutes,
    this.isPublished = false,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      lessonId: json['lessonId'] as String? ?? '',
      week: json['week'] as int? ?? 1,
      day: json['day'] as int? ?? 1,
      lessonTitle: json['lessonTitle'] as String? ?? '',
      topic: json['topic'] as String? ?? '',
      bibleVerse: json['bibleVerse'] as String? ?? '',
      connect: (json['connect'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      discover: (json['discover'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      challenge: (json['challenge'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      stillThirsty: (json['stillThirsty'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      estimatedMinutes: json['estimatedMinutes'] as int? ?? 12,
      isPublished: json['isPublished'] as bool? ?? false,
      createdAt: json['createdAt'] != null ? (json['createdAt'] as Timestamp).toDate() : null,
      updatedAt: json['updatedAt'] != null ? (json['updatedAt'] as Timestamp).toDate() : null,
      createdBy: json['createdBy'] as String?,
      updatedBy: json['updatedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lessonId': lessonId,
      'week': week,
      'day': day,
      'lessonTitle': lessonTitle,
      'topic': topic,
      'bibleVerse': bibleVerse,
      'connect': connect,
      'discover': discover,
      'challenge': challenge,
      'stillThirsty': stillThirsty,
      'estimatedMinutes': estimatedMinutes,
      'isPublished': isPublished,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (createdBy != null) 'createdBy': createdBy,
      if (updatedBy != null) 'updatedBy': updatedBy,
    };
  }

  LessonModel copyWith({
    String? lessonId,
    int? week,
    int? day,
    String? lessonTitle,
    String? topic,
    String? bibleVerse,
    List<String>? connect,
    List<String>? discover,
    List<String>? challenge,
    List<String>? stillThirsty,
    int? estimatedMinutes,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) {
    return LessonModel(
      lessonId: lessonId ?? this.lessonId,
      week: week ?? this.week,
      day: day ?? this.day,
      lessonTitle: lessonTitle ?? this.lessonTitle,
      topic: topic ?? this.topic,
      bibleVerse: bibleVerse ?? this.bibleVerse,
      connect: connect ?? this.connect,
      discover: discover ?? this.discover,
      challenge: challenge ?? this.challenge,
      stillThirsty: stillThirsty ?? this.stillThirsty,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
