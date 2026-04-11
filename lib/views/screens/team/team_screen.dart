import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/team_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/loading_widget.dart';

class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

  static String _roleLabel(dynamic raw) {
    final r = raw?.toString().toUpperCase() ?? '';
    switch (r) {
      case 'MANAGER':
        return 'manager_role'.tr;
      case 'LAWYER':
        return 'lawyer_role'.tr;
      case 'EDITOR':
        return 'editor_role'.tr;
      case 'VIEWER':
        return 'viewer_role'.tr;
      case 'CLIENT':
        return 'client_role'.tr;
      default:
        return r.isEmpty ? '—' : r;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<TeamController>();
    final auth = Get.find<AuthController>();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'team'.tr,
      ),
      body: Obx(() {
        if (ctrl.isLoading.value) return const LoadingWidget();
        
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: ctrl.members.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (ctx, i) {
                  final member = ctrl.members[i];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primary.withOpacity(0.1),
                        child: Text(member['name']?[0]?.toUpperCase() ?? 'U', 
                          style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(member['name'] ?? ''),
                      subtitle: Text(member['email'] ?? ''),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _roleLabel(member['role']),
                          style: const TextStyle(color: AppTheme.accent, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
      floatingActionButton: Obx(() {
        if (auth.currentUser.value?.canMutateOfficeContent != true) {
          return const SizedBox.shrink();
        }
        return FloatingActionButton.extended(
          onPressed: () => _showAddMemberDialog(context, ctrl),
          icon: const Icon(Icons.person_add_outlined),
          label: Text('add_member'.tr),
        );
      }),
    );
  }

  void _showAddMemberDialog(BuildContext context, TeamController ctrl) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final role = 'LAWYER'.obs;

    Get.dialog(
      AlertDialog(
        title: Text('add_member'.tr),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(labelText: 'name'.tr),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                decoration: InputDecoration(labelText: 'email'.tr),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordCtrl,
                decoration: InputDecoration(labelText: 'password'.tr),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              Obx(() => DropdownButtonFormField<String>(
                value: role.value,
                decoration: InputDecoration(labelText: 'role'.tr),
                items: [
                  DropdownMenuItem(value: 'MANAGER', child: Text('manager_role'.tr)),
                  DropdownMenuItem(value: 'LAWYER', child: Text('lawyer_role'.tr)),
                  DropdownMenuItem(value: 'EDITOR', child: Text('editor_role'.tr)),
                  DropdownMenuItem(value: 'VIEWER', child: Text('viewer_role'.tr)),
                ],
                onChanged: (v) => role.value = v!,
              )),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: Text('cancel'.tr)),
          Obx(() => ElevatedButton(
            onPressed: ctrl.isSubmitting.value ? null : () async {
              final success = await ctrl.addMember({
                'name': nameCtrl.text,
                'email': emailCtrl.text,
                'password': passwordCtrl.text,
                'role': role.value,
              });
              if (success) Get.back();
            },
            child: ctrl.isSubmitting.value 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('add'.tr),
          )),
        ],
      ),
    );
  }
}
