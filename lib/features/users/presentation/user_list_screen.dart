import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/export_helper.dart';
import '../domain/app_user.dart';
import '../domain/user_management_view_model.dart';
import '../data/user_management_repository.dart';
import '../application/user_management_controller.dart';
import 'widgets/assign_mentor_dialog.dart';

class UserListScreen extends ConsumerStatefulWidget {
  const UserListScreen({super.key});

  @override
  ConsumerState<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends ConsumerState<UserListScreen> {
  String _searchQuery = '';
  int _currentPage = 0;
  final int _itemsPerPage = 10;

  // Selection
  final Set<String> _selectedUids = {};
  bool _selectAll = false;

  // Filters
  String _statusFilter =
      'All Users'; // All Users, Active Users, Disabled Users, Deleted Users
  String _mentorFilter = 'All'; // All, Assigned, Unassigned
  final String _countryFilter = 'All';
  final String _languageFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref
        .watch(userManagementRepositoryProvider)
        .getUsersStream();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Management',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Bulk Actions Banner
            if (_selectedUids.isNotEmpty) _buildBulkActionsBanner(),

            Expanded(
              child: Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Toolbar
                    _buildToolbar(),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),

                    // Header Row
                    _buildHeaderRow(),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),

                    // Scrollable Rows
                    Expanded(
                      child: StreamBuilder<List<UserManagementViewModel>>(
                        stream: usersAsync,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              !snapshot.hasData) {
                            return _buildSkeletonRows();
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Error: ${snapshot.error}',
                                style: const TextStyle(color: AppColors.error),
                              ),
                            );
                          }

                          final users = snapshot.data ?? [];
                          final filteredUsers = _applyFilters(users);

                          if (filteredUsers.isEmpty) {
                            return const Center(
                              child: Text(
                                'No users found.',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            );
                          }

                          // Pagination
                          final startIndex = _currentPage * _itemsPerPage;
                          final endIndex =
                              (startIndex + _itemsPerPage <
                                  filteredUsers.length)
                              ? startIndex + _itemsPerPage
                              : filteredUsers.length;

                          if (startIndex >= filteredUsers.length &&
                              filteredUsers.isNotEmpty) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              setState(() => _currentPage = 0);
                            });
                            return const SizedBox();
                          }

                          final pageUsers = filteredUsers.sublist(
                            startIndex,
                            endIndex,
                          );

                          return ListView.separated(
                            itemCount: pageUsers.length,
                            separatorBuilder: (context, index) => const Divider(
                              height: 1,
                              color: Color(0xFFE2E8F0),
                            ),
                            itemBuilder: (context, index) {
                              final vm = pageUsers[index];
                              return _buildUserRow(vm);
                            },
                          );
                        },
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),

                    // Pagination Footer
                    StreamBuilder<List<UserManagementViewModel>>(
                      stream: usersAsync,
                      builder: (context, snapshot) {
                        final users = snapshot.data ?? [];
                        final filteredUsers = _applyFilters(users);
                        final totalPages =
                            (filteredUsers.length / _itemsPerPage).ceil();

                        return Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Showing ${filteredUsers.length} users',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    'Page ${_currentPage + 1} of ${totalPages == 0 ? 1 : totalPages}',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_left),
                                    onPressed: _currentPage > 0
                                        ? () => setState(() => _currentPage--)
                                        : null,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right),
                                    onPressed: _currentPage < totalPages - 1
                                        ? () => setState(() => _currentPage++)
                                        : null,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<UserManagementViewModel> _applyFilters(
    List<UserManagementViewModel> users,
  ) {
    return users.where((u) {
      // Search
      final searchMatch =
          _searchQuery.isEmpty ||
          u.user.displayName.toLowerCase().contains(_searchQuery) ||
          u.user.email.toLowerCase().contains(_searchQuery) ||
          (u.user.username?.toLowerCase().contains(_searchQuery) ?? false) ||
          (u.user.country?.toLowerCase().contains(_searchQuery) ?? false);
      if (!searchMatch) return false;

      // Status
      if (_statusFilter == 'Active Users' &&
          u.user.accountStatus != AccountStatus.active) {
        return false;
      }
      if (_statusFilter == 'Disabled Users' &&
          u.user.accountStatus != AccountStatus.disabled) {
        return false;
      }
      if (_statusFilter == 'Deleted Users' && !u.isDeleted) return false;
      if (_statusFilter != 'Deleted Users' && u.isDeleted) {
        return false; // Hide deleted by default unless filter is selected
      }

      // Mentor
      if (_mentorFilter == 'Assigned' && u.user.mentorId == null) return false;
      if (_mentorFilter == 'Unassigned' && u.user.mentorId != null) {
        return false;
      }

      // Additional simple filters (could be expanded)
      if (_countryFilter != 'All' && u.user.country != _countryFilter) {
        return false;
      }
      if (_languageFilter != 'All' &&
          u.user.selectedLanguage != _languageFilter) {
        return false;
      }

      return true;
    }).toList();
  }

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by Name, Username, Country...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (val) => setState(() {
                _searchQuery = val.toLowerCase();
                _currentPage = 0;
              }),
            ),
          ),
          const SizedBox(width: 16),
          // Status Filter
          DropdownButton<String>(
            value: _statusFilter,
            items: [
              'All Users',
              'Active Users',
              'Disabled Users',
              'Deleted Users',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() {
              _statusFilter = v!;
              _currentPage = 0;
              _selectedUids.clear();
              _selectAll = false;
            }),
            underline: const SizedBox(),
          ),
          const SizedBox(width: 16),
          // Mentor Filter
          DropdownButton<String>(
            value: _mentorFilter,
            items: ['All', 'Assigned', 'Unassigned']
                .map(
                  (e) => DropdownMenuItem(value: e, child: Text('Mentor: $e')),
                )
                .toList(),
            onChanged: (v) => setState(() {
              _mentorFilter = v!;
              _currentPage = 0;
            }),
            underline: const SizedBox(),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _exportData(false),
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Export XLSX'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => _exportData(true),
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Export CSV'),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkActionsBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primaryAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Text(
            '${_selectedUids.length} users selected',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () async {
              final ctrl = ref.read(userManagementControllerProvider.notifier);
              await ctrl.bulkUpdateAccountStatus(
                _selectedUids.toList(),
                AccountStatus.disabled,
              );
              setState(() => _selectedUids.clear());
            },
            icon: const Icon(Icons.block, size: 18),
            label: const Text('Disable'),
          ),
          TextButton.icon(
            onPressed: () async {
              final ctrl = ref.read(userManagementControllerProvider.notifier);
              await ctrl.bulkUpdateAccountStatus(
                _selectedUids.toList(),
                AccountStatus.active,
              );
              setState(() => _selectedUids.clear());
            },
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('Enable'),
          ),
          TextButton.icon(
            onPressed: () async {
              final mentorId = await showDialog<String>(
                context: context,
                builder: (_) => const AssignMentorDialog(),
              );
              if (mentorId != null) {
                final ctrl = ref.read(
                  userManagementControllerProvider.notifier,
                );
                await ctrl.bulkAssignMentor(_selectedUids.toList(), mentorId);
                setState(() => _selectedUids.clear());
              }
            },
            icon: const Icon(Icons.school, size: 18),
            label: const Text('Assign Mentor'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Checkbox(
            value: _selectAll,
            onChanged: (v) {
              setState(() {
                _selectAll = v ?? false;
                // We'd select all currently visible if implemented perfectly, but for now we can just select all on current page
                // Due to streamBuilder async nature, implementing true select all requires refactoring state.
              });
            },
          ),
          const SizedBox(width: 48), // Avatar space
          _buildHeaderCell('User', flex: 3),
          _buildHeaderCell('Progress', flex: 2),
          _buildHeaderCell('Mentor', flex: 2),
          _buildHeaderCell('Status', flex: 1),
          _buildHeaderCell('Joined', flex: 1),
          const SizedBox(width: 48), // Actions space
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildUserRow(UserManagementViewModel vm) {
    final user = vm.user;
    final isSelected = _selectedUids.contains(user.uid);

    return InkWell(
      onTap: () => context.push('/users/${user.uid}'),
      hoverColor: AppColors.background,
      child: Container(
        color: isSelected
            ? AppColors.primaryAccent.withValues(alpha: 0.05)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    _selectedUids.add(user.uid);
                  } else {
                    _selectedUids.remove(user.uid);
                  }
                });
              },
            ),
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: user.photoUrl.isNotEmpty
                  ? NetworkImage(user.photoUrl)
                  : null,
              child: user.photoUrl.isEmpty
                  ? Text(
                      user.displayName.isNotEmpty
                          ? user.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (user.username != null)
                    Text(
                      '@${user.username}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  Text(
                    '${user.country ?? '-'} • ${user.selectedLanguage ?? '-'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'W${vm.currentWeek} D${vm.currentDay} • ${(vm.completionPercentage * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${vm.completedLessons} lessons • ${vm.dayStreak}d streak',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 14,
                    color: user.mentorId != null
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    vm.mentorName,
                    style: TextStyle(
                      color: user.mentorId != null
                          ? Colors.black87
                          : AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildStatusBadge(vm),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                user.createdAt != null
                    ? DateFormat('MMM dd, yyyy').format(user.createdAt!)
                    : '-',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.more_vert,
                size: 20,
                color: AppColors.textSecondary,
              ),
              onPressed: () {
                // Future: context menu for individual row actions.
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(UserManagementViewModel vm) {
    Color color;
    String text;

    if (vm.isDeleted) {
      color = Colors.grey;
      text = 'Deleted';
    } else if (vm.isActive) {
      color = AppColors.success;
      text = 'Active';
    } else if (vm.isDisabled) {
      color = AppColors.error;
      text = 'Disabled';
    } else {
      color = Colors.orange;
      text = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSkeletonRows() {
    return ListView.separated(
      itemCount: 5,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                color: Colors.grey.withValues(alpha: 0.2),
              ),
              const SizedBox(width: 12),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Container(
                  height: 16,
                  color: Colors.grey.withValues(alpha: 0.2),
                  margin: const EdgeInsets.only(right: 16),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  height: 16,
                  color: Colors.grey.withValues(alpha: 0.2),
                  margin: const EdgeInsets.only(right: 16),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  height: 16,
                  color: Colors.grey.withValues(alpha: 0.2),
                  margin: const EdgeInsets.only(right: 16),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  height: 16,
                  color: Colors.grey.withValues(alpha: 0.2),
                  margin: const EdgeInsets.only(right: 16),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  height: 16,
                  color: Colors.grey.withValues(alpha: 0.2),
                  margin: const EdgeInsets.only(right: 16),
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportData(bool asCsv) async {
    // In a real scenario we might await a future or read current state.
    // Assuming we want to export the currently fetched/filtered users.
    // For simplicity, let's just listen to the stream one time.
    final repo = ref.read(userManagementRepositoryProvider);
    final allUsers = await repo.getUsersStream().first;

    List<UserManagementViewModel> exportUsers = _applyFilters(allUsers);
    if (_selectedUids.isNotEmpty) {
      exportUsers = exportUsers
          .where((u) => _selectedUids.contains(u.user.uid))
          .toList();
    }

    final headers = [
      'ID',
      'Name',
      'Username',
      'Email',
      'Country',
      'Language',
      'Status',
      'Joined Date',
      'Current Week',
      'Current Day',
      'Completion %',
      'Completed Lessons',
      'Day Streak',
      'Mentor Name',
    ];

    final rows = exportUsers
        .map(
          (vm) => [
            vm.user.uid,
            vm.user.displayName,
            vm.user.username ?? '',
            vm.user.email,
            vm.user.country ?? '',
            vm.user.selectedLanguage ?? '',
            vm.user.accountStatus.name,
            vm.user.createdAt != null
                ? DateFormat('yyyy-MM-dd').format(vm.user.createdAt!)
                : '',
            vm.currentWeek,
            vm.currentDay,
            vm.completionPercentage,
            vm.completedLessons,
            vm.dayStreak,
            vm.mentorName,
          ],
        )
        .toList();

    final filters = {
      'Status': _statusFilter,
      'Mentor': _mentorFilter,
      'Search': _searchQuery.isEmpty ? 'None' : _searchQuery,
      'Selection': _selectedUids.isNotEmpty
          ? 'Selected rows only'
          : 'All visible',
    };

    if (asCsv) {
      ExportHelper.exportToCsv(
        'User Management Report',
        headers,
        rows,
        filters: filters,
      );
    } else {
      ExportHelper.exportToExcel(
        'User Management Report',
        headers,
        rows,
        filters: filters,
      );
    }
  }
}
