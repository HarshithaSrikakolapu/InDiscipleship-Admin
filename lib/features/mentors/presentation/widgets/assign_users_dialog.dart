import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mentor_providers.dart';
import '../../application/mentor_controller.dart';
import '../../../users/domain/app_user.dart';

class AssignUsersDialog extends ConsumerStatefulWidget {
  final String mentorId;

  const AssignUsersDialog({super.key, required this.mentorId});

  @override
  ConsumerState<AssignUsersDialog> createState() => _AssignUsersDialogState();
}

class _AssignUsersDialogState extends ConsumerState<AssignUsersDialog> {
  String _searchQuery = '';
  List<AppUser> _availableUsers = [];
  final Set<String> _selectedUserIds = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAvailableUsers();
  }

  Future<void> _loadAvailableUsers() async {
    try {
      final repository = ref.read(mentorRepositoryProvider);
      final stream = repository.getAvailableDisciplesStream();
      final users = await stream.first;
      
      if (mounted) {
        setState(() {
          _availableUsers = users;
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
    final filteredUsers = _availableUsers.where((user) {
      final matchesSearch = user.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 600,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Assign Disciples',
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
              'Select users who do not have a mentor assigned.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search users...',
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
                          ? const Center(child: Text('No available users found.'))
                          : ListView.builder(
                              itemCount: filteredUsers.length,
                              itemBuilder: (context, index) {
                                final user = filteredUsers[index];
                                final isSelected = _selectedUserIds.contains(user.uid);
                                
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: CheckboxListTile(
                                    value: isSelected,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        if (value == true) {
                                          _selectedUserIds.add(user.uid);
                                        } else {
                                          _selectedUserIds.remove(user.uid);
                                        }
                                      });
                                    },
                                    secondary: CircleAvatar(
                                      child: Text(user.displayName.isNotEmpty ? user.displayName[0] : '?'),
                                    ),
                                    title: Text(user.displayName),
                                    subtitle: Text(user.country ?? 'Unknown Country'),
                                  ),
                                );
                              },
                            ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _selectedUserIds.isEmpty
                      ? null
                      : () async {
                          await ref.read(mentorControllerProvider.notifier).assignUsers(
                                widget.mentorId,
                                _selectedUserIds.toList(),
                              );
                          if (context.mounted) Navigator.of(context).pop();
                        },
                  child: Text('Assign ${_selectedUserIds.length} Users'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
