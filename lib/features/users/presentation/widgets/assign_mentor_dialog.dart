import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/app_user.dart';
import '../../../mentors/application/mentor_controller.dart';

class AssignMentorDialog extends ConsumerStatefulWidget {
  const AssignMentorDialog({super.key});

  @override
  ConsumerState<AssignMentorDialog> createState() => _AssignMentorDialogState();
}

class _AssignMentorDialogState extends ConsumerState<AssignMentorDialog> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final mentorsAsync = ref.watch(mentorsStreamProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Assign Mentor',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search mentors...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: mentorsAsync.when(
                data: (mentors) {
                  final activeMentors = mentors.where((m) => m.accountStatus == AccountStatus.active).toList();
                  final filtered = activeMentors.where((m) =>
                      m.displayName.toLowerCase().contains(_searchQuery) ||
                      m.email.toLowerCase().contains(_searchQuery)).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('No active mentors found.'));
                  }

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final mentor = filtered[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: mentor.photoUrl.isNotEmpty ? NetworkImage(mentor.photoUrl) : null,
                          child: mentor.photoUrl.isEmpty ? Text(mentor.displayName.isNotEmpty ? mentor.displayName[0].toUpperCase() : '?') : null,
                        ),
                        title: Text(mentor.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(mentor.email),
                        trailing: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(mentor.uid),
                          child: const Text('Assign'),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
