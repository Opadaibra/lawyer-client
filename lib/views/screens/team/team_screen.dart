import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/team_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';

class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(TeamController());
    final auth = Get.find<AuthController>();

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'فريق العمل',
        showNotification: false,
      ),
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (ctrl.members.isEmpty) {
          return const Center(child: Text('لا يوجد أعضاء في الفريق حالياً'));
        }

        return RefreshIndicator(
          onRefresh: () => ctrl.fetchMembers(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ctrl.members.length,
            itemBuilder: (context, index) {
              final member = ctrl.members[index];
              final String roleKey = (member['role']?.toString() ?? '').toLowerCase() + '_role';
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    child: const Icon(Icons.person, color: AppTheme.primary),
                  ),
                  title: Text(member['name']?.toString() ?? 'بدون اسم',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${member['email']}\nالصفة: ${roleKey.tr}'),
                  trailing:
                      (auth.currentUser.value?.id != member['id'] && 
                       auth.currentUser.value?.role == 'MANAGER')
                          ? IconButton(
                              icon: const Icon(Icons.person_remove_outlined,
                                  color: Colors.redAccent),
                              onPressed: () => _confirmRemove(ctrl, member['id']),
                            )
                          : null,
                ),
              );
            },
          ),
        );
      }),
      floatingActionButton: Obx(() {
        final user = auth.currentUser.value;
        if (user?.role != 'MANAGER') return const SizedBox();
        return FloatingActionButton(
          heroTag: 'team_fab',
          onPressed: () => _showAddMemberDialog(context, ctrl),
          backgroundColor: AppTheme.primary,
          child: const Icon(Icons.add),
        );
      }),
    );
  }

  void _showAddMemberDialog(BuildContext context, TeamController ctrl) {
    final email = TextEditingController();
    final role = 'LAWYER'.obs;

    Get.dialog(
      AlertDialog(
        title: const Text('إضافة عضو للفريق'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: email,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                hintText: 'user@example.com',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            Obx(() => DropdownButtonFormField<String>(
                  value: role.value,
                  decoration: const InputDecoration(labelText: 'الدور'),
                  items: [
                    DropdownMenuItem(value: 'MANAGER', child: Text('manager_role'.tr)),
                    DropdownMenuItem(value: 'LAWYER', child: Text('lawyer_role'.tr)),
                    DropdownMenuItem(value: 'CLIENT', child: Text('client_role'.tr)),
                  ],
                  onChanged: (v) => role.value = v!,
                )),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (email.text.isNotEmpty) {
                Get.back();
                ctrl.addMember(email.text.trim(), role.value);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _confirmRemove(TeamController ctrl, dynamic id) {
    if (id == null) return;
    Get.dialog(
      AlertDialog(
        title: const Text('حذف عضو'),
        content: const Text('هل أنت متأكد من حذف هذا العضو من الفريق؟'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              ctrl.removeMember(int.parse(id.toString()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
