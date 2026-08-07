import 'app_user.dart';
import 'user_progress.dart';

class UserManagementViewModel {
  final AppUser user;
  final UserProgress? progress;
  final AppUser? mentor;

  UserManagementViewModel({required this.user, this.progress, this.mentor});

  bool get isDeleted => user.isDeleted;
  bool get isActive => user.accountStatus == AccountStatus.active;
  bool get isDisabled => user.accountStatus == AccountStatus.disabled;
  bool get isPending => user.accountStatus == AccountStatus.pending;

  int get currentWeek => progress?.currentWeek ?? 1;
  int get currentDay => progress?.currentDay ?? 1;
  int get dayStreak => progress?.dayStreak ?? 0;
  double get completionPercentage => progress?.completionPercentage ?? 0.0;
  int get completedLessons => progress?.completedLessonsCount ?? 0;
  DateTime? get lastCompletedAt => progress?.lastCompletedAt;

  String get mentorName => mentor?.displayName ?? 'None';

  UserManagementViewModel copyWith({
    AppUser? user,
    UserProgress? progress,
    AppUser? mentor,
  }) {
    return UserManagementViewModel(
      user: user ?? this.user,
      progress: progress ?? this.progress,
      mentor: mentor ?? this.mentor,
    );
  }
}
