import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../application/mentor_controller.dart';
import '../../users/domain/app_user.dart';
import 'widgets/assign_users_dialog.dart';

class MentorDetailsScreen extends ConsumerWidget {
  final String uid;

  const MentorDetailsScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mentorsAsync = ref.watch(mentorsStreamProvider);
    final assignedUsersAsync = ref.watch(assignedUsersProvider(uid));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Mentor Details', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 1,
      ),
      body: mentorsAsync.when(
        data: (mentors) {
          final mentor = mentors.firstWhere((m) => m.uid == uid, orElse: () => AppUser(
            uid: '', email: '', displayName: 'Not Found', photoUrl: ''
          ));
          
          if (mentor.uid.isEmpty) return const Center(child: Text('Mentor not found.'));
          
          final isActive = mentor.mentorStatus == 'active';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileCard(context, ref, mentor, isActive),
                const SizedBox(height: 24),
                _buildAnalyticsCards(assignedUsersAsync),
                const SizedBox(height: 24),
                _buildAssignedUsersSection(context, ref, assignedUsersAsync, mentor),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, WidgetRef ref, AppUser mentor, bool isActive) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue.shade50,
              child: Text(
                mentor.displayName.isNotEmpty ? mentor.displayName[0].toUpperCase() : '?',
                style: TextStyle(fontSize: 32, color: Colors.blue.shade700, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(mentor.displayName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green.shade50 : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          isActive ? 'Active' : 'Suspended',
                          style: TextStyle(
                            color: isActive ? Colors.green.shade700 : Colors.orange.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Country: ${mentor.country ?? 'Unknown'}', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    'Mentor Since: ${mentor.mentorSince != null ? DateFormat('MMMM d, yyyy').format(mentor.mentorSince!) : 'Unknown'}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isActive)
                  OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(mentorControllerProvider.notifier).suspendMentor(mentor.uid);
                    },
                    icon: const Icon(Icons.pause),
                    label: const Text('Suspend Mentor'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(mentorControllerProvider.notifier).reactivateMentor(mentor.uid);
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Reactivate Mentor'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.green),
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await ref.read(mentorControllerProvider.notifier).removeMentorRole(mentor.uid);
                      if (context.mounted) context.pop();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(e.toString().replaceAll('Exception: ', '')),
                          backgroundColor: Colors.red,
                        ));
                      }
                    }
                  },
                  icon: const Icon(Icons.person_remove),
                  label: const Text('Remove Mentor Role'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCards(AsyncValue<List<AppUser>> assignedUsersAsync) {
    return assignedUsersAsync.when(
      data: (users) {
        final activeUsers = users.where((u) => u.isActive).length;
        
        return Row(
          children: [
            _buildStatCard('Assigned Users', users.length.toString(), Icons.people),
            const SizedBox(width: 16),
            _buildStatCard('Active Users', activeUsers.toString(), Icons.check_circle_outline),
            const SizedBox(width: 16),
            _buildStatCard('Completed Disciples', '0', Icons.school), // Placeholder for actual calculation
            const SizedBox(width: 16),
            _buildStatCard('Avg Completion', '0%', Icons.analytics), // Placeholder
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Text('Error loading stats: $e'),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.blue.shade600, size: 20),
                  const SizedBox(width: 8),
                  Text(title, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 12),
              Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssignedUsersSection(BuildContext context, WidgetRef ref, AsyncValue<List<AppUser>> assignedUsersAsync, AppUser mentor) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Assigned Disciples', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AssignUsersDialog(mentorId: mentor.uid),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Assign Users'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            assignedUsersAsync.when(
              data: (users) {
                if (users.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('No assigned disciples.')),
                  );
                }
                
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: users.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      leading: CircleAvatar(child: Text(user.displayName.isNotEmpty ? user.displayName[0] : '?')),
                      title: Text(user.displayName),
                      subtitle: Text(user.country ?? 'Unknown Country'),
                      trailing: IconButton(
                        icon: const Icon(Icons.person_remove, color: Colors.red),
                        onPressed: () async {
                          await ref.read(mentorControllerProvider.notifier).removeUserFromMentor(user.uid);
                        },
                        tooltip: 'Remove from Mentor',
                      ),
                    );
                  },
                );
              },
              loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
              error: (e, st) => Padding(padding: const EdgeInsets.all(24), child: Center(child: Text('Error: $e'))),
            ),
          ],
        ),
      ),
    );
  }
}
