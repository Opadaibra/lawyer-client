import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/task_controller.dart';
import '../../../data/models/task_model.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../widgets/custom_app_bar.dart';

class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<TaskController>();
    
    // Support navigation via full model or just ID (for notifications)
    final TaskModel? taskData;
    if (Get.arguments?['task'] is TaskModel) {
      taskData = Get.arguments['task'] as TaskModel;
    } else if (Get.arguments?['id'] != null) {
      final id = Get.arguments['id'] is int ? Get.arguments['id'] : int.tryParse(Get.arguments['id'].toString());
      taskData = ctrl.tasks.firstWhereOrNull((t) => t.id == id);
    } else {
      taskData = null;
    }

    if (taskData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Task Not Found')),
        body: const Center(child: Text('Task not found or loading...\nالمهمة غير موجودة أو قيد التحميل')),
      );
    }

    final task = taskData; // Final local for null safety
    final statusColor = AppTheme.getStatusColor(task.status);
    final auth = Get.find<AuthController>();
    final canMutate = auth.currentUser.value?.canMutateOfficeContent ?? true;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Task Detail / تفاصيل المهمة',
        actions: [
          if (canMutate)
            PopupMenuButton(
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Edit'))),
                PopupMenuItem(
                    value: 'archive',
                    child: ListTile(
                        leading: Icon(task.isArchived
                            ? Icons.unarchive_outlined
                            : Icons.archive_outlined),
                        title: Text(
                            task.isArchived ? 'Unarchive' : 'Archive'))),
                const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                        leading: Icon(Icons.delete_outline, color: Colors.red),
                        title: Text('Delete',
                            style: TextStyle(color: Colors.red)))),
              ],
              onSelected: (v) {
                if (v == 'edit') {
                  Get.toNamed(AppRoutes.taskForm, arguments: {'task': task});
                } else if (v == 'archive') {
                  task.isArchived
                      ? ctrl.unarchiveTask(task.id)
                      : ctrl.archiveTask(task.id);
                } else {
                  _confirmDelete(ctrl, task.id);
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.task_outlined, color: statusColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: statusColor),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      task.status.replaceAll('_', ' '),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _DetailTile(Icons.calendar_today_outlined, 'Due Date / تاريخ الاستحقاق',
                        AppHelpers.formatDateHuman(task.dueDate)),
                    if (task.caseNumber != null)
                      _DetailTile(Icons.folder_outlined, 'Case / القضية', task.caseNumber!),
                    _DetailTile(Icons.access_time_outlined, 'Created / تاريخ الإنشاء',
                        AppHelpers.formatDateHuman(task.createdAt)),
                    if (task.isArchived)
                      _DetailTile(Icons.archive_outlined, 'Archived / مؤرشفة', 'Yes / نعم'),
                  ],
                ),
              ),
            ),
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Description / الوصف',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(task.description!,
                          style: const TextStyle(height: 1.6)),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (task.status != 'completed')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => ctrl.completeTask(task.id).then((_) => Get.back()),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Mark Complete / إكمال المهمة'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(TaskController ctrl, int id) {
    Get.dialog(AlertDialog(
      title: const Text('Delete Task / حذف المهمة'),
      content: const Text('Are you sure? / هل أنت متأكد؟'),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            Get.back(); Get.back();
            ctrl.deleteTask(id);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    ));
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailTile(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
