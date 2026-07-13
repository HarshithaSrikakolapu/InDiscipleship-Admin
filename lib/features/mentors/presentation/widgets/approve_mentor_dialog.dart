import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mentor_providers.dart';
import '../../application/mentor_controller.dart';
import '../../../users/domain/app_user.dart';

class ApproveMentorDialog extends ConsumerStatefulWidget {
  const ApproveMentorDialog({super.key});

  @override
  ConsumerState<ApproveMentorDialog> createState() => _ApproveMentorDialogState();
}

class _ApproveMentorDialogState extends ConsumerState<ApproveMentorDialog> {
  String _searchQuery = '';
  List<AppUser> _eligibleUsers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEligibleUsers();
  }

  Future<void> _loadEligibleUsers() async {
    try {
      final repository = ref.read(mentorRepositoryProvider);
      final users = await repository.getEligibleUsersForPromotion();
      if (mounted) {
        setState(() {
          _eligibleUsers = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _eligibleUsers.where((user) {
      final matchesSearch = user.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 600,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Approve Mentor',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Select an eligible user (completed 12-week program) to approve as a mentor.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search eligible users...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text('Error loading users: $_error'))
                      : filteredUsers.isEmpty
                          ? const Center(child: Text('No eligible users found.'))
                          : ListView.builder(
                              itemCount: filteredUsers.length,
                              itemBuilder: (context, index) {
                                final user = filteredUsers[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      child: Text(user.displayName.isNotEmpty ? user.displayName[0] : '?'),
                                    ),
                                    title: Text(user.displayName),
                                    subtitle: Text(user.country ?? 'Unknown Country'),
                                    trailing: ElevatedButton(
                                      onPressed: () async {
                                        await ref.read(mentorControllerProvider.notifier).promoteToMentor(user.uid);
                                        if (context.mounted) Navigator.of(context).pop();
                                      },
                                      child: const Text('Approve'),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
