import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/dashboard_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../app/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import 'package:table_calendar/table_calendar.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const List<String> syrianMonths = [
    'كانون الثاني', 'شباط', 'آذار', 'نيسان', 'أيار', 'حزيران',
    'تموز', 'آب', 'أيلول', 'تشرين الأول', 'تشرين الثاني', 'كانون الأول'
  ];

  @override
  Widget build(BuildContext context) {
    final dash = Get.put(DashboardController());
    final auth = Get.find<AuthController>();

    return RefreshIndicator(
      onRefresh: () => dash.refreshDashboard(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Welcome
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'welcome_back'.tr,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Obx(() => Text(
                      auth.userName,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    )),
              ],
            ),
            const SizedBox(height: 20),

            // Calendar Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month, color: AppTheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'calendar'.tr,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Obx(() => TableCalendar(
                      locale: 'ar',
                      firstDay: DateTime.utc(2024, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: dash.focusedDay.value,
                      selectedDayPredicate: (day) => isSameDay(dash.selectedDay.value, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        dash.selectedDay.value = selectedDay;
                        dash.focusedDay.value = focusedDay;
                      },
                      eventLoader: (day) => dash.filterTasksByDate(day),
                      calendarFormat: CalendarFormat.month,
                      rowHeight: 46,
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: true,
                        cellMargin: const EdgeInsets.all(4),
                        todayDecoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.2), shape: BoxShape.circle),
                        selectedDecoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                        markerDecoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextFormatter: (date, locale) {
                          return '${date.month} - ${syrianMonths[date.month - 1]}';
                        },
                      ),
                    )),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Statistics Section
            Obx(() => GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.0,
                  children: [
                    _CompactStatCard(
                      title: 'cases'.tr,
                      value: dash.totalCases.value.toString(),
                      icon: Icons.folder,
                      color: Colors.blue,
                      onTap: () => Get.toNamed(AppRoutes.cases),
                    ),
                    _CompactStatCard(
                      title: 'tasks'.tr,
                      value: dash.pendingTasks.value.toString(),
                      icon: Icons.assignment,
                      color: Colors.purple,
                      onTap: () => Get.toNamed(AppRoutes.tasks),
                    ),
                    _CompactStatCard(
                      title: 'sessions'.tr,
                      value: dash.totalSessions.value.toString(),
                      icon: Icons.calendar_today,
                      color: Colors.red,
                      onTap: () => Get.toNamed(AppRoutes.allSessions),
                    ),
                  ],
                )),

            const SizedBox(height: 24),

            // Tasks section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'tasks_for_day'.tr,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => Get.toNamed(AppRoutes.tasks),
                  child: Text('view_all'.tr),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Obx(() {
              final filteredTasks = dash.filterTasksByDate(dash.selectedDay.value);
              if (filteredTasks.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.event_available, size: 48, color: Colors.grey.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text('no_tasks_for_selected_day'.tr, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredTasks.length,
                itemBuilder: (context, index) {
                  final task = filteredTasks[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      onTap: () => Get.toNamed(AppRoutes.taskDetail, arguments: {'task': task}),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.assignment_outlined, color: AppTheme.accent),
                      ),
                      title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(task.caseNumber ?? 'task'.tr, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: dash.getStatusColor(task.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          task.status.tr,
                          style: TextStyle(color: dash.getStatusColor(task.status), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _CompactStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CompactStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
          ],
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
