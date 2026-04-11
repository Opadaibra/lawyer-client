import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/task_controller.dart';
import '../../../controllers/case_controller.dart';
import '../../../data/models/task_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/helpers.dart';
import '../../widgets/custom_app_bar.dart';

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _status = 'pending';
  int? _selectedCaseId;
  DateTime? _dueDate;
  TaskModel? _editTask;

  bool get _isEditing => _editTask != null;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    if (args?['task'] != null) {
      _editTask = args!['task'] as TaskModel;
      _titleCtrl.text = _editTask!.title;
      _descCtrl.text = _editTask!.description ?? '';
      _status = _editTask!.status;
      _selectedCaseId = _editTask!.caseFileId;
      if (_editTask!.dueDate != null) {
        try {
          _dueDate = DateTime.parse(_editTask!.dueDate!).toLocal();
        } catch (_) {}
      }
    } else if (args?['caseId'] != null) {
      _selectedCaseId = args!['caseId'] as int;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (pickedDate != null) {
      if (!context.mounted) return;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: _dueDate != null
            ? TimeOfDay.fromDateTime(_dueDate!)
            : TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          _dueDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      } else {
        setState(() => _dueDate = pickedDate);
      }
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final task = TaskModel(
      id: _editTask?.id ?? 0,
      caseFileId: _selectedCaseId,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
      dueDate: _dueDate?.toUtc().toIso8601String(),
      status: _status,
    );
    final ctrl = Get.find<TaskController>();
    if (_isEditing) {
      ctrl.updateTask(_editTask!.id, task);
    } else {
      ctrl.createTask(task);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<TaskController>();
    final caseCtrl = Get.find<CaseController>();

    return Scaffold(
      appBar: CustomAppBar(
        title: _isEditing ? 'Edit Task / تعديل المهمة' : 'New Task / مهمة جديدة',
        showNotification: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Case dropdown (optional)
              Obx(() {
                final cases = caseCtrl.cases;
                return DropdownButtonFormField<int>(
                  value: _selectedCaseId,
                  decoration: const InputDecoration(
                    labelText: 'Case / القضية (Optional)',
                    prefixIcon: Icon(Icons.folder_outlined),
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                        value: null, child: Text('No case / بدون قضية')),
                    ...cases.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.caseNumber),
                        )),
                  ],
                  onChanged: (v) => setState(() => _selectedCaseId = v),
                );
              }),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Task Title / عنوان المهمة *',
                  prefixIcon: Icon(Icons.task_outlined),
                ),
                validator: (v) => AppValidators.required(v, fieldName: 'Title'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description / الوصف',
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              // Due date picker
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).inputDecorationTheme.fillColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFFE0E7FF), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _dueDate != null
                              ? AppHelpers.formatDateTime(_dueDate!.toIso8601String())
                              : 'Due Date & Time / تاريخ ووقت الاستحقاق',
                          style: TextStyle(
                              color: _dueDate != null
                                  ? null
                                  : Colors.grey[500]),
                        ),
                      ),
                      if (_dueDate != null)
                        GestureDetector(
                          onTap: () => setState(() => _dueDate = null),
                          child: const Icon(Icons.clear, size: 18),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Status / الحالة',
                  prefixIcon: Icon(Icons.info_outlined),
                ),
                items: AppConstants.taskStatuses.map((s) =>
                    DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 24),
              Obx(() => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: ctrl.isSubmitting.value ? null : _submit,
                      child: ctrl.isSubmitting.value
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text(_isEditing
                              ? 'Update Task / تحديث'
                              : 'Create Task / إنشاء المهمة'),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
