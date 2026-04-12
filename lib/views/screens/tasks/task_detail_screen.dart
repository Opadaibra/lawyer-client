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
    final auth = Get.find<AuthController>();
    final args = Get.arguments as Map<String, dynamic>?;

    TaskModel? fromArgs;
    int? idArg;
    if (args?['task'] is TaskModel) {
      fromArgs = args!['task'] as TaskModel;
    } else if (args?['id'] != null) {
      idArg = args!['id'] is int
          ? args['id'] as int
          : int.tryParse(args['id'].toString());
      if (idArg != null) {
        fromArgs = ctrl.tasks.firstWhereOrNull((t) => t.id == idArg);
      }
    }

    final resolved = fromArgs;
    if (resolved != null) {
      return _TaskDetailView(task: resolved, ctrl: ctrl, auth: auth);
    }

    if (idArg != null && !auth.isClient) {
      return FutureBuilder<TaskModel?>(
        future: ctrl.fetchTaskByIdQuiet(idArg),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return Scaffold(
              appBar: CustomAppBar(title: 'task_detail'.tr),
              body: const Center(child: CircularProgressIndicator()),
            );
          }
          final t = snap.data;
          if (t == null) {
            return Scaffold(
              appBar: AppBar(title: Text('task_not_found'.tr)),
              body: Center(child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text('task_not_found_body'.tr, textAlign: TextAlign.center),
              )),
            );
          }
          return _TaskDetailView(task: t, ctrl: ctrl, auth: auth);
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('task_not_found'.tr)),
      body: Center(child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text('task_not_found_body'.tr, textAlign: TextAlign.center),
      )),
    );
  }
}

class _TaskDetailView extends StatelessWidget {
  final TaskModel task;
  final TaskController ctrl;
  final AuthController auth;

  const _TaskDetailView({
    required this.task,
    required this.ctrl,
    required this.auth,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.getStatusColor(task.status);
    final canMutate = auth.currentUser.value?.canMutateOfficeContent ?? true;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'task_detail'.tr,
        actions: [
          if (canMutate)
            PopupMenuButton(
              itemBuilder: (_) => [
                PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                        leading: const Icon(Icons.edit_outlined),
                        title: Text('edit'.tr))),
                PopupMenuItem(
                    value: 'archive',
                    child: ListTile(
                        leading: Icon(task.isArchived
                            ? Icons.unarchive_outlined
                            : Icons.archive_outlined),
                        title: Text(
                            task.isArchived ? 'unarchive'.tr : 'archive_verb'.tr))),
                PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                        leading:
                            const Icon(Icons.delete_outline, color: Colors.red),
                        title: Text('delete'.tr,
                            style: const TextStyle(color: Colors.red)))),
              ],
              onSelected: (v) {
                if (v == 'edit') {
                  Get.toNamed(AppRoutes.taskForm, arguments: {'task': task});
                } else if (v == 'archive') {
                  task.isArchived
                      ? ctrl.unarchiveTask(task.id)
                      : ctrl.archiveTask(task.id);
                } else {
                  _confirmDelete(context, ctrl, task.id);
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      AppHelpers.taskStatusArabic(task.status),
                      style:
                          const TextStyle(color: Colors.white, fontSize: 12),
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
                    _DetailTile(Icons.calendar_today_outlined,
                        'task_due_date'.tr, AppHelpers.formatDateTime(task.dueDate)),
                    if (task.caseNumber != null)
                      _DetailTile(Icons.folder_outlined, 'task_case'.tr,
                          task.caseNumber!),
                    _DetailTile(Icons.access_time_outlined, 'task_created_at'.tr,
                        AppHelpers.formatDateHuman(task.createdAt)),
                    if (task.isArchived)
                      _DetailTile(Icons.archive_outlined,
                          'task_archived_label'.tr, 'yes'.tr),
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
                      Text('task_description'.tr,
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
                  onPressed: () =>
                      ctrl.completeTask(task.id).then((_) => Get.back()),
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text('mark_task_complete'.tr),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, TaskController ctrl, int id) {
    Get.dialog(AlertDialog(
      title: Text('delete_task_title'.tr),
      content: Text('are_you_sure'.tr),
      actions: [
        TextButton(onPressed: Get.back, child: Text('cancel'.tr)),
        ElevatedButton(
          onPressed: () {
            Get.back();
            Get.back();
            ctrl.deleteTask(id);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text('delete'.tr),
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
