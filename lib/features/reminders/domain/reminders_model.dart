import 'package:cloud_firestore/cloud_firestore.dart';

class ReminderConfig {
  final bool enabled;
  final String title;
  final String message;
  final String defaultTime; // 24-hour format: "HH:mm"

  const ReminderConfig({
    required this.enabled,
    required this.title,
    required this.message,
    required this.defaultTime,
  });

  ReminderConfig copyWith({
    bool? enabled,
    String? title,
    String? message,
    String? defaultTime,
  }) {
    return ReminderConfig(
      enabled: enabled ?? this.enabled,
      title: title ?? this.title,
      message: message ?? this.message,
      defaultTime: defaultTime ?? this.defaultTime,
    );
  }

  factory ReminderConfig.fromMap(
    Map<String, dynamic> map, {
    required String defaultTitle,
    required String defaultMsg,
    required String defaultTimeVal,
  }) {
    return ReminderConfig(
      enabled: map['enabled'] ?? false,
      title: map['title'] ?? defaultTitle,
      message: map['message'] ?? defaultMsg,
      defaultTime: map['defaultTime'] ?? defaultTimeVal,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'title': title,
      'message': message,
      'defaultTime': defaultTime,
    };
  }

  factory ReminderConfig.empty({
    required String title,
    required String message,
    required String defaultTime,
  }) {
    return ReminderConfig(
      enabled: false,
      title: title,
      message: message,
      defaultTime: defaultTime,
    );
  }
}

class RemindersSettings {
  final ReminderConfig prayerReminder;
  final ReminderConfig lessonReminder;
  final DateTime updatedAt;
  final String updatedBy;
  final int version;

  const RemindersSettings({
    required this.prayerReminder,
    required this.lessonReminder,
    required this.updatedAt,
    required this.updatedBy,
    required this.version,
  });

  RemindersSettings copyWith({
    ReminderConfig? prayerReminder,
    ReminderConfig? lessonReminder,
    DateTime? updatedAt,
    String? updatedBy,
    int? version,
  }) {
    return RemindersSettings(
      prayerReminder: prayerReminder ?? this.prayerReminder,
      lessonReminder: lessonReminder ?? this.lessonReminder,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      version: version ?? this.version,
    );
  }

  factory RemindersSettings.fromMap(Map<String, dynamic> map) {
    return RemindersSettings(
      prayerReminder: ReminderConfig.fromMap(
        Map<String, dynamic>.from(map['prayerReminder'] ?? {}),
        defaultTitle: 'Time to Pray 🙏',
        defaultMsg: 'Spend a few minutes with God today.',
        defaultTimeVal: '07:00',
      ),
      lessonReminder: ReminderConfig.fromMap(
        Map<String, dynamic>.from(map['lessonReminder'] ?? {}),
        defaultTitle: "Today's Lesson is Ready 📖",
        defaultMsg: 'Continue your discipleship journey today.',
        defaultTimeVal: '20:00',
      ),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedBy: map['updatedBy'] ?? '',
      version: map['version'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'prayerReminder': prayerReminder.toMap(),
      'lessonReminder': lessonReminder.toMap(),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
      'version': version,
    };
  }

  factory RemindersSettings.empty() {
    return RemindersSettings(
      prayerReminder: ReminderConfig.empty(
        title: 'Time to Pray 🙏',
        message: 'Spend a few minutes with God today.',
        defaultTime: '07:00',
      ),
      lessonReminder: ReminderConfig.empty(
        title: "Today's Lesson is Ready 📖",
        message: 'Continue your discipleship journey today.',
        defaultTime: '20:00',
      ),
      updatedAt: DateTime.now(),
      updatedBy: '',
      version: 1,
    );
  }
}
