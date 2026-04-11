import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../../data/services/storage_service.dart';
import '../models/task_model.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type; // task_reminder, case_reminder, overdue
  final int? relatedId;
  final String? relatedType; // task, case
  bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.relatedId,
    this.relatedType,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String,
      relatedId: json['related_id'] as int?,
      relatedType: json['related_type'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'type': type,
        'related_id': relatedId,
        'related_type': relatedType,
        'is_read': isRead,
        'created_at': createdAt.toIso8601String(),
      };
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static const _uuid = Uuid();

  static Future<void> initialize() async {
    tz_data.initializeTimeZones();
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap — navigate based on payload
        final payload = details.payload;
        if (payload != null) {
          try {
            final data = jsonDecode(payload) as Map<String, dynamic>;
            final type = data['related_type'];
            final id = data['related_id'];
            if (type == 'task') {
              Get.toNamed('/task-detail', arguments: {'id': id});
            } else if (type == 'case') {
              Get.toNamed('/case-detail', arguments: {'id': id});
            }
          } catch (_) {}
        }
      },
    );

    // Request permissions on Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // ─── Show local OS notification ───────────────────────────────────────────
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'lawyer_channel',
      'Lawyer Office Reminders',
      channelDescription: 'Task and case reminders',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(''),
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _plugin.show(id, title, body, details, payload: payload);
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) return;

    const androidDetails = AndroidNotificationDetails(
      'lawyer_channel',
      'Lawyer Office Reminders',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  // ─── Daily 8:00 AM Morning Update ─────────────────────────────────────────
  static Future<void> scheduleDailyTaskReminder(List<TaskModel> tasks) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, 8, 0);
    
    // If it's already past 8 AM today, schedule for tomorrow
    if (now.hour >= 8) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final tasksToday = tasks.where((t) {
      if (t.dueDate == null || t.status == 'completed') return false;
      try {
        final d = DateTime.parse(t.dueDate!).toLocal();
        return d.year == now.year && d.month == now.month && d.day == now.day;
      } catch (_) {
        return false;
      }
    }).toList();

    if (tasksToday.isEmpty) return;

    final body = 'You have ${tasksToday.length} tasks scheduled for today. / لديك ${tasksToday.length} مهام اليوم.';

    await _plugin.zonedSchedule(
      888, // Unique ID for daily reminder
      'Morning Update / تحديث الصباح',
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder_channel',
          'Daily Reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat every day at this time
    );
  }

  // ─── In-app notification store ────────────────────────────────────────────
  static List<NotificationModel> getAll() {
    final raw = StorageService.getNotifications();
    return raw.map((e) => NotificationModel.fromJson(e)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static int getUnreadCount() => getAll().where((n) => !n.isRead).length;

  static Future<void> addNotification({
    required String title,
    required String message,
    required String type,
    int? relatedId,
    String? relatedType,
  }) async {
    final notifications = getAll();
    // Avoid duplicates (same type+relatedId within last 24h)
    final isDuplicate = notifications.any((n) =>
        n.type == type &&
        n.relatedId == relatedId &&
        DateTime.now().difference(n.createdAt).inHours < 24);
    if (isDuplicate) return;

    final notification = NotificationModel(
      id: _uuid.v4(),
      title: title,
      message: message,
      type: type,
      relatedId: relatedId,
      relatedType: relatedType,
      createdAt: DateTime.now(),
    );

    notifications.insert(0, notification);
    // Keep only last 100
    final trimmed = notifications.take(100).toList();
    await StorageService.setNotifications(
        trimmed.map((n) => n.toJson()).toList());

    // Also show OS push notification
    await showNotification(
      id: relatedId ?? DateTime.now().millisecondsSinceEpoch % 100000,
      title: title,
      body: message,
      payload: jsonEncode({
        'related_type': relatedType,
        'related_id': relatedId,
      }),
    );
  }

  static Future<void> markAsRead(String id) async {
    final notifications = getAll();
    final idx = notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      notifications[idx].isRead = true;
      await StorageService.setNotifications(
          notifications.map((n) => n.toJson()).toList());
    }
  }

  static Future<void> markAllAsRead() async {
    final notifications = getAll();
    for (var n in notifications) {
      n.isRead = true;
    }
    await StorageService.setNotifications(
        notifications.map((n) => n.toJson()).toList());
  }

  static Future<void> deleteNotification(String id) async {
    final notifications = getAll().where((n) => n.id != id).toList();
    await StorageService.setNotifications(
        notifications.map((n) => n.toJson()).toList());
  }

  static Future<void> clearAll() async {
    await StorageService.setNotifications([]);
  }
}
