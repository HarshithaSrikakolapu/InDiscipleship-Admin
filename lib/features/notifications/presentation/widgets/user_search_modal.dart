import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../users/data/user_management_repository.dart';
final _usersSearchStreamProvider = StreamProvider.autoDispose((ref) {
  return ref.watch(userManagementRepositoryProvider).getUsersStream();
});

class UserSearchModal extends ConsumerStatefulWidget {
  final List<String> initiallySelectedUids;

  const UserSearchModal({
    super.key,
    this.initiallySelectedUids = const [],
  });

  @override
  ConsumerState<UserSearchModal> createState() => _UserSearchModalState();
}

class _UserSearchModalState extends ConsumerState<UserSearchModal> {
  final _searchController = TextEditingController();
  final Set<String> _selectedUids = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedUids.addAll(widget.initiallySelectedUids);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We reuse the existing userManagementRepositoryProvider which fetches all users via stream.
    // For a truly scalable system, this should use a paginated query, but since the existing system 
    // uses a single stream for all users in UserManagementRepository, we filter on the client for now.
    // In a production app with >100k users, this should be a paginated Algolia/Typesense search or 
    // a paginated Firestore query with startAfter.
    final usersAsync = ref.watch(_usersSearchStreamProvider);

    return AlertDialog(
      title: const Text('Select Users'),
      content: SizedBox(
        width: 600,
        height: 600,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by Name, Username, or Country...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: usersAsync.when(
                data: (viewModels) {
                  final filteredUsers = viewModels.map((vm) => vm.user).where((user) {
                    final q = _searchQuery.toLowerCase();
                    return user.displayName.toLowerCase().contains(q) ||
                        (user.username?.toLowerCase().contains(q) ?? false) ||
                        (user.country?.toLowerCase().contains(q) ?? false);
                  }).toList();

                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${filteredUsers.length} users found'),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                final allFilteredIds = filteredUsers.map((u) => u.uid).toList();
                                final allSelected = allFilteredIds.every((id) => _selectedUids.contains(id));
                                if (allSelected) {
                                  _selectedUids.removeAll(allFilteredIds);
                                } else {
                                  _selectedUids.addAll(allFilteredIds);
                                }
                              });
                            },
                            child: const Text('Select / Deselect All (Filtered)'),
                          )
                        ],
                      ),
                      const Divider(),
                      Expanded(
                        child: ListView.builder(
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            final isSelected = _selectedUids.contains(user.uid);
                            return CheckboxListTile(
                              value: isSelected,
                              title: Text(user.displayName),
                              subtitle: Text('${user.email} • ${user.country ?? "Unknown"}'),
                              secondary: CircleAvatar(
                                backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
                                child: user.photoUrl.isEmpty ? Text(user.displayName[0]) : null,
                              ),
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedUids.add(user.uid);
                                  } else {
                                    _selectedUids.remove(user.uid);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error loading users: $e')),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, _selectedUids.toList());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: Text('Confirm Selection (${_selectedUids.length})'),
        ),
      ],
    );
  }
}
