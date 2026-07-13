enum AccountStatus {
  active,
  disabled,
  pending,
}

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String? username;
  final String photoUrl;
  final DateTime? createdAt;
  final bool isActive;
  final AccountStatus accountStatus;
  final String? selectedLanguage;
  final String? ageGroup;
  final DateTime? lastLoginAt;
  final DateTime? lastAppOpenAt;
  final String? platform;
  final String? country;
  final bool isMentor;
  final String? mentorStatus;
  final DateTime? mentorSince;
  final String? mentorId;
  final String? approvedBy;
  final DateTime? approvedAt;
  
  // Soft Delete fields
  final bool isDeleted;
  final DateTime? deletedAt;
  final String? deletedBy;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.username,
    required this.photoUrl,
    this.createdAt,
    this.isActive = true,
    this.accountStatus = AccountStatus.active,
    this.selectedLanguage,
    this.ageGroup,
    this.lastLoginAt,
    this.lastAppOpenAt,
    this.platform,
    this.country,
    this.isMentor = false,
    this.mentorStatus,
    this.mentorSince,
    this.mentorId,
    this.approvedBy,
    this.approvedAt,
    this.isDeleted = false,
    this.deletedAt,
    this.deletedBy,
  });

  factory AppUser.fromFirestore(Map<String, dynamic> data, String documentId) {
    AccountStatus parseStatus(String? status, bool active) {
      if (status != null) {
        return AccountStatus.values.firstWhere(
          (e) => e.name == status,
          orElse: () => AccountStatus.active,
        );
      }
      return active ? AccountStatus.active : AccountStatus.disabled;
    }

    final bool active = data['isActive'] ?? true;

    return AppUser(
      uid: documentId,
      email: data['email'] ?? '',
      displayName: data['fullName'] ?? data['name'] ?? data['displayName'] ?? 'Unknown User',
      username: data['username'],
      photoUrl: data['photoUrl'] ?? '',
      createdAt: data['createdAt'] != null ? (data['createdAt'] as dynamic).toDate() : null,
      isActive: active,
      accountStatus: parseStatus(data['accountStatus'], active),
      selectedLanguage: data['selectedLanguage'] ?? data['language'],
      ageGroup: data['ageGroup'],
      lastLoginAt: data['lastLoginAt'] != null ? (data['lastLoginAt'] as dynamic).toDate() : null,
      lastAppOpenAt: data['lastAppOpenAt'] != null ? (data['lastAppOpenAt'] as dynamic).toDate() : null,
      platform: data['platform'],
      country: data['country'],
      isMentor: data['isMentor'] ?? false,
      mentorStatus: data['mentorStatus'],
      mentorSince: data['mentorSince'] != null ? (data['mentorSince'] as dynamic).toDate() : null,
      mentorId: data['mentorId'],
      approvedBy: data['approvedBy'],
      approvedAt: data['approvedAt'] != null ? (data['approvedAt'] as dynamic).toDate() : null,
      isDeleted: data['isDeleted'] ?? false,
      deletedAt: data['deletedAt'] != null ? (data['deletedAt'] as dynamic).toDate() : null,
      deletedBy: data['deletedBy'],
    );
  }
}
