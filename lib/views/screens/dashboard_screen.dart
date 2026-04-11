import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/dashboard_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../app/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/stat_card.dart';
import 'package:table_calendar/table_calendar.dart';
class DashboardScreen extends StatelessWidget {
  final bool isNested;
  const DashboardScreen({super.key, this.isNested = false});

  @override
  Widget build(BuildContext context) {
    final dash = Get.find<DashboardController>();
    final auth = Get.find<AuthController>();

    return Scaffold(
      appBar: isNested 
        ? null 
        : CustomAppBar(
            title: 'dashboard'.tr,
            showBack: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => Get.toNamed(AppRoutes.search),
              ),
            ],
          ),
      drawer: isNested ? null : _buildDrawer(context, auth),
      body: Obx(() {
        if (dash.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: dash.loadDashboard,
          child: CustomScrollView(
            slivers: [
              // Welcome section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_getGreeting()}, ${auth.userName}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'dashboard_subtitle'.tr,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),

              // Calendar Section
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Obx(() => TableCalendar(
                        firstDay: DateTime.utc(2024, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: dash.focusedDay.value,
                        selectedDayPredicate: (day) =>
                            isSameDay(dash.selectedDay.value, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          dash.selectedDay.value = selectedDay;
                          dash.focusedDay.value = focusedDay;
                        },
                        eventLoader: (day) => dash.filterTasksByDate(day),
                        calendarFormat: CalendarFormat.month,
                        rowHeight: 52,
                        calendarStyle: CalendarStyle(
                          outsideDaysVisible: true,
                          cellMargin: const EdgeInsets.all(4),
                          todayDecoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          markerDecoration: const BoxDecoration(
                            color: AppTheme.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                        ),
                      )),
                ),
              ),

              // Stats Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'cases'.tr,
                          value: dash.totalCases.value.toString(),
                          icon: Icons.folder_outlined,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: 'sessions'.tr,
                          value: dash.totalSessions.value.toString(),
                          icon: Icons.gavel_outlined,
                          color: AppTheme.accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: 'tasks'.tr,
                          value: dash.allTasks.length.toString(),
                          icon: Icons.task_alt_outlined,
                          color: AppTheme.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Sections
              _buildSectionTitle(context, 'notifications'.tr),
              SliverToBoxAdapter(
                child: Center(
                    child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('no_notifications'.tr,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                )),
              ),

              _buildSectionTitle(context, 'important'.tr),
              SliverToBoxAdapter(
                child: Center(
                    child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('no_important_items'.tr,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                )),
              ),

              _buildSectionTitle(context, 'cases'.tr,
                  onSeeAll: () => Get.toNamed(AppRoutes.cases)),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final c = dash.recentCases[i];
                    return ListTile(
                      leading:
                          const Icon(Icons.folder_outlined, color: AppTheme.primary),
                      title: Text(c['case_number'] ?? ''),
                      subtitle: Text(c['subject'] ?? ''),
                      onTap: () =>
                          Get.toNamed(AppRoutes.caseDetail, arguments: {'id': c['id']}),
                    );
                  },
                  childCount: dash.recentCases.length,
                ),
              ),

              _buildSectionTitle(context, 'minutes'.tr,
                  onSeeAll: () => Get.toNamed(AppRoutes.minutes)),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final m = dash.recentMinutes[i];
                    return ListTile(
                      leading: const Icon(Icons.article_outlined,
                          color: AppTheme.accent),
                      title: Text(m['minute_number'] ?? m['date'] ?? ''),
                      subtitle: Text(m['department'] ?? ''),
                      onTap: () {},
                    );
                  },
                  childCount: dash.recentMinutes.length,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      }),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'good_morning'.tr;
    return 'good_evening'.tr;
  }

  Widget _buildSectionTitle(BuildContext context, String title,
      {VoidCallback? onSeeAll}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (onSeeAll != null)
              TextButton(onPressed: onSeeAll, child: Text('see_all'.tr)),
          ],
        ),
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context, AuthController auth) {
    // Legacy drawer (not used in main nav)
    return const Drawer();
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;

  const _DrawerItem(this.icon, this.label, this.route);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(label),
      onTap: () {
        Get.back();
        Get.toNamed(route);
      },
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      onTap: (i) {
        switch (i) {
          case 0:
            Get.offAllNamed(AppRoutes.dashboard);
            break;
          case 1:
            Get.toNamed(AppRoutes.clients);
            break;
          case 2:
            Get.toNamed(AppRoutes.cases);
            break;
          case 3:
            Get.toNamed(AppRoutes.tasks);
            break;
          case 4:
            Get.toNamed(AppRoutes.profile);
            break;
        }
      },
      items: [
        BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_outlined), label: 'dashboard'.tr),
        BottomNavigationBarItem(
            icon: const Icon(Icons.people_outline), label: 'clients'.tr),
        BottomNavigationBarItem(
            icon: const Icon(Icons.folder_outlined), label: 'cases'.tr),
        BottomNavigationBarItem(
            icon: const Icon(Icons.task_outlined), label: 'tasks'.tr),
        BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline), label: 'profile'.tr),
      ],
    );
  }
}
