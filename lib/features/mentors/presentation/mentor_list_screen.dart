import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../application/mentor_controller.dart';
import 'widgets/approve_mentor_dialog.dart';
import '../../../core/utils/export_helper.dart';

class MentorListScreen extends ConsumerStatefulWidget {
  const MentorListScreen({super.key});

  @override
  ConsumerState<MentorListScreen> createState() => _MentorListScreenState();
}

class _MentorListScreenState extends ConsumerState<MentorListScreen> {
  String _searchQuery = '';
  String _statusFilter = 'All Statuses';

  @override
  Widget build(BuildContext context) {
    final mentorsAsync = ref.watch(mentorsStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          Expanded(
            child: mentorsAsync.when(
              data: (mentors) {
                final filteredMentors = mentors.where((m) {
                  final matchesSearch = m.displayName.toLowerCase().contains(_searchQuery.toLowerCase());
                  final matchesStatus = _statusFilter == 'All Statuses' ||
                      (_statusFilter == 'Active' && m.mentorStatus == 'active') ||
                      (_statusFilter == 'Suspended' && m.mentorStatus == 'suspended');
                  return matchesSearch && matchesStatus;
                }).toList();

                return Card(
                  margin: const EdgeInsets.all(24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  child: Column(
                    children: [
                      _buildFilters(context, filteredMentors),
                      const Divider(height: 1),
                      Expanded(
                        child: filteredMentors.isEmpty
                            ? const Center(child: Text('No mentors found.'))
                            : ListView.separated(
                                padding: const EdgeInsets.all(0),
                                itemCount: filteredMentors.length,
                                separatorBuilder: (context, index) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final mentor = filteredMentors[index];
                                  return _buildMentorRow(context, mentor);
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Mentor Management',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const ApproveMentorDialog(),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Approve Mentor'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context, List<dynamic> currentMentors) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search mentors...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _statusFilter,
                  isExpanded: true,
                  items: ['All Statuses', 'Active', 'Suspended'].map((e) {
                    return DropdownMenuItem(value: e, child: Text(e));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _statusFilter = val);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            onPressed: () {
              if (currentMentors.isEmpty) return;
              final rows = currentMentors.map((m) => [
                m.displayName,
                m.country ?? 'Unknown',
                m.mentorStatus ?? 'Unknown',
                m.mentorSince != null ? DateFormat('yyyy-MM-dd').format(m.mentorSince!) : 'Unknown',
              ]).toList();
              
              ExportHelper.exportToCsv('Mentors Export', ['Name', 'Country', 'Status', 'Mentor Since'], rows);
            },
            icon: const Icon(Icons.download),
            label: const Text('Export'),
          ),
        ],
      ),
    );
  }

  Widget _buildMentorRow(BuildContext context, dynamic mentor) {
    final bool isActive = mentor.mentorStatus == 'active';
    
    return InkWell(
      onTap: () {
        context.go('/mentors/${mentor.uid}');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.shade50,
              child: Text(
                mentor.displayName.isNotEmpty ? mentor.displayName[0].toUpperCase() : '?',
                style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mentor.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(mentor.country ?? 'N/A', style: TextStyle(color: Colors.grey.shade600)),
            ),
            Expanded(
              flex: 1,
              child: Text(
                mentor.mentorSince != null ? DateFormat('MMM d, yyyy').format(mentor.mentorSince!) : 'Unknown',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
