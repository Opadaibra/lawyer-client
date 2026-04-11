import 'package:get/get.dart';
import '../../data/services/notification_service.dart';

class NotificationController extends GetxController {
  final notifications = <NotificationModel>[].obs;
  final unreadCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
  }

  void loadNotifications() {
    notifications.value = NotificationService.getAll();
    unreadCount.value = notifications.where((n) => !n.isRead).length;
  }

  Future<void> markAsRead(String id) async {
    await NotificationService.markAsRead(id);
    loadNotifications();
  }

  Future<void> markAllAsRead() async {
    await NotificationService.markAllAsRead();
    loadNotifications();
  }

  Future<void> deleteNotification(String id) async {
    await NotificationService.deleteNotification(id);
    loadNotifications();
  }

  Future<void> clearAll() async {
    await NotificationService.clearAll();
    loadNotifications();
  }
}
