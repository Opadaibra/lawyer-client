import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/notification_controller.dart';
import '../../data/services/notification_service.dart';
import '../../app/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/empty_state_widget.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<NotificationController>();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Notifications / الإشعارات',
        showNotification: false,
        actions: [
          TextButton(
            onPressed: () async {
              await ctrl.markAllAsRead();
            },
            child: const Text('Mark all read', style: TextStyle(color: Colors.white)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () => _confirmClearAll(ctrl),
            tooltip: 'Clear all / مسح الكل',
          ),
        ],
      ),
      body: Obx(() {
        final items = ctrl.notifications;
        if (items.isEmpty) {
          return const EmptyStateWidget(
            title: 'No notifications\nلا توجد إشعارات',
            icon: Icons.notifications_off_outlined,
          );
        }
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, i) {
            final notif = items[i];
            return Dismissible(
              key: Key(notif.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: Colors.red,
                child: const Icon(Icons.delete_outline, color: Colors.white),
              ),
              onDismissed: (_) => ctrl.deleteNotification(notif.id),
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                color: notif.isRead
                    ? null
                    : AppTheme.primary.withOpacity(0.05),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    await ctrl.markAsRead(notif.id);
                    // Navigate to related item
                    if (notif.relatedType == 'task' &&
                        notif.relatedId != null) {
                      Get.toNamed(AppRoutes.taskDetail,
                          arguments: {'id': notif.relatedId});
                    } else if (notif.relatedType == 'case' &&
                        notif.relatedId != null) {
                      Get.toNamed(AppRoutes.caseDetail,
                          arguments: {'id': notif.relatedId});
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _getNotifColor(notif.type)
                                .withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getNotifIcon(notif.type),
                            color: _getNotifColor(notif.type),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      notif.title,
                                      style: TextStyle(
                                        fontWeight: notif.isRead
                                            ? FontWeight.w500
                                            : FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  if (!notif.isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppTheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                notif.message,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600]),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppHelpers.formatDateTime(
                                    notif.createdAt.toIso8601String()),
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Color _getNotifColor(String type) {
    switch (type) {
      case 'overdue':
        return AppTheme.error;
      case 'task_reminder':
        return AppTheme.warning;
      case 'case_reminder':
        return AppTheme.info;
      default:
        return AppTheme.primary;
    }
  }

  IconData _getNotifIcon(String type) {
    switch (type) {
      case 'overdue':
        return Icons.warning_amber_outlined;
      case 'task_reminder':
        return Icons.task_outlined;
      case 'case_reminder':
        return Icons.folder_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  void _confirmClearAll(NotificationController ctrl) {
    Get.dialog(AlertDialog(
      title: const Text('Clear All / مسح الكل'),
      content: const Text('Delete all notifications? / حذف جميع الإشعارات؟'),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            Get.back();
            ctrl.clearAll();
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Clear All'),
        ),
      ],
    ));
  }
}
