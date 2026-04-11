import 'dart:convert';
import 'package:get/get.dart';
import '../../data/services/api_service.dart';
import '../../data/models/task_model.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/notification_service.dart';

class TaskController extends GetxController {
  final ApiService _api = ApiService();

  final tasks = <TaskModel>[].obs;
  final selectedTask = Rx<TaskModel?>(null);
  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final filterStatus = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    isLoading.value = true;
    try {
      final response = await _api.getList('${AppConstants.tasks}/');
      final list = _parseList(response);
      tasks.value = list.map((e) => TaskModel.fromJson(e)).toList();
      _checkReminders();
    } catch (e) {
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchTaskById(int id) async {
    isLoading.value = true;
    try {
      final response = await _api.get('${AppConstants.tasks}/$id');
      final data = _extractData(response);
      selectedTask.value = TaskModel.fromJson(data);
    } catch (e) {
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  List<TaskModel> get filteredTasks {
    if (filterStatus.value.isEmpty) return tasks;
    return tasks.where((t) => t.status == filterStatus.value).toList();
  }

  List<TaskModel> get pendingTasks =>
      tasks.where((t) => t.status == 'pending' && !t.isArchived).toList();

  List<TaskModel> get overdueTasks {
    final now = DateTime.now();
    return tasks.where((t) {
      if (t.dueDate == null || t.isArchived) return false;
      try {
        return DateTime.parse(t.dueDate!).isBefore(now) &&
            t.status != 'completed';
      } catch (_) {
        return false;
      }
    }).toList();
  }

  Future<bool> createTask(TaskModel task) async {
    isSubmitting.value = true;
    try {
      await _api.post('${AppConstants.tasks}/', data: task.toCreateJson());
      await fetchTasks();
      Get.back();
      _showSuccess('Task created / تم إنشاء المهمة');
      return true;
    } catch (e) {
      _showError(e);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> updateTask(int id, TaskModel task) async {
    isSubmitting.value = true;
    try {
      await _api.patch('${AppConstants.tasks}/$id', task.toCreateJson());
      await fetchTasks();
      Get.back();
      _showSuccess('Task updated / تم تحديث المهمة');
      return true;
    } catch (e) {
      _showError(e);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> completeTask(int id) async {
    try {
      final task = tasks.firstWhereOrNull((t) => t.id == id);
      if (task == null) return false;
      await _api.patch('${AppConstants.tasks}/$id', {
        'case_file_id': task.caseFileId,
        'title': task.title,
        'status': 'completed',
      });
      await fetchTasks();
      _showSuccess('Task completed! / تم إكمال المهمة!');
      return true;
    } catch (e) {
      _showError(e);
      return false;
    }
  }

  Future<bool> deleteTask(int id) async {
    try {
      await _api.delete('${AppConstants.tasks}/$id');
      tasks.removeWhere((t) => t.id == id);
      _showSuccess('Task deleted / تم حذف المهمة');
      return true;
    } catch (e) {
      _showError(e);
      return false;
    }
  }

  Future<void> archiveTask(int id) async {
    try {
      await _api.post('${AppConstants.tasks}/$id/archive');
      await fetchTasks();
      _showSuccess('Task archived / تم أرشفة المهمة');
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> unarchiveTask(int id) async {
    try {
      await _api.post('${AppConstants.tasks}/$id/unarchive');
      await fetchTasks();
      _showSuccess('Task unarchived / تم إلغاء الأرشفة');
    } catch (e) {
      _showError(e);
    }
  }

  void _checkReminders() async {
    final now = DateTime.now();
    for (final task in tasks) {
      if (task.dueDate == null || task.isArchived || task.status == 'completed') {
        continue;
      }
      try {
        final due = DateTime.parse(task.dueDate!);
        final diff = due.difference(now);
        if (diff.isNegative && task.status != 'completed') {
          await NotificationService.addNotification(
            title: 'Overdue Task / مهمة متأخرة',
            message: '"${task.title}" is overdue!',
            type: 'overdue',
            relatedId: task.id,
            relatedType: 'task',
          );
        } else if (diff.inHours <= 24 && diff.inHours >= 0) {
          await NotificationService.addNotification(
            title: 'Task Due Soon / مهمة قادمة',
            message: '"${task.title}" is due in ${diff.inHours}h',
            type: 'task_reminder',
            relatedId: task.id,
            relatedType: 'task',
          );
        }
        
        // Exact time scheduling
        if (due.isAfter(now)) {
           await NotificationService.scheduleNotification(
             id: task.id,
             title: 'Task Due! / حان وقت المهمة!',
             body: 'Your task "${task.title}" is due right now.',
             scheduledDate: due,
             payload: jsonEncode({'related_type': 'task', 'related_id': task.id}),
           );
        }
      } catch (_) {}
    }
  }

  List<dynamic> _parseList(dynamic response) {
    if (response is List) return response;
    if (response is Map) {
      return response['data'] as List? ?? response['tasks'] as List? ?? [];
    }
    return [];
  }

  Map<String, dynamic> _extractData(Map<String, dynamic> response) {
    return (response['data'] as Map<String, dynamic>?) ?? response;
  }

  void _showError(dynamic e) {
    Get.snackbar('Error / خطأ',
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM);
  }

  void _showSuccess(String msg) {
    Get.snackbar('Success / نجاح', msg, snackPosition: SnackPosition.BOTTOM);
  }
}
