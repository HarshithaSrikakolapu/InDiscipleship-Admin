import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationStatus { draft, scheduled, sending, sent, failed }

enum NotificationTargetType {
  all,
  selectedUsers,
  selectedCountry,
  selectedLanguage,
  mentorsOnly,
}

enum NotificationDelivery { sendNow, schedule }

enum NotificationPriority { high, normal, low }

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String? imageUrl;
  final String? deepLink;
  final NotificationTargetType targetType;
  final List<String> targetValues;
  final Map<String, List<String>> targetFilters;
  final String deliveryType; // "sendNow" | "scheduled"
  final NotificationPriority priority;
  final DateTime? scheduledAt;
  final NotificationStatus status;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? sentAt;

  // Analytics
  final int totalRecipients;
  final int delivered;
  final int failed;
  final int opened;
  final double clickRate;
  final int? deliveryDurationMs;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    this.imageUrl,
    this.deepLink,
    required this.targetType,
    this.targetValues = const [],
    required this.targetFilters,
    required this.deliveryType,
    this.priority = NotificationPriority.normal,
    this.scheduledAt,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.sentAt,
    this.totalRecipients = 0,
    this.delivered = 0,
    this.failed = 0,
    this.opened = 0,
    this.clickRate = 0.0,
    this.deliveryDurationMs,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? imageUrl,
    String? deepLink,
    NotificationTargetType? targetType,
    List<String>? targetValues,
    Map<String, List<String>>? targetFilters,
    String? deliveryType,
    NotificationPriority? priority,
    DateTime? scheduledAt,
    NotificationStatus? status,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? sentAt,
    int? totalRecipients,
    int? delivered,
    int? failed,
    int? opened,
    double? clickRate,
    int? deliveryDurationMs,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      imageUrl: imageUrl ?? this.imageUrl,
      deepLink: deepLink ?? this.deepLink,
      targetType: targetType ?? this.targetType,
      targetValues: targetValues ?? this.targetValues,
      targetFilters: targetFilters ?? this.targetFilters,
      deliveryType: deliveryType ?? this.deliveryType,
      priority: priority ?? this.priority,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sentAt: sentAt ?? this.sentAt,
      totalRecipients: totalRecipients ?? this.totalRecipients,
      delivered: delivered ?? this.delivered,
      failed: failed ?? this.failed,
      opened: opened ?? this.opened,
      clickRate: clickRate ?? this.clickRate,
      deliveryDurationMs: deliveryDurationMs ?? this.deliveryDurationMs,
    );
  }

  Map<String, dynamic> toMap() {
    // Serialize targetType to uppercase string format
    String targetTypeStr = 'ALL';
    if (targetType == NotificationTargetType.selectedUsers) {
      targetTypeStr = 'SELECTED_USERS';
    } else if (targetType == NotificationTargetType.selectedCountry) {
      targetTypeStr = 'SELECTED_COUNTRY';
    } else if (targetType == NotificationTargetType.selectedLanguage) {
      targetTypeStr = 'SELECTED_LANGUAGE';
    } else if (targetType == NotificationTargetType.mentorsOnly) {
      targetTypeStr = 'MENTORS_ONLY';
    }

    return {
      'title': title,
      'message': message,
      'imageUrl': imageUrl,
      'deepLink': deepLink,
      'targetType': targetTypeStr,
      'targetValues': targetValues,
      'targetFilters': {
        'countries': targetType == NotificationTargetType.selectedCountry
            ? targetValues
            : (targetFilters['countries'] ?? []),
        'languages': targetType == NotificationTargetType.selectedLanguage
            ? targetValues
            : (targetFilters['languages'] ?? []),
        'ageGroups': targetFilters['ageGroups'] ?? [],
        'organizations': targetFilters['organizations'] ?? [],
      },
      'deliveryType': deliveryType,
      'priority': priority.name,
      'scheduledAt': scheduledAt != null
          ? Timestamp.fromDate(scheduledAt!)
          : null,
      'status': status.name,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'sentAt': sentAt != null ? Timestamp.fromDate(sentAt!) : null,
      'totalRecipients': totalRecipients,
      'delivered': delivered,
      'failed': failed,
      'opened': opened,
      'clickRate': clickRate,
      'deliveryDurationMs': deliveryDurationMs,
    };
  }

  factory NotificationModel.fromFirestore(Map<String, dynamic> map, String id) {
    // Reconstruct targetType from Firestore string (handling legacy camelCase format too)
    final String targetTypeStr = map['targetType'] ?? 'ALL';
    NotificationTargetType parsedTargetType;
    List<String> parsedTargetValues = List<String>.from(
      map['targetValues'] ?? [],
    );

    // Reconstruct targetFilters map
    final Map<String, dynamic> rawFilters = map['targetFilters'] ?? {};
    final Map<String, List<String>> parsedFilters = {
      'countries': List<String>.from(rawFilters['countries'] ?? []),
      'languages': List<String>.from(rawFilters['languages'] ?? []),
      'ageGroups': List<String>.from(rawFilters['ageGroups'] ?? []),
      'organizations': List<String>.from(rawFilters['organizations'] ?? []),
    };

    if (targetTypeStr == 'SELECTED_USERS' || targetTypeStr == 'selectedUsers') {
      parsedTargetType = NotificationTargetType.selectedUsers;
    } else if (targetTypeStr == 'SELECTED_COUNTRY' ||
        targetTypeStr == 'selectedCountry') {
      parsedTargetType = NotificationTargetType.selectedCountry;
      if (parsedTargetFiltersCountries(parsedFilters).isNotEmpty) {
        parsedTargetValues = parsedTargetFiltersCountries(parsedFilters);
      }
    } else if (targetTypeStr == 'SELECTED_LANGUAGE' ||
        targetTypeStr == 'selectedLanguage') {
      parsedTargetType = NotificationTargetType.selectedLanguage;
      if (parsedTargetFiltersLanguages(parsedFilters).isNotEmpty) {
        parsedTargetValues = parsedTargetFiltersLanguages(parsedFilters);
      }
    } else if (targetTypeStr == 'MENTORS_ONLY' ||
        targetTypeStr == 'mentorsOnly') {
      parsedTargetType = NotificationTargetType.mentorsOnly;
    } else {
      parsedTargetType = NotificationTargetType.all;
    }

    // Resolve deliveryType (handling legacy fields)
    final String parsedDeliveryType =
        map['deliveryType'] ??
        (map['delivery'] == 'schedule' || map['notificationType'] == 'scheduled'
            ? 'scheduled'
            : 'sendNow');

    return NotificationModel(
      id: id,
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      imageUrl: map['imageUrl'],
      deepLink: map['deepLink'],
      targetType: parsedTargetType,
      targetValues: parsedTargetValues,
      targetFilters: parsedFilters,
      deliveryType: parsedDeliveryType,
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      scheduledAt: map['scheduledAt'] != null
          ? (map['scheduledAt'] as Timestamp).toDate()
          : null,
      status: NotificationStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => NotificationStatus.draft,
      ),
      createdBy: map['createdBy'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      sentAt: map['sentAt'] != null
          ? (map['sentAt'] as Timestamp).toDate()
          : null,
      totalRecipients: map['totalRecipients'] ?? 0,
      delivered: map['delivered'] ?? 0,
      failed: map['failed'] ?? 0,
      opened: map['opened'] ?? 0,
      clickRate: (map['clickRate'] ?? 0.0).toDouble(),
      deliveryDurationMs: map['deliveryDurationMs'],
    );
  }

  static List<String> parsedTargetFiltersCountries(
    Map<String, List<String>> filters,
  ) => filters['countries'] ?? [];
  static List<String> parsedTargetFiltersLanguages(
    Map<String, List<String>> filters,
  ) => filters['languages'] ?? [];
}
