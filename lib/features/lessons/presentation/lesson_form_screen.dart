import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../application/lesson_providers.dart';
import '../data/models/lesson_model.dart';

class LessonFormScreen extends ConsumerStatefulWidget {
  final LessonModel? lesson;

  const LessonFormScreen({super.key, this.lesson});

  @override
  ConsumerState<LessonFormScreen> createState() => _LessonFormScreenState();
}

class _LessonFormScreenState extends ConsumerState<LessonFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late int _week;
  late int _day;
  late TextEditingController _titleController;
  late TextEditingController _topicController;
  late TextEditingController _verseController;
  late TextEditingController _minutesController;

  late List<TextEditingController> _connectControllers;
  late List<TextEditingController> _discoverControllers;
  late List<TextEditingController> _challengeControllers;
  late List<TextEditingController> _stillThirstyControllers;

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

    _connectControllers = (lesson?.connect.isNotEmpty ?? false)
        ? lesson!.connect.map((e) => TextEditingController(text: e)).toList()
        : [TextEditingController()];
    _discoverControllers = (lesson?.discover.isNotEmpty ?? false)
        ? lesson!.discover.map((e) => TextEditingController(text: e)).toList()
        : [TextEditingController()];
    _challengeControllers = (lesson?.challenge.isNotEmpty ?? false)
        ? lesson!.challenge.map((e) => TextEditingController(text: e)).toList()
        : [TextEditingController()];
    _stillThirstyControllers = (lesson?.stillThirsty.isNotEmpty ?? false)
        ? lesson!.stillThirsty.map((e) => TextEditingController(text: e)).toList()
        : [TextEditingController()];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _topicController.dispose();
    _verseController.dispose();
    _minutesController.dispose();
    for (var c in _connectControllers) { c.dispose(); }
    for (var c in _discoverControllers) { c.dispose(); }
    for (var c in _challengeControllers) { c.dispose(); }
    for (var c in _stillThirstyControllers) { c.dispose(); }
    super.dispose();
  }

  void _addListItem(List<TextEditingController> controllers) {
    setState(() {
      controllers.add(TextEditingController());
    });
  }

  void _removeListItem(List<TextEditingController> controllers, int index) {
    setState(() {
      if (controllers.length > 1) {
        controllers[index].dispose();
        controllers.removeAt(index);
      }
    });
  }

  Widget _buildDynamicList(String title, List<TextEditingController> controllers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addListItem(controllers),
            ),
          ],
        ),
        ...controllers.asMap().entries.map((entry) {
          int index = entry.key;
          TextEditingController controller = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Item ${index + 1}',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                if (controllers.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeListItem(controllers, index),
                  ),
              ],
            ),
          );
        }),
        const Divider(),
      ],
    );
  }

  void _saveLesson() async {
    if (_formKey.currentState!.validate()) {
      final newLesson = LessonModel(
        lessonId: widget.lesson?.lessonId ?? '', // Will be overridden in repo if new
        week: _week,
        day: _day,
        lessonTitle: _titleController.text.trim(),
        topic: _topicController.text.trim(),
        bibleVerse: _verseController.text.trim(),
        estimatedMinutes: int.tryParse(_minutesController.text) ?? 12,
        connect: _connectControllers.map((c) => c.text.trim()).toList(),
        discover: _discoverControllers.map((c) => c.text.trim()).toList(),
        challenge: _challengeControllers.map((c) => c.text.trim()).toList(),
        stillThirsty: _stillThirstyControllers.map((c) => c.text.trim()).toList(),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lesson saved successfully!')),
        );
        context.pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.error ?? 'Error saving lesson'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _deleteLesson() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lesson?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final controller = ref.read(lessonControllerProvider.notifier);
      await controller.deleteLesson(widget.lesson!.lessonId);
      final state = ref.read(lessonControllerProvider);
      if (state.error == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lesson deleted')),
        );
        context.pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.error ?? 'Error deleting'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.lesson != null;
    final state = ref.watch(lessonControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Lesson' : 'Create Lesson'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteLesson,
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          decoration: const InputDecoration(labelText: 'Week', border: OutlineInputBorder()),
                          initialValue: _week,
                          items: List.generate(12, (index) => DropdownMenuItem(value: index + 1, child: Text('Week ${index + 1}'))),
                          onChanged: isEditing ? null : (value) => setState(() => _week = value!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          decoration: const InputDecoration(labelText: 'Day', border: OutlineInputBorder()),
                          initialValue: _day,
                          items: List.generate(5, (index) => DropdownMenuItem(value: index + 1, child: Text('Day ${index + 1}'))),
                          onChanged: isEditing ? null : (value) => setState(() => _day = value!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Lesson Title', border: OutlineInputBorder()),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _topicController,
                    decoration: const InputDecoration(labelText: 'Topic (Optional)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _verseController,
                    decoration: const InputDecoration(labelText: 'Bible Verse', border: OutlineInputBorder()),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _minutesController,
                    decoration: const InputDecoration(labelText: 'Estimated Minutes', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  _buildDynamicList('Connect', _connectControllers),
                  _buildDynamicList('Discover', _discoverControllers),
                  _buildDynamicList('Challenge', _challengeControllers),
                  _buildDynamicList('Still Thirsty (Bible References)', _stillThirstyControllers),
                  
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saveLesson,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    child: Text(isEditing ? 'Save Changes' : 'Create Lesson'),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
