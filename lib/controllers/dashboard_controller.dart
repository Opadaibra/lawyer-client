import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/api_service.dart';
import '../../data/models/client_model.dart';
import '../../data/models/sub_resource_models.dart';
import '../../data/models/task_model.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/notification_service.dart';
import '../../core/utils/helpers.dart';

class DashboardController extends GetxController {
  final ApiService _api = ApiService();

  final isLoading = false.obs;
  final totalClients = 0.obs;
  final totalCases = 0.obs;
  final pendingTasks = 0.obs;
  final overdueTasks = 0.obs;
  final totalSessions = 0.obs;
  final recentClients = <ClientModel>[].obs;
  final recentCases = <dynamic>[].obs;
  final recentMinutes = <dynamic>[].obs;
  final allTasks = <TaskModel>[].obs;
  /// جلسات من `GET /cases/all-sessions`
  final allSessions = <SessionModel>[].obs;
  final focusedDay = DateTime.now().obs;
  final selectedDay = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
  }

  Future<void> refreshDashboard() => loadDashboard();

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'overdue':
        return Colors.red;
      case 'in_progress':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  List<TaskModel> filterTasksByDate(DateTime date) {
    return allTasks.where((task) {
      if (task.dueDate == null) return false;
      final dueUtc = AppHelpers.dueInstantUtc(task.dueDate);
      if (dueUtc == null) return false;
      final d = dueUtc.toLocal();
      return d.year == date.year && d.month == date.month && d.day == date.day;
    }).toList();
  }

  Future<void> loadDashboard() async {
    isLoading.value = true;
    try {
      await Future.wait([
        _loadClients(),
        _loadCases(),
        _loadTasks(),
        _loadMinutes(),
        _loadAllSessions(),
      ]);
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadClients() async {
    try {
      final response = await _api.getList('/clients/');
      final list = _parseList(response);
      totalClients.value = list.length;
      final clients = list.map((e) => ClientModel.fromJson(e)).toList();
      recentClients.value = clients.take(5).toList();
    } catch (_) {}
  }

  Future<void> _loadCases() async {
    try {
      final response = await _api.getList('/cases/');
      final list = _parseList(response);
      totalCases.value = list.length;
      recentCases.value = list.take(5).toList();
    } catch (_) {}
  }

  Future<void> _loadAllSessions() async {
    try {
      final response =
          await _api.getList('${AppConstants.cases}/all-sessions');
      final list = _parseList(response);
      final sessions = list
          .map((e) =>
              SessionModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      sessions.sort((a, b) {
        try {
          return a.date.compareTo(b.date);
        } catch (_) {
          return 0;
        }
      });
      allSessions.assignAll(sessions);
      totalSessions.value = sessions.length;
    } catch (_) {
      allSessions.clear();
      totalSessions.value = 0;
    }
  }

  Future<void> _loadMinutes() async {
    try {
      final response = await _api.getList('/minutes/');
      final list = _parseList(response);
      recentMinutes.value = list.take(5).toList();
    } catch (_) {}
  }

  Future<void> _loadTasks() async {
    try {
      final response = await _api.getList('/tasks/');
      final list = _parseList(response);
      final tasks = list.map((e) => TaskModel.fromJson(e)).toList();
      allTasks.value = tasks;
      pendingTasks.value =
          tasks.where((t) => t.status == 'pending').length;
      overdueTasks.value = tasks.where((t) {
        if (t.dueDate == null || t.status == 'completed') return false;
        return AppHelpers.isOverdue(t.dueDate);
      }).length;
      NotificationService.scheduleDailyTaskReminder(tasks);
    } catch (_) {}
  }

  List<dynamic> _parseList(dynamic response) {
    if (response is List) return response;
    if (response is Map) return response['data'] as List? ?? [];
    return [];
  }

  /// تحديث قائمة الجلسات فقط (مثلاً من شاشة «كل الجلسات»).
  Future<void> reloadAllSessions() => _loadAllSessions();
}
