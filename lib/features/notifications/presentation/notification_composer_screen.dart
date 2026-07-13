import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/notification_model.dart';
import '../application/notification_providers.dart';
import 'widgets/user_search_modal.dart';

class NotificationComposerScreen extends ConsumerStatefulWidget {
  final NotificationModel? initialDraft; // Optional draft to edit

  const NotificationComposerScreen({super.key, this.initialDraft});

  @override
  ConsumerState<NotificationComposerScreen> createState() => _NotificationComposerScreenState();
}

class _NotificationComposerScreenState extends ConsumerState<NotificationComposerScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _id;
  
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _deepLinkController = TextEditingController();
  
  NotificationTargetType _targetType = NotificationTargetType.all;
  List<String> _targetValues = [];
  
  NotificationDelivery _delivery = NotificationDelivery.sendNow;
  NotificationPriority _priority = NotificationPriority.normal;
  
  // Schedule state
  DateTime? _scheduledAt;
  TimeOfDay? _timeOfDay;

  Timer? _autoSaveTimer;
  bool _isDirty = false;
  bool _isSaving = false;
  DateTime? _lastSaved;

  @override
  void initState() {
    super.initState();
    if (widget.initialDraft != null) {
      _id = widget.initialDraft!.id;
      _titleController.text = widget.initialDraft!.title;
      _messageController.text = widget.initialDraft!.message;
      _imageUrlController.text = widget.initialDraft!.imageUrl ?? '';
      _deepLinkController.text = widget.initialDraft!.deepLink ?? '';
      _targetType = widget.initialDraft!.targetType;
      _targetValues = List.from(widget.initialDraft!.targetValues);
      _delivery = widget.initialDraft!.deliveryType == 'scheduled' ? NotificationDelivery.schedule : NotificationDelivery.sendNow;
      _scheduledAt = widget.initialDraft!.scheduledAt;
      if (widget.initialDraft!.scheduledAt != null) {
        _timeOfDay = TimeOfDay.fromDateTime(widget.initialDraft!.scheduledAt!);
      }
    } else {
      _id = const Uuid().v4();
    }

    _titleController.addListener(_markDirty);
    _messageController.addListener(_markDirty);
    _imageUrlController.addListener(_markDirty);
    _deepLinkController.addListener(_markDirty);

    // Auto-save every 15 seconds if dirty
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 15), (_) => _autoSave());
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleController.dispose();
    _messageController.dispose();
    _imageUrlController.dispose();
    _deepLinkController.dispose();
    super.dispose();
  }

  Future<void> _autoSave() async {
    if (!_isDirty || _isSaving) return;
    if (_titleController.text.isEmpty && _messageController.text.isEmpty) return; // Don't save empty drafts

    setState(() => _isSaving = true);
    
    final draft = _buildModel(NotificationStatus.draft);
    await ref.read(notificationControllerProvider.notifier).saveDraft(draft);
    
    if (mounted) {
      setState(() {
        _isDirty = false;
        _isSaving = false;
        _lastSaved = DateTime.now();
      });
    }
  }

  NotificationModel _buildModel(NotificationStatus status) {
    return NotificationModel(
      id: _id,
      title: _titleController.text,
      message: _messageController.text,
      targetType: _targetType,
      targetValues: _targetValues,
      targetFilters: const {},
      deliveryType: _delivery == NotificationDelivery.schedule ? 'scheduled' : 'sendNow',
      scheduledAt: _delivery == NotificationDelivery.schedule ? _scheduledAt : null,
      status: status,
      createdBy: 'admin', // Ideally fetch from Auth service
      createdAt: widget.initialDraft?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      sentAt: status == NotificationStatus.sent ? DateTime.now() : null,
    );
  }

  Future<void> _handlePublish() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Additional validations
    if (_targetType == NotificationTargetType.selectedUsers && _targetValues.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one user.')));
      return;
    }
    if (_delivery == NotificationDelivery.schedule && _scheduledAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a scheduled date and time.')));
      return;
    }

    final model = _buildModel(
      _delivery == NotificationDelivery.sendNow ? NotificationStatus.sent : NotificationStatus.scheduled
    );

    if (_delivery == NotificationDelivery.sendNow) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Send Broadcast?'),
          content: const Text('This will be sent immediately to the selected targets. Are you sure?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true), 
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text('Send Now')
            ),
          ],
        ),
      );
      if (confirm != true) return;
      await ref.read(notificationControllerProvider.notifier).sendNow(model);
    } else {
      await ref.read(notificationControllerProvider.notifier).scheduleNotification(model);
    }

    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(notificationControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Operation failed: ${next.error}')),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.initialDraft == null ? 'Compose Broadcast' : 'Edit Broadcast Draft'),
        backgroundColor: Colors.white,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else if (_lastSaved != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(child: Text('Draft saved at ${DateFormat('HH:mm').format(_lastSaved!)}', style: const TextStyle(color: Colors.grey, fontSize: 12))),
            ),
          TextButton(
            onPressed: () async {
              await _autoSave();
              if (context.mounted) context.pop();
            },
            child: const Text('Save Draft & Exit'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _handlePublish,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: Text(_delivery == NotificationDelivery.sendNow ? 'Send Now' : 'Schedule'),
          ),
          const SizedBox(width: 24),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Side - Form
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('1. Message Content'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder()),
                              validator: (v) => v!.trim().isEmpty ? 'Title is required' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _messageController,
                              decoration: const InputDecoration(labelText: 'Message *', border: OutlineInputBorder()),
                              maxLines: 4,
                              validator: (v) => v!.trim().isEmpty ? 'Message is required' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _imageUrlController,
                              decoration: const InputDecoration(labelText: 'Image URL (optional)', border: OutlineInputBorder()),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _deepLinkController,
                              decoration: const InputDecoration(labelText: 'Deep Link Route (optional, e.g. /lessons/123)', border: OutlineInputBorder()),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    _buildSectionHeader('2. Target Audience'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButtonFormField<NotificationTargetType>(
                              decoration: const InputDecoration(labelText: 'Target Type', border: OutlineInputBorder()),
                              value: _targetType,
                              items: NotificationTargetType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.name.replaceAll('_', ' ').toUpperCase()))).toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() {
                                    _targetType = v;
                                    _targetValues.clear();
                                    _markDirty();
                                  });
                                }
                              },
                            ),
                            if (_targetType == NotificationTargetType.selectedUsers) ...[
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: InputDecorator(
                                      decoration: const InputDecoration(labelText: 'Selected Users', border: OutlineInputBorder()),
                                      child: Text(_targetValues.isEmpty ? 'No users selected' : '${_targetValues.length} users selected'),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton(
                                    onPressed: () async {
                                      final selected = await showDialog<List<String>>(
                                        context: context,
                                        builder: (ctx) => UserSearchModal(initiallySelectedUids: _targetValues),
                                      );
                                      if (selected != null) {
                                        setState(() {
                                          _targetValues = selected;
                                          _markDirty();
                                        });
                                      }
                                    },
                                    child: const Text('Select Users'),
                                  ),
                                ],
                              ),
                            ],
                            if (_targetType == NotificationTargetType.selectedCountry) ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                decoration: const InputDecoration(labelText: 'Country Code (comma-separated, e.g. US, IN, CA)', border: OutlineInputBorder()),
                                initialValue: _targetValues.join(', '),
                                onChanged: (v) {
                                  _targetValues = v.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                                  _markDirty();
                                },
                              ),
                            ],
                            if (_targetType == NotificationTargetType.selectedLanguage) ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                decoration: const InputDecoration(labelText: 'Language Code (comma-separated, e.g. en, es, fr)', border: OutlineInputBorder()),
                                initialValue: _targetValues.join(', '),
                                onChanged: (v) {
                                  _targetValues = v.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                                  _markDirty();
                                },
                              ),
                            ]
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    _buildSectionHeader('3. Delivery & Priority'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            DropdownButtonFormField<NotificationDelivery>(
                              decoration: const InputDecoration(labelText: 'Delivery Method', border: OutlineInputBorder()),
                              value: _delivery,
                              items: const [
                                DropdownMenuItem(value: NotificationDelivery.sendNow, child: Text('SEND NOW (IMMEDIATE)')),
                                DropdownMenuItem(value: NotificationDelivery.schedule, child: Text('SEND LATER (SCHEDULED)')),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() {
                                    _delivery = v;
                                    _markDirty();
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            if (_delivery == NotificationDelivery.schedule) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        final date = await showDatePicker(context: context, initialDate: _scheduledAt ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                                        if (date != null) setState(() { _scheduledAt = date; _markDirty(); });
                                      },
                                      icon: const Icon(Icons.calendar_today),
                                      label: Text(_scheduledAt != null ? DateFormat('dd MMM yyyy').format(_scheduledAt!) : 'Select Date'),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        final time = await showTimePicker(context: context, initialTime: _timeOfDay ?? TimeOfDay.now());
                                        if (time != null) {
                                          setState(() {
                                            _timeOfDay = time;
                                            if (_scheduledAt != null) {
                                              _scheduledAt = DateTime(_scheduledAt!.year, _scheduledAt!.month, _scheduledAt!.day, time.hour, time.minute);
                                            }
                                            _markDirty();
                                          });
                                        }
                                      },
                                      icon: const Icon(Icons.access_time),
                                      label: Text(_timeOfDay != null ? _timeOfDay!.format(context) : 'Select Time'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),
                            DropdownButtonFormField<NotificationPriority>(
                              decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
                              value: _priority,
                              items: NotificationPriority.values.map((t) => DropdownMenuItem(value: t, child: Text(t.name.toUpperCase()))).toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() {
                                    _priority = v;
                                    _markDirty();
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Right Side - Device Preview
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.all(32),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const Text('Device Preview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey)),
                    const SizedBox(height: 24),
                    Container(
                      width: 300,
                      height: 600,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: Colors.grey[800]!, width: 8),
                      ),
                      child: Stack(
                        children: [
                          // Screen background
                          Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          // Top status bar notch
                          Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              width: 100,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
                              ),
                            ),
                          ),
                          // Notification Banner
                          Positioned(
                            top: 50,
                            left: 10,
                            right: 10,
                            child: ListenableBuilder(
                              listenable: Listenable.merge([_titleController, _messageController, _imageUrlController]),
                              builder: (context, _) {
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 1)
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                                        child: const Icon(Icons.notifications, color: Colors.white),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _titleController.text.isEmpty ? 'Notification Title' : _titleController.text,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _messageController.text.isEmpty ? 'Notification message body will appear here.' : _messageController.text,
                                              style: const TextStyle(fontSize: 12, color: Colors.black87),
                                            ),
                                            if (_imageUrlController.text.isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.network(
                                                  _imageUrlController.text,
                                                  height: 100,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => Container(height: 100, color: Colors.grey[300], child: const Center(child: Icon(Icons.broken_image))),
                                                ),
                                              )
                                            ]
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
    );
  }
}
