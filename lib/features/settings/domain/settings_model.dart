import 'package:cloud_firestore/cloud_firestore.dart';

class SupportedLanguage {
  final String name;
  final String code;
  final bool enabled;
  final bool rtl;
  final int displayOrder;

  const SupportedLanguage({
    required this.name,
    required this.code,
    required this.enabled,
    required this.rtl,
    required this.displayOrder,
  });

  factory SupportedLanguage.fromMap(Map<String, dynamic> map) {
    return SupportedLanguage(
      name: map['name'] ?? '',
      code: map['code'] ?? '',
      enabled: map['enabled'] ?? false,
      rtl: map['rtl'] ?? false,
      displayOrder: map['displayOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'code': code,
      'enabled': enabled,
      'rtl': rtl,
      'displayOrder': displayOrder,
    };
  }

  SupportedLanguage copyWith({
    String? name,
    String? code,
    bool? enabled,
    bool? rtl,
    int? displayOrder,
  }) {
    return SupportedLanguage(
      name: name ?? this.name,
      code: code ?? this.code,
      enabled: enabled ?? this.enabled,
      rtl: rtl ?? this.rtl,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }
}

class GeneralSettings {
  final String appName;
  final String companyName;
  final String website;
  final String supportEmail;
  final String supportPhone;
  final String supportAddress;
  final DateTime updatedAt;
  final String updatedBy;

  const GeneralSettings({
    required this.appName,
    required this.companyName,
    required this.website,
    required this.supportEmail,
    required this.supportPhone,
    required this.supportAddress,
    required this.updatedAt,
    required this.updatedBy,
  });

  factory GeneralSettings.fromMap(Map<String, dynamic> map) {
    return GeneralSettings(
      appName: map['appName'] ?? 'InDiscipleship',
      companyName: map['companyName'] ?? 'InDiscipleship LLC',
      website: map['website'] ?? 'https://indiscipleship.org',
      supportEmail: map['supportEmail'] ?? 'support@indiscipleship.org',
      supportPhone: map['supportPhone'] ?? '',
      supportAddress: map['supportAddress'] ?? '',
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedBy: map['updatedBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'appName': appName,
      'companyName': companyName,
      'website': website,
      'supportEmail': supportEmail,
      'supportPhone': supportPhone,
      'supportAddress': supportAddress,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
    };
  }

  factory GeneralSettings.empty() {
    return GeneralSettings(
      appName: 'InDiscipleship',
      companyName: 'InDiscipleship LLC',
      website: 'https://indiscipleship.org',
      supportEmail: 'support@indiscipleship.org',
      supportPhone: '',
      supportAddress: '',
      updatedAt: DateTime.now(),
      updatedBy: '',
    );
  }
}

class LanguagesSettings {
  final String defaultLanguage;
  final List<SupportedLanguage> supportedLanguages;

  const LanguagesSettings({
    required this.defaultLanguage,
    required this.supportedLanguages,
  });

  factory LanguagesSettings.fromMap(Map<String, dynamic> map) {
    final list = map['supportedLanguages'] as List<dynamic>? ?? [];
    final languages = list
        .map((item) => SupportedLanguage.fromMap(Map<String, dynamic>.from(item)))
        .toList();
    // Sort by display order
    languages.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return LanguagesSettings(
      defaultLanguage: map['defaultLanguage'] ?? 'en',
      supportedLanguages: languages,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'defaultLanguage': defaultLanguage,
      'supportedLanguages': supportedLanguages.map((l) => l.toMap()).toList(),
    };
  }

  factory LanguagesSettings.empty() {
    return const LanguagesSettings(
      defaultLanguage: 'en',
      supportedLanguages: [
        SupportedLanguage(name: 'English', code: 'en', enabled: true, rtl: false, displayOrder: 1),
        SupportedLanguage(name: 'Telugu', code: 'te', enabled: true, rtl: false, displayOrder: 2),
        SupportedLanguage(name: 'Hindi', code: 'hi', enabled: true, rtl: false, displayOrder: 3),
        SupportedLanguage(name: 'Spanish', code: 'es', enabled: true, rtl: false, displayOrder: 4),
        SupportedLanguage(name: 'French', code: 'fr', enabled: true, rtl: false, displayOrder: 5),
        SupportedLanguage(name: 'Greek', code: 'el', enabled: true, rtl: false, displayOrder: 6),
        SupportedLanguage(name: 'Japanese', code: 'ja', enabled: true, rtl: false, displayOrder: 7),
      ],
    );
  }
}

class PrivacySettings {
  final String content;
  final String draftContent;
  final int version;
  final DateTime lastUpdated;
  final String updatedBy;
  final DateTime? publishedAt;
  final String publishedBy;

  const PrivacySettings({
    required this.content,
    required this.draftContent,
    required this.version,
    required this.lastUpdated,
    required this.updatedBy,
    this.publishedAt,
    required this.publishedBy,
  });

  factory PrivacySettings.fromMap(Map<String, dynamic> map) {
    return PrivacySettings(
      content: map['content'] ?? '',
      draftContent: map['draftContent'] ?? map['content'] ?? '',
      version: map['version'] ?? 1,
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedBy: map['updatedBy'] ?? '',
      publishedAt: (map['publishedAt'] as Timestamp?)?.toDate(),
      publishedBy: map['publishedBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'draftContent': draftContent,
      'version': version,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'updatedBy': updatedBy,
      if (publishedAt != null) 'publishedAt': Timestamp.fromDate(publishedAt!),
      'publishedBy': publishedBy,
    };
  }

  factory PrivacySettings.empty() {
    return PrivacySettings(
      content: '',
      draftContent: '',
      version: 0,
      lastUpdated: DateTime.now(),
      updatedBy: '',
      publishedAt: null,
      publishedBy: '',
    );
  }
}

class TermsSettings {
  final String content;
  final String draftContent;
  final int version;
  final DateTime lastUpdated;
  final String updatedBy;
  final DateTime? publishedAt;
  final String publishedBy;

  const TermsSettings({
    required this.content,
    required this.draftContent,
    required this.version,
    required this.lastUpdated,
    required this.updatedBy,
    this.publishedAt,
    required this.publishedBy,
  });

  factory TermsSettings.fromMap(Map<String, dynamic> map) {
    return TermsSettings(
      content: map['content'] ?? '',
      draftContent: map['draftContent'] ?? map['content'] ?? '',
      version: map['version'] ?? 1,
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedBy: map['updatedBy'] ?? '',
      publishedAt: (map['publishedAt'] as Timestamp?)?.toDate(),
      publishedBy: map['publishedBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'draftContent': draftContent,
      'version': version,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'updatedBy': updatedBy,
      if (publishedAt != null) 'publishedAt': Timestamp.fromDate(publishedAt!),
      'publishedBy': publishedBy,
    };
  }

  factory TermsSettings.empty() {
    return TermsSettings(
      content: '',
      draftContent: '',
      version: 0,
      lastUpdated: DateTime.now(),
      updatedBy: '',
      publishedAt: null,
      publishedBy: '',
    );
  }
}

class MaintenanceSettings {
  final bool enabled;
  final String message;
  final DateTime? estimatedEndTime;
  final DateTime updatedAt;
  final String updatedBy;

  const MaintenanceSettings({
    required this.enabled,
    required this.message,
    this.estimatedEndTime,
    required this.updatedAt,
    required this.updatedBy,
  });

  factory MaintenanceSettings.fromMap(Map<String, dynamic> map) {
    return MaintenanceSettings(
      enabled: map['enabled'] ?? false,
      message: map['message'] ?? 'The application is currently under maintenance. Please try again later.',
      estimatedEndTime: (map['estimatedEndTime'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedBy: map['updatedBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'message': message,
      if (estimatedEndTime != null) 'estimatedEndTime': Timestamp.fromDate(estimatedEndTime!),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
    };
  }

  factory MaintenanceSettings.empty() {
    return MaintenanceSettings(
      enabled: false,
      message: 'The application is currently under maintenance. Please try again later.',
      estimatedEndTime: null,
      updatedAt: DateTime.now(),
      updatedBy: '',
    );
  }
}

class FeatureFlagsSettings {
  final Map<String, bool> flags;

  const FeatureFlagsSettings({
    required this.flags,
  });

  factory FeatureFlagsSettings.fromMap(Map<String, dynamic> map) {
    final Map<String, bool> parsedFlags = {};
    map.forEach((key, value) {
      if (value is bool) {
        parsedFlags[key] = value;
      }
    });
    return FeatureFlagsSettings(flags: parsedFlags);
  }

  Map<String, dynamic> toMap() {
    return flags;
  }

  bool isEnabled(String key) => flags[key] ?? false;

  factory FeatureFlagsSettings.empty() {
    return const FeatureFlagsSettings(
      flags: {
        'notifications': true,
        'mentors': true,
        'reports': true,
        'dailyReminders': true,
        'notes': true,
        'leaderboard': false,
        'audioLessons': false,
        'videoLessons': false,
      },
    );
  }
}

class AppVersionSettings {
  final String androidVersion;
  final String iosVersion;
  final String minimumVersion;
  final String releaseNotes;
  final DateTime releaseDate;
  final bool forceUpdate;
  final bool recommendedUpdate;
  final DateTime updatedAt;
  final String updatedBy;

  const AppVersionSettings({
    required this.androidVersion,
    required this.iosVersion,
    required this.minimumVersion,
    required this.releaseNotes,
    required this.releaseDate,
    required this.forceUpdate,
    required this.recommendedUpdate,
    required this.updatedAt,
    required this.updatedBy,
  });

  factory AppVersionSettings.fromMap(Map<String, dynamic> map) {
    return AppVersionSettings(
      androidVersion: map['androidVersion'] ?? '1.0.0',
      iosVersion: map['iosVersion'] ?? '1.0.0',
      minimumVersion: map['minimumVersion'] ?? '1.0.0',
      releaseNotes: map['releaseNotes'] ?? '',
      releaseDate: (map['releaseDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      forceUpdate: map['forceUpdate'] ?? false,
      recommendedUpdate: map['recommendedUpdate'] ?? false,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedBy: map['updatedBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'androidVersion': androidVersion,
      'iosVersion': iosVersion,
      'minimumVersion': minimumVersion,
      'releaseNotes': releaseNotes,
      'releaseDate': Timestamp.fromDate(releaseDate),
      'forceUpdate': forceUpdate,
      'recommendedUpdate': recommendedUpdate,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
    };
  }

  factory AppVersionSettings.empty() {
    return AppVersionSettings(
      androidVersion: '1.0.0',
      iosVersion: '1.0.0',
      minimumVersion: '1.0.0',
      releaseNotes: '',
      releaseDate: DateTime.now(),
      forceUpdate: false,
      recommendedUpdate: false,
      updatedAt: DateTime.now(),
      updatedBy: '',
    );
  }
}

class SettingsModel {
  final GeneralSettings general;
  final LanguagesSettings languages;
  final PrivacySettings privacy;
  final TermsSettings terms;
  final MaintenanceSettings maintenance;
  final FeatureFlagsSettings featureFlags;
  final AppVersionSettings appVersion;

  const SettingsModel({
    required this.general,
    required this.languages,
    required this.privacy,
    required this.terms,
    required this.maintenance,
    required this.featureFlags,
    required this.appVersion,
  });

  factory SettingsModel.empty() {
    return SettingsModel(
      general: GeneralSettings.empty(),
      languages: LanguagesSettings.empty(),
      privacy: PrivacySettings.empty(),
      terms: TermsSettings.empty(),
      maintenance: MaintenanceSettings.empty(),
      featureFlags: FeatureFlagsSettings.empty(),
      appVersion: AppVersionSettings.empty(),
    );
  }

  SettingsModel copyWith({
    GeneralSettings? general,
    LanguagesSettings? languages,
    PrivacySettings? privacy,
    TermsSettings? terms,
    MaintenanceSettings? maintenance,
    FeatureFlagsSettings? featureFlags,
    AppVersionSettings? appVersion,
  }) {
    return SettingsModel(
      general: general ?? this.general,
      languages: languages ?? this.languages,
      privacy: privacy ?? this.privacy,
      terms: terms ?? this.terms,
      maintenance: maintenance ?? this.maintenance,
      featureFlags: featureFlags ?? this.featureFlags,
      appVersion: appVersion ?? this.appVersion,
    );
  }
}
