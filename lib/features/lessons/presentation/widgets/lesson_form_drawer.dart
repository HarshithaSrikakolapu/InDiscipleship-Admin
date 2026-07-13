import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../../../../core/theme/app_colors.dart';
import '../../application/lesson_providers.dart';
import '../../data/models/lesson_model.dart';

class LessonFormDrawer extends ConsumerStatefulWidget {
  final LessonModel? lesson;
  final VoidCallback onClose;

  const LessonFormDrawer({super.key, this.lesson, required this.onClose});

  @override
  ConsumerState<LessonFormDrawer> createState() => _LessonFormDrawerState();
}

class _LessonFormDrawerState extends ConsumerState<LessonFormDrawer> {
  final _formKey = GlobalKey<FormState>();

  late int _week;
  late int _day;
  late TextEditingController _titleController;
  late TextEditingController _topicController;
  late TextEditingController _verseController;
  late TextEditingController _minutesController;

  late quill.QuillController _connectController;
  late quill.QuillController _discoverController;
  late quill.QuillController _challengeController;
  late quill.QuillController _stillThirstyController;

  @override
  void initState() {
    super.initState();
    final lesson = widget.lesson;
    _week = lesson?.week ?? 1;
    _day = lesson?.day ?? 1;
    _titleController = TextEditingController(text: lesson?.lessonTitle ?? '');
    _topicController = TextEditingController(text: lesson?.topic ?? '');
    _verseController = TextEditingController(text: lesson?.bibleVerse ?? '');
    _minutesController = TextEditingController(text: (lesson?.estimatedMinutes ?? 12).toString());

    _connectController = _initQuillController(lesson?.connect);
    _discoverController = _initQuillController(lesson?.discover);
    _challengeController = _initQuillController(lesson?.challenge);
    _stillThirstyController = _initQuillController(lesson?.stillThirsty);
  }

  quill.QuillController _initQuillController(List<String>? data) {
    if (data == null || data.isEmpty) {
      return quill.QuillController.basic();
    }
    
    // Check if it's stored as Quill JSON Delta in the first element
    if (data.length == 1 && data.first.startsWith('[') && data.first.endsWith(']')) {
      try {
        final doc = quill.Document.fromJson(jsonDecode(data.first));
        return quill.QuillController(document: doc, selection: const TextSelection.collapsed(offset: 0));
      } catch (e) {
        // Fallback to plain text
      }
    }
    
    // Fallback to plain text
    final doc = quill.Document()..insert(0, data.join('\n'));
    return quill.QuillController(document: doc, selection: const TextSelection.collapsed(offset: 0));
  }

  List<String> _getQuillData(quill.QuillController controller) {
    final deltaJson = controller.document.toDelta().toJson();
    return [jsonEncode(deltaJson)];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _topicController.dispose();
    _verseController.dispose();
    _minutesController.dispose();
    _connectController.dispose();
    _discoverController.dispose();
    _challengeController.dispose();
    _stillThirstyController.dispose();
    super.dispose();
  }

  void _saveLesson() async {
    if (_formKey.currentState!.validate()) {
      final newLesson = LessonModel(
        lessonId: widget.lesson?.lessonId ?? '',
        week: _week,
        day: _day,
        lessonTitle: _titleController.text.trim(),
        topic: _topicController.text.trim(),
        bibleVerse: _verseController.text.trim(),
        estimatedMinutes: int.tryParse(_minutesController.text) ?? 12,
        connect: _getQuillData(_connectController),
        discover: _getQuillData(_discoverController),
        challenge: _getQuillData(_challengeController),
        stillThirsty: _getQuillData(_stillThirstyController),
        isPublished: widget.lesson?.isPublished ?? false,
      );

      final controller = ref.read(lessonControllerProvider.notifier);
      
      if (widget.lesson == null) {
        await controller.createLesson(newLesson);
      } else {
        await controller.updateLesson(newLesson);
      }

      final state = ref.read(lessonControllerProvider);
      if (state.error == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lesson saved successfully!')));
        widget.onClose();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error ?? 'Error saving lesson'), backgroundColor: AppColors.danger));
      }
    }
  }

  void _deleteLesson() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Lesson'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              final controller = ref.read(lessonControllerProvider.notifier);
              await controller.deleteLesson(widget.lesson!.lessonId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lesson deleted')));
                widget.onClose();
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildRichTextSection(String title, quill.QuillController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: Column(
            children: [
              quill.QuillSimpleToolbar(
                controller: controller,
                config: const quill.QuillSimpleToolbarConfig(
                  showAlignmentButtons: true,
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              Container(
                height: 200,
                padding: const EdgeInsets.all(16),
                child: quill.QuillEditor.basic(
                  controller: controller,
                  config: const quill.QuillEditorConfig(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.lesson != null;
    final state = ref.watch(lessonControllerProvider);

    return Container(
      width: 600, // Drawer width
      color: AppColors.background,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Edit Lesson' : 'Create Lesson',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: widget.onClose),
              ],
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        const Text('Lesson Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                decoration: const InputDecoration(labelText: 'Week', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                                value: _week,
                                items: List.generate(12, (index) => DropdownMenuItem(value: index + 1, child: Text('Week ${index + 1}'))),
                                onChanged: isEditing ? null : (value) => setState(() => _week = value!),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                decoration: const InputDecoration(labelText: 'Day', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                                value: _day,
                                items: List.generate(5, (index) => DropdownMenuItem(value: index + 1, child: Text('Day ${index + 1}'))),
                                onChanged: isEditing ? null : (value) => setState(() => _day = value!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(labelText: 'Lesson Title', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                          validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _topicController,
                          decoration: const InputDecoration(labelText: 'Topic (Optional)', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _verseController,
                          decoration: const InputDecoration(labelText: 'Bible Verse', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                          validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _minutesController,
                          decoration: const InputDecoration(labelText: 'Estimated Minutes', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 32),
                        const Divider(color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 32),
                        
                        _buildRichTextSection('Connect', _connectController),
                        _buildRichTextSection('Discover', _discoverController),
                        _buildRichTextSection('Challenge', _challengeController),
                        _buildRichTextSection('Still Thirsty', _stillThirstyController),
                      ],
                    ),
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isEditing)
                  TextButton.icon(
                    onPressed: _deleteLesson,
                    icon: const Icon(Icons.delete, color: AppColors.danger),
                    label: const Text('Delete', style: TextStyle(color: AppColors.danger)),
                  )
                else
                  const SizedBox(),
                Row(
                  children: [
                    TextButton(onPressed: widget.onClose, child: const Text('Cancel')),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _saveLesson,
                      child: const Text('Save Lesson'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
