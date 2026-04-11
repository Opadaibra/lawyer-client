import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/case_controller.dart';
import '../../controllers/minute_controller.dart';
import '../../controllers/task_controller.dart';
import '../../app/routes/app_routes.dart';
import '../widgets/custom_app_bar.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<MinuteController>().fetchMinutes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final caseCtrl = Get.find<CaseController>();
    final minuteCtrl = Get.find<MinuteController>();
    final taskCtrl = Get.find<TaskController>();
    final auth = Get.find<AuthController>();
    final canMutate = auth.currentUser.value?.canMutateOfficeContent ?? true;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'archive'.tr,
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey[300],
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'cases'.tr),
              Tab(text: 'tasks'.tr),
              Tab(text: 'minutes'.tr),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCasesList(caseCtrl, canMutate),
            _buildTasksList(taskCtrl, canMutate),
            _buildMinutesList(minuteCtrl, canMutate),
          ],
        ),
      ),
    );
  }

  Widget _buildCasesList(CaseController ctrl, bool canMutate) {
    return Obx(() {
      final archived = ctrl.cases.where((c) => c.isArchived).toList();
      if (archived.isEmpty) return _buildEmptyState();
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: archived.length,
        itemBuilder: (_, i) {
          final c = archived[i];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.archive_outlined, color: Colors.grey),
              title: Text(c.caseNumber),
              subtitle: Text(c.subject ?? ''),
              trailing: canMutate
                  ? IconButton(
                      icon: const Icon(Icons.unarchive_outlined),
                      onPressed: () => ctrl.unarchiveCase(c.id),
                    )
                  : null,
              onTap: () => Get.toNamed(AppRoutes.caseDetail, arguments: {'case': c}),
            ),
          );
        },
      );
    });
  }

  Widget _buildTasksList(TaskController ctrl, bool canMutate) {
    return Obx(() {
      final archived = ctrl.tasks.where((t) => t.isArchived).toList();
      if (archived.isEmpty) return _buildEmptyState();
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: archived.length,
        itemBuilder: (_, i) {
          final t = archived[i];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.archive_outlined, color: Colors.grey),
              title: Text(t.title),
              subtitle: Text(t.dueDate ?? ''),
              trailing: canMutate
                  ? IconButton(
                      icon: const Icon(Icons.unarchive_outlined),
                      onPressed: () => ctrl.unarchiveTask(t.id),
                    )
                  : null,
              onTap: () => Get.toNamed(AppRoutes.taskDetail, arguments: {'task': t}),
            ),
          );
        },
      );
    });
  }

  Widget _buildMinutesList(MinuteController ctrl, bool canMutate) {
    return Obx(() {
      final archived = ctrl.minutes.where((m) => m.isArchived).toList();
      if (archived.isEmpty) return _buildEmptyState();
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: archived.length,
        itemBuilder: (_, i) {
          final m = archived[i];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.archive_outlined, color: Colors.grey),
              title: Text(m.title),
              subtitle: Text(m.minuteNumber ?? ''),
              trailing: canMutate
                  ? IconButton(
                      icon: const Icon(Icons.unarchive_outlined),
                      onPressed: () => ctrl.unarchiveMinute(m.id),
                    )
                  : null,
              onTap: () => canMutate
                  ? Get.toNamed(AppRoutes.minuteForm, arguments: {'minute': m})
                  : Get.toNamed(AppRoutes.minuteDetail, arguments: {'minute': m}),
            ),
          );
        },
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text('no_archived_items'.tr, style: const TextStyle(color: Colors.grey)),
    );
  }
}
