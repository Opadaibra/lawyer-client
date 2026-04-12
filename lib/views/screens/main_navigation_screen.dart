import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/main_navigation_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../app/routes/app_routes.dart';
import '../../controllers/case_controller.dart';
import '../../controllers/client_controller.dart';
import '../../controllers/notification_controller.dart';
import '../../core/theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'tasks/tasks_screen.dart';

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MainNavigationController());
    final auth = Get.find<AuthController>();
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    final List<Widget> pages = [
      const SizedBox.shrink(), // Placeholder for Menu button
      const DashboardScreen(isNested: true),
      const TasksScreen(isNested: true),
      const StarredScreen(),
    ];

    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: Text('app_name'.tr,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          Obx(() {
            final notifCtrl = Get.find<NotificationController>();
            final count = notifCtrl.unreadCount.value;
            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  tooltip: 'notifications'.tr,
                  onPressed: () => Get.toNamed(AppRoutes.notifications),
                ),
                if (count > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        count > 99 ? '99+' : count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          }),
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.2),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  Get.toNamed(AppRoutes.profile);
                  break;
                case 'office':
                  Get.toNamed(AppRoutes.officeInfo);
                  break;
                case 'logout':
                  auth.logout();
                  break;
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(children: [
                  const Icon(Icons.person_outline, size: 18),
                  const SizedBox(width: 8),
                  Text('profile'.tr),
                ]),
              ),
              PopupMenuItem(
                value: 'office',
                child: Row(children: [
                  const Icon(Icons.business_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text('office_info'.tr),
                ]),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(children: [
                  const Icon(Icons.logout, size: 18, color: Colors.red),
                  const SizedBox(width: 8),
                  Text('logout'.tr, style: const TextStyle(color: Colors.red)),
                ]),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: AppDrawer(auth: auth, nav: controller),
      body: Obx(() => IndexedStack(
            index: controller.currentIndex.value,
            children: pages,
          )),
      bottomNavigationBar: Obx(() => BottomNavigationBar(
            currentIndex: controller.currentIndex.value,
            onTap: (index) {
              if (index == 0) {
                scaffoldKey.currentState?.openDrawer();
              } else {
                controller.changeIndex(index);
              }
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppTheme.primary,
            unselectedItemColor: Colors.grey,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.menu),
                label: 'menu'.tr,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.home_outlined),
                label: 'home'.tr,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.task_outlined),
                label: 'tasks'.tr,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.star_outline),
                label: 'featured'.tr,
              ),
            ],
          )),
    );
  }
}

class AppDrawer extends StatelessWidget {
  final AuthController auth;
  final MainNavigationController nav;

  const AppDrawer({super.key, required this.auth, required this.nav});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppTheme.primary),
            accountName: Text(auth.userName),
            accountEmail: Text(auth.userEmail),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white, size: 40),
            ),
          ),
          _DrawerTile(
            icon: Icons.calendar_today_outlined,
            label: 'calendar'.tr,
            onTap: () {
              Get.back();
              nav.openSystemCalendar();
            },
          ),
          _DrawerTile(
            icon: Icons.people_outline,
            label: 'clients'.tr,
            onTap: () {
              Get.back();
              Get.toNamed(AppRoutes.clients);
            },
          ),
          _DrawerTile(
            icon: Icons.attach_file_outlined,
            label: 'files'.tr,
            onTap: () {
              Get.back();
              Get.toNamed(AppRoutes.files);
            },
          ),
          _DrawerTile(
            icon: Icons.folder_outlined,
            label: 'cases'.tr,
            onTap: () {
              Get.back();
              Get.toNamed(AppRoutes.cases);
            },
          ),
          _DrawerTile(
            icon: Icons.article_outlined,
            label: 'minutes'.tr,
            onTap: () {
              Get.back();
              Get.toNamed(AppRoutes.minutes);
            },
          ),
          _DrawerTile(
            icon: Icons.archive_outlined,
            label: 'archive'.tr,
            onTap: () {
              Get.back();
              Get.toNamed(AppRoutes.archive);
            },
          ),
          _DrawerTile(
            icon: Icons.notifications_none,
            label: 'notifications'.tr,
            onTap: () {
              Get.back();
              Get.toNamed(AppRoutes.notifications);
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: Text('logout'.tr, style: const TextStyle(color: Colors.redAccent)),
            onTap: () => auth.logout(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(label),
      onTap: onTap,
    );
  }
}

class StarredScreen extends StatelessWidget {
  const StarredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final caseCtrl = Get.find<CaseController>();
    final clientCtrl = Get.find<ClientController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('featured'.tr),
        centerTitle: true,
      ),
      body: Obx(() {
        final starredCases = caseCtrl.cases.where((c) => c.isStarred).toList();
        final starredClients = clientCtrl.clients.where((c) => c.isStarred).toList();

        if (starredCases.isEmpty && starredClients.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_border, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('no_featured_items'.tr, style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (starredCases.isNotEmpty) ...[
              _buildSectionHeader('cases'.tr),
              const SizedBox(height: 8),
              ...starredCases.map((c) => _buildFeaturedTile(
                    context,
                    title: c.caseNumber,
                    subtitle: c.subject ?? '',
                    icon: Icons.folder_outlined,
                    onTap: () => Get.toNamed(AppRoutes.caseDetail, arguments: {'case': c}),
                  )),
              const SizedBox(height: 16),
            ],
            if (starredClients.isNotEmpty) ...[
              _buildSectionHeader('clients'.tr),
              const SizedBox(height: 8),
              ...starredClients.map((c) => _buildFeaturedTile(
                    context,
                    title: c.name,
                    subtitle: c.phone ?? '',
                    icon: Icons.person_outline,
                    onTap: () => Get.toNamed(AppRoutes.clientDetail, arguments: {'client': c}),
                  )),
            ],
          ],
        );
      }),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
    );
  }

  Widget _buildFeaturedTile(BuildContext context, {required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withOpacity(0.1),
          child: Icon(icon, color: AppTheme.primary, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
