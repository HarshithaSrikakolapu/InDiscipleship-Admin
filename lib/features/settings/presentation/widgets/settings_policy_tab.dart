import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/auth_repository.dart';

class SettingsPolicyTab extends ConsumerStatefulWidget {
  final String title;
  final String content;
  final String draftContent;
  final int version;
  final DateTime lastUpdated;
  final String updatedBy;
  final DateTime? publishedAt;
  final String publishedBy;
  final Future<bool> Function(String content, String userId) onSave;
  final Future<bool> Function(String content, String userId) onPublish;

  const SettingsPolicyTab({
    super.key,
    required this.title,
    required this.content,
    required this.draftContent,
    required this.version,
    required this.lastUpdated,
    required this.updatedBy,
    required this.publishedAt,
    required this.publishedBy,
    required this.onSave,
    required this.onPublish,
  });

  @override
  ConsumerState<SettingsPolicyTab> createState() => _SettingsPolicyTabState();
}

class _SettingsPolicyTabState extends ConsumerState<SettingsPolicyTab> {
  late quill.QuillController _quillController;
  bool _isEditing = true;

  @override
  void initState() {
    super.initState();
    _initQuillController();
  }

  void _initQuillController() {
    final rawContent = widget.draftContent;
    if (rawContent.isEmpty) {
      _quillController = quill.QuillController.basic();
    } else {
      try {
        final doc = quill.Document.fromJson(jsonDecode(rawContent));
        _quillController = quill.QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (_) {
        final doc = quill.Document()..insert(0, rawContent);
        _quillController = quill.QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    }
  }

  @override
  void didUpdateWidget(SettingsPolicyTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draftContent != widget.draftContent) {
      setState(() {
        _quillController.dispose();
        _initQuillController();
      });
    }
  }

  @override
  void dispose() {
    _quillController.dispose();
    super.dispose();
  }

  String _getQuillData() {
    final deltaJson = _quillController.document.toDelta().toJson();
    return jsonEncode(deltaJson);
  }

  bool _isDocumentEmpty() {
    final text = _quillController.document.toPlainText().trim();
    return text.isEmpty;
  }

  void _saveDraft() async {
    if (_isDocumentEmpty()) {
      _showError('Cannot save an empty document.');
      return;
    }

    final user = ref.read(authRepositoryProvider).currentUser;
    final userId = user?.email ?? user?.uid ?? 'unknown';

    final contentJson = _getQuillData();
    final success = await widget.onSave(contentJson, userId);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.title} draft saved successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        _showError('Failed to save draft settings.');
      }
    }
  }

  void _publishPolicy() async {
    if (_isDocumentEmpty()) {
      _showError('Cannot publish an empty document.');
      return;
    }

    // Show confirmation dialog before publishing
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Publish ${widget.title}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to publish this version? This will update the live policy for all mobile users, increment the version, and record you as the publisher.',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm Publish'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final user = ref.read(authRepositoryProvider).currentUser;
    final userId = user?.email ?? user?.uid ?? 'unknown';

    final contentJson = _getQuillData();
    final success = await widget.onPublish(contentJson, userId);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.title} published and live! (Version ${widget.version + 1})',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        _showError('Failed to publish settings.');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    _quillController.readOnly = !_isEditing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (widget.version > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Version ${widget.version}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Published by ${widget.publishedBy}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            // Mode Selector
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  _buildModeButton(
                    label: 'Edit',
                    isActive: _isEditing,
                    onTap: () => setState(() => _isEditing = true),
                  ),
                  _buildModeButton(
                    label: 'Preview',
                    isActive: !_isEditing,
                    onTap: () => setState(() => _isEditing = false),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          color: AppColors.cardWhite,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isEditing) ...[
                quill.QuillSimpleToolbar(
                  controller: _quillController,
                  config: const quill.QuillSimpleToolbarConfig(
                    showAlignmentButtons: true,
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),
              ],
              Container(
                height: 450,
                padding: const EdgeInsets.all(24.0),
                child: quill.QuillEditor.basic(
                  controller: _quillController,
                  config: const quill.QuillEditorConfig(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (widget.updatedBy.isNotEmpty)
              Text(
                'Draft last saved by ${widget.updatedBy}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              )
            else
              const SizedBox.shrink(),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _saveDraft,
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Save Draft'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _publishPolicy,
                  icon: const Icon(Icons.publish),
                  label: const Text('Publish Live'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModeButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive
              ? [
                  const BoxShadow(
                    color: Colors.black12,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
