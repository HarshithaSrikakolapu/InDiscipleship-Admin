import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/app_user.dart';
import '../domain/user_management_view_model.dart';
import '../data/user_management_repository.dart';
import '../application/user_management_controller.dart';
import 'widgets/assign_mentor_dialog.dart';
import 'widgets/edit_user_dialog.dart';

final userStreamDetailsProvider = StreamProvider.family<UserManagementViewModel?, String>((ref, uid) {
  if (uid.isEmpty) return Stream.value(null);
  return ref.watch(userManagementRepositoryProvider).getUserStreamById(uid);
});

class UserDetailsScreen extends ConsumerWidget {
  final String uid;

  const UserDetailsScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsyncValue = ref.watch(userStreamDetailsProvider(uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        actions: [
          userAsyncValue.maybeWhen(
            data: (vm) => vm != null ? _buildAppbarActions(context, ref, vm) : const SizedBox(),
            orElse: () => const SizedBox(),
          )
        ],
      ),
      body: SafeArea(
        child: userAsyncValue.when(
          data: (vm) {
            if (vm == null) {
              return const Center(child: Text('User not found.'));
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(context, vm),
                  const SizedBox(height: 24),
                  
                  // Sections
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            _buildProfileSection(context, ref, vm),
                            const SizedBox(height: 24),
                            _buildAccountSection(context, ref, vm),
                            const SizedBox(height: 24),
                            _buildMentorSection(context, ref, vm),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            _buildLearningProgressSection(context, vm),
                            const SizedBox(height: 24),
                            _buildActivityTimelineSection(context, vm),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryAccent),
          ),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  Widget _buildAppbarActions(BuildContext context, WidgetRef ref, UserManagementViewModel vm) {
    final ctrl = ref.read(userManagementControllerProvider.notifier);
    
    return Row(
      children: [
        if (vm.isDeleted)
          TextButton.icon(
            onPressed: () async {
              await ctrl.restoreUser(uid);
            },
            icon: const Icon(Icons.restore, color: AppColors.primary),
            label: const Text('Restore User', style: TextStyle(color: AppColors.primary)),
          )
        else
          TextButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete User?'),
                  content: const Text('This will soft-delete the user. This action hides the user from normal views.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: AppColors.error))),
                  ],
                )
              );
              if (confirm == true) {
                await ctrl.softDeleteUser(uid, 'admin'); // or auth user id
                if (context.mounted) Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            label: const Text('Delete User', style: TextStyle(color: AppColors.error)),
          ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, UserManagementViewModel vm) {
    final user = vm.user;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
              child: user.photoUrl.isEmpty ? Text(user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?', style: const TextStyle(fontSize: 32, color: AppColors.primary)) : null,
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.displayName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Country: ${user.country ?? 'Unknown'}', style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Program Progress: ', style: TextStyle(fontWeight: FontWeight.w600)),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: vm.completionPercentage,
                            minHeight: 8,
                            backgroundColor: Colors.grey.withValues(alpha: 0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('${(vm.completionPercentage * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 48),
            Expanded(
              flex: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryStat('Current Week', vm.currentWeek.toString()),
                  _buildSummaryStat('Current Day', vm.currentDay.toString()),
                  _buildSummaryStat('Mentor', vm.mentorName),
                  _buildSummaryStat('Status', vm.isDeleted ? 'Deleted' : (vm.isActive ? 'Active' : 'Disabled'), isStatus: true, vm: vm),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value, {bool isStatus = false, UserManagementViewModel? vm}) {
    Color? valueColor;
    if (isStatus && vm != null) {
      if (vm.isDeleted) valueColor = Colors.grey;
      else if (vm.isActive) valueColor = AppColors.success;
      else if (vm.isDisabled) valueColor = AppColors.error;
      else valueColor = Colors.orange;
    }

    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: valueColor ?? Colors.black87),
        ),
      ],
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children, Widget? trailing}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (trailing != null) trailing,
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, WidgetRef ref, UserManagementViewModel vm) {
    final user = vm.user;
    return _buildSectionCard(
      title: 'Profile',
      trailing: TextButton.icon(
        icon: const Icon(Icons.edit, size: 16),
        label: const Text('Edit'),
        onPressed: () async {
          final result = await showDialog<Map<String, String>>(
            context: context,
            builder: (_) => EditUserDialog(user: user),
          );
          if (result != null) {
            await ref.read(userManagementControllerProvider.notifier).updateUserProfile(
              uid, 
              displayName: result['displayName'], 
              country: result['country'], 
              language: result['language']
            );
          }
        },
      ),
      children: [
        _buildInfoRow('Name', user.displayName),
        _buildInfoRow('Username', user.username != null ? '@${user.username}' : '-'),
        _buildInfoRow('Joined Date', user.createdAt != null ? DateFormat('dd MMM yyyy').format(user.createdAt!) : '-'),
        _buildInfoRow('Avatar URL', user.photoUrl.isNotEmpty ? 'Set' : 'Not Set'),
      ],
    );
  }

  Widget _buildAccountSection(BuildContext context, WidgetRef ref, UserManagementViewModel vm) {
    final user = vm.user;
    return _buildSectionCard(
      title: 'Account Information',
      children: [
        _buildInfoRow('User ID', user.uid),
        _buildInfoRow('Country', user.country ?? '-'),
        _buildInfoRow('Language', user.selectedLanguage ?? '-'),
        const SizedBox(height: 16),
        if (!vm.isDeleted)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Icon(vm.isActive ? Icons.block : Icons.check_circle),
              label: Text(vm.isActive ? 'Disable Account' : 'Enable Account'),
              style: ElevatedButton.styleFrom(
                backgroundColor: vm.isActive ? AppColors.error : AppColors.success,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final newStatus = vm.isActive ? AccountStatus.disabled : AccountStatus.active;
                await ref.read(userManagementControllerProvider.notifier).updateAccountStatus(uid, newStatus);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildMentorSection(BuildContext context, WidgetRef ref, UserManagementViewModel vm) {
    return _buildSectionCard(
      title: 'Mentor',
      children: [
        if (vm.user.mentorId == null) ...[
          const Text('No mentor assigned.', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.school),
              label: const Text('Assign Mentor'),
              onPressed: () => _openAssignMentor(context, ref),
            ),
          )
        ] else ...[
          _buildInfoRow('Mentor Name', vm.mentorName),
          _buildInfoRow('Assigned On', vm.user.mentorSince != null ? DateFormat('dd MMM yyyy').format(vm.user.mentorSince!) : '-'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _openAssignMentor(context, ref),
                  child: const Text('Reassign'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await ref.read(userManagementControllerProvider.notifier).removeMentor(uid);
                  },
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                  child: const Text('Remove'),
                ),
              ),
            ],
          ),
        ]
      ],
    );
  }

  Future<void> _openAssignMentor(BuildContext context, WidgetRef ref) async {
    final mentorId = await showDialog<String>(
      context: context,
      builder: (_) => const AssignMentorDialog(),
    );
    if (mentorId != null) {
      await ref.read(userManagementControllerProvider.notifier).assignMentor(uid, mentorId);
    }
  }

  Widget _buildLearningProgressSection(BuildContext context, UserManagementViewModel vm) {
    return _buildSectionCard(
      title: 'Learning Progress',
      children: [
        Row(
          children: [
            Expanded(child: _buildInfoRow('Current Week', 'Week ${vm.currentWeek}', isVertical: true)),
            Expanded(child: _buildInfoRow('Current Day', 'Day ${vm.currentDay}', isVertical: true)),
            Expanded(child: _buildInfoRow('Completion %', '${(vm.completionPercentage * 100).toInt()}%', isVertical: true)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildInfoRow('Completed Lessons', '${vm.completedLessons}', isVertical: true)),
            Expanded(child: _buildInfoRow('Remaining', '${60 - vm.completedLessons}', isVertical: true)), // Assuming 60 total
            Expanded(child: _buildInfoRow('Day Streak', '${vm.dayStreak}', isVertical: true)),
          ],
        ),
      ],
    );
  }

  Widget _buildActivityTimelineSection(BuildContext context, UserManagementViewModel vm) {
    final user = vm.user;
    
    // Build a chronological timeline
    final events = <_TimelineEvent>[];
    
    if (user.createdAt != null) {
      events.add(_TimelineEvent('Registered', user.createdAt!, Icons.person_add));
    }
    if (user.mentorSince != null) {
      events.add(_TimelineEvent('Assigned Mentor', user.mentorSince!, Icons.school));
    }
    if (user.lastLoginAt != null) {
      events.add(_TimelineEvent('Last Login', user.lastLoginAt!, Icons.login));
    }
    if (user.lastAppOpenAt != null && user.lastAppOpenAt != user.lastLoginAt) {
      events.add(_TimelineEvent('Opened App', user.lastAppOpenAt!, Icons.phone_android));
    }
    if (vm.lastCompletedAt != null) {
      events.add(_TimelineEvent('Completed Lesson', vm.lastCompletedAt!, Icons.task_alt));
    }

    events.sort((a, b) => b.date.compareTo(a.date)); // Descending order (newest first)

    return _buildSectionCard(
      title: 'Activity',
      children: [
        if (events.isEmpty)
          const Text('No recent activity.', style: TextStyle(color: AppColors.textSecondary))
        else
          ...events.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.primaryAccent.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: Icon(e.icon, size: 16, color: AppColors.primary),
                    ),
                    // Would put a connecting line here for a true timeline if we had a custom painter
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat('dd MMM yyyy • hh:mm a').format(e.date), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          )),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isVertical = false}) {
    if (isVertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _TimelineEvent {
  final String title;
  final DateTime date;
  final IconData icon;
  _TimelineEvent(this.title, this.date, this.icon);
}
