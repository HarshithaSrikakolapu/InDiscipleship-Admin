import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../application/lesson_providers.dart';
import '../data/models/lesson_model.dart';
import 'widgets/lesson_form_drawer.dart';

enum LessonFilterMode { all, published, draft }

class LessonListScreen extends ConsumerStatefulWidget {
  final LessonFilterMode filterMode;

  const LessonListScreen({super.key, this.filterMode = LessonFilterMode.all});

  @override
  ConsumerState<LessonListScreen> createState() => _LessonListScreenState();
}

class _LessonListScreenState extends ConsumerState<LessonListScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  LessonModel? _selectedLesson;
  
  String _searchQuery = '';
  int? _selectedWeek;
  bool? _isPublishedFilter;
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  
  Set<String> _selectedLessonIds = {};

  @override
  void initState() {
    super.initState();
    if (widget.filterMode == LessonFilterMode.published) {
      _isPublishedFilter = true;
    } else if (widget.filterMode == LessonFilterMode.draft) {
      _isPublishedFilter = false;
    }
  }

  void _openLessonForm([LessonModel? lesson]) {
    setState(() {
      _selectedLesson = lesson;
    });
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _closeDrawer() {
    if (_scaffoldKey.currentState?.isEndDrawerOpen ?? false) {
      Navigator.of(context).pop(); // Close drawer
    }
  }

  @override
  Widget build(BuildContext context) {
    final lessonsAsync = ref.watch(lessonsStreamProvider);
    final controller = ref.watch(lessonControllerProvider.notifier);
    final state = ref.watch(lessonControllerProvider);

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: Drawer(
        width: 600,
        backgroundColor: AppColors.background,
        child: _selectedLesson != null
            ? LessonFormDrawer(
                key: ValueKey(_selectedLesson!.lessonId),
                lesson: _selectedLesson,
                onClose: _closeDrawer,
              )
            : LessonFormDrawer(
                key: const ValueKey('create'),
                onClose: _closeDrawer,
              ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Manage Lessons',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 24),
                ),
                Row(
                  children: [
                    if (widget.filterMode == LessonFilterMode.all) ...[
                      PopupMenuButton<String>(
                        onSelected: (format) {
                          lessonsAsync.whenData((lessons) {
                            controller.exportLessons(lessons, format);
                          });
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'json', child: Text('Export JSON')),
                          const PopupMenuItem(value: 'csv', child: Text('Export CSV')),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.file_upload, color: AppColors.textPrimary, size: 20),
                              SizedBox(width: 8),
                              Text('Export', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    ElevatedButton.icon(
                      onPressed: () => _openLessonForm(),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Lesson'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            if (state.error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(state.error!, style: const TextStyle(color: AppColors.danger)),
              ),
              
            Expanded(
              child: Card(
                child: Column(
                  children: [
                    // Toolbar
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search Title, Topic, Verse...',
                                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              onChanged: (val) => setState(() {
                                _searchQuery = val.toLowerCase();
                                _currentPage = 0;
                              }),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<int?>(
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              value: _selectedWeek,
                              hint: const Text('All Weeks'),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('All Weeks')),
                                ...List.generate(12, (index) => DropdownMenuItem(value: index + 1, child: Text('Week ${index + 1}'))),
                              ],
                              onChanged: (val) => setState(() {
                                _selectedWeek = val;
                                _currentPage = 0;
                              }),
                            ),
                          ),
                          if (widget.filterMode == LessonFilterMode.all) ...[
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<bool?>(
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                value: _isPublishedFilter,
                                hint: const Text('Status'),
                                items: const [
                                  DropdownMenuItem(value: null, child: Text('All Statuses')),
                                  DropdownMenuItem(value: true, child: Text('Published')),
                                  DropdownMenuItem(value: false, child: Text('Unpublished')),
                                ],
                                onChanged: (val) => setState(() {
                                  _isPublishedFilter = val;
                                  _currentPage = 0;
                                }),
                              ),
                            ),
                          ],
                          if (_selectedLessonIds.isNotEmpty) ...[
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                for (final id in _selectedLessonIds) {
                                  controller.togglePublish(id, true);
                                }
                                setState(() => _selectedLessonIds.clear());
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                              icon: const Icon(Icons.check_circle, size: 18),
                              label: const Text('Publish'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                for (final id in _selectedLessonIds) {
                                  controller.togglePublish(id, false);
                                }
                                setState(() => _selectedLessonIds.clear());
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
                              icon: const Icon(Icons.cancel, size: 18),
                              label: const Text('Unpublish'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                // Real app might show confirmation dialog
                                for (final id in _selectedLessonIds) {
                                  controller.deleteLesson(id);
                                }
                                setState(() => _selectedLessonIds.clear());
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                              icon: const Icon(Icons.delete, size: 18),
                              label: const Text('Delete'),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    
                    // Header Row
                    Container(
                      color: AppColors.background,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const SizedBox(width: 32), // Checkbox space
                          _buildHeaderCell('W', flex: 1), // Week
                          _buildHeaderCell('D', flex: 1), // Day
                          _buildHeaderCell('Lesson Title', flex: 4),
                          _buildHeaderCell('Topic', flex: 3),
                          _buildHeaderCell('Bible Verse', flex: 3),
                          _buildHeaderCell('Status', flex: 2),
                          const SizedBox(width: 48), // Actions space
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),

                    // Scrollable Rows
                    Expanded(
                      child: lessonsAsync.when(
                        data: (lessons) {
                          final filteredLessons = lessons.where((lesson) {
                            final matchesSearch = lesson.lessonTitle.toLowerCase().contains(_searchQuery) ||
                                lesson.topic.toLowerCase().contains(_searchQuery) ||
                                lesson.bibleVerse.toLowerCase().contains(_searchQuery);
                            final matchesWeek = _selectedWeek == null || lesson.week == _selectedWeek;
                            final matchesStatus = _isPublishedFilter == null || lesson.isPublished == _isPublishedFilter;
                            return matchesSearch && matchesWeek && matchesStatus;
                          }).toList();

                          if (filteredLessons.isEmpty) {
                            return const Center(child: Text('No lessons found.'));
                          }

                          final startIndex = _currentPage * _itemsPerPage;
                          final endIndex = (startIndex + _itemsPerPage < filteredLessons.length)
                              ? startIndex + _itemsPerPage
                              : filteredLessons.length;
                          final pageLessons = filteredLessons.sublist(startIndex, endIndex);

                          return ListView.separated(
                            itemCount: pageLessons.length,
                            separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                            itemBuilder: (context, index) {
                              final lesson = pageLessons[index];
                              return InkWell(
                                onTap: () => _openLessonForm(lesson),
                                hoverColor: AppColors.background,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 32,
                                        child: Checkbox(
                                          value: _selectedLessonIds.contains(lesson.lessonId),
                                          onChanged: (val) {
                                            setState(() {
                                              if (val == true) {
                                                _selectedLessonIds.add(lesson.lessonId);
                                              } else {
                                                _selectedLessonIds.remove(lesson.lessonId);
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(4)),
                                          child: Text('W${lesson.week}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 1,
                                        child: Text('D${lesson.day}', style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                                      ),
                                      Expanded(flex: 4, child: Text(lesson.lessonTitle, style: const TextStyle(fontWeight: FontWeight.w600))),
                                      Expanded(flex: 3, child: Text(lesson.topic, style: const TextStyle(color: AppColors.textSecondary))),
                                      Expanded(flex: 3, child: Text(lesson.bibleVerse, style: const TextStyle(color: AppColors.textSecondary))),
                                      Expanded(
                                        flex: 2,
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Switch(
                                            value: lesson.isPublished,
                                            onChanged: (val) {
                                              controller.togglePublish(lesson.lessonId, val);
                                            },
                                            activeColor: AppColors.success,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 20, color: AppColors.textSecondary),
                                        onPressed: () => _openLessonForm(lesson),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        loading: () => _buildSkeletonRows(),
                        error: (error, stackTrace) => Center(child: Text('Error: $error', style: const TextStyle(color: AppColors.danger))),
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),

                    // Pagination
                    lessonsAsync.maybeWhen(
                      data: (lessons) {
                        final filteredLessons = lessons.where((lesson) {
                          final matchesSearch = lesson.lessonTitle.toLowerCase().contains(_searchQuery) ||
                              lesson.topic.toLowerCase().contains(_searchQuery) ||
                              lesson.bibleVerse.toLowerCase().contains(_searchQuery);
                          final matchesWeek = _selectedWeek == null || lesson.week == _selectedWeek;
                          final matchesStatus = _isPublishedFilter == null || lesson.isPublished == _isPublishedFilter;
                          return matchesSearch && matchesWeek && matchesStatus;
                        }).toList();
                        final totalPages = (filteredLessons.length / _itemsPerPage).ceil();

                        return Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('Page ${_currentPage + 1} of ${totalPages == 0 ? 1 : totalPages}', style: const TextStyle(color: AppColors.textSecondary)),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                              ),
                            ],
                          ),
                        );
                      },
                      orElse: () => const SizedBox(height: 48), // Placeholder
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

  Widget _buildSkeletonRows() {
    return ListView.separated(
      itemCount: 5,
      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const SizedBox(width: 32),
              Expanded(flex: 1, child: Container(height: 24, color: Colors.grey.withOpacity(0.2), margin: const EdgeInsets.only(right: 8))),
              Expanded(flex: 1, child: Container(height: 16, color: Colors.grey.withOpacity(0.2), margin: const EdgeInsets.only(right: 16))),
              Expanded(flex: 4, child: Container(height: 16, color: Colors.grey.withOpacity(0.2), margin: const EdgeInsets.only(right: 16))),
              Expanded(flex: 3, child: Container(height: 16, color: Colors.grey.withOpacity(0.2), margin: const EdgeInsets.only(right: 16))),
              Expanded(flex: 3, child: Container(height: 16, color: Colors.grey.withOpacity(0.2), margin: const EdgeInsets.only(right: 16))),
              Expanded(flex: 2, child: Container(width: 40, height: 24, color: Colors.grey.withOpacity(0.2), margin: const EdgeInsets.only(right: 16))),
              const SizedBox(width: 40),
            ],
          ),
        );
      },
    );
  }
}
