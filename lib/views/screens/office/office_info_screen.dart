import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../data/services/api_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';

class OfficeInfoScreen extends StatefulWidget {
  const OfficeInfoScreen({super.key});

  @override
  State<OfficeInfoScreen> createState() => _OfficeInfoScreenState();
}

class _OfficeInfoScreenState extends State<OfficeInfoScreen> {
  final ApiService _api = ApiService();
  final auth = Get.find<AuthController>();

  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  final isLoading = false.obs;
  final isSaving = false.obs;
  Map<String, dynamic>? officeData;

  @override
  void initState() {
    super.initState();
    _loadOfficeData();
  }

  void _loadOfficeData() {
    // تحميل من بيانات اليوزر المحفوظة أولاً
    final user = auth.currentUser.value;
    if (user != null) {
      _nameCtrl.text = user.officeName ?? '';
      _addressCtrl.text = user.officeAddress ?? '';
      _phoneCtrl.text = user.officePhone ?? '';
    }
    _fetchFromServer();
  }

  Map<String, dynamic>? _extractOfficePayload(
      Map<String, dynamic> response, int? userOfficeId) {
    final raw = response['data'] ?? response['office'];
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          final m = Map<String, dynamic>.from(item);
          final oid = m['id'];
          if (userOfficeId != null &&
              oid != null &&
              int.tryParse(oid.toString()) == userOfficeId) {
            return m;
          }
        }
      }
      if (raw.isNotEmpty && raw.first is Map) {
        return Map<String, dynamic>.from(raw.first as Map);
      }
    }
    if (response['name'] != null || response['id'] != null) {
      return Map<String, dynamic>.from(response);
    }
    return null;
  }

  Future<void> _fetchFromServer() async {
    isLoading.value = true;
    try {
      final response = await _api.get(AppConstants.offices);
      final user = auth.currentUser.value;
      final data = _extractOfficePayload(response, user?.officeId);
      if (data != null) {
        officeData = data;
        if (mounted) {
          _nameCtrl.text = data['name']?.toString() ?? _nameCtrl.text;
          _addressCtrl.text = data['address']?.toString() ?? _addressCtrl.text;
          _phoneCtrl.text = data['phone']?.toString() ?? _phoneCtrl.text;
          _emailCtrl.text = data['email']?.toString() ?? _emailCtrl.text;
        }
      }
    } catch (_) {
      // تجاهل الخطأ - نستخدم البيانات المحفوظة
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _save() async {
    if (auth.currentUser.value?.canMutateOfficeContent != true) {
      Get.snackbar('error'.tr, 'viewer_no_edit_permission'.tr,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    isSaving.value = true;
    try {
      final body = {
        'name': _nameCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
      };
      final user = auth.currentUser.value;
      final existingId = officeData?['id'] ?? user?.officeId;
      final id = existingId != null ? int.tryParse(existingId.toString()) : null;

      if (id != null) {
        await _api.patch('${AppConstants.offices}/$id', body);
      } else {
        final res = await _api.post(AppConstants.offices, data: body);
        final next = _extractOfficePayload(res, null);
        if (next != null) officeData = next;
      }
      Get.snackbar('تم', 'تم تحديث معلومات المكتب بنجاح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.success,
          colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ', e.toString().replaceFirst('Exception: ', ''),
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'معلومات المكتب',
        showNotification: false,
      ),
      body: Obx(() {
        if (isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final canMutate =
            auth.currentUser.value?.canMutateOfficeContent ?? true;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // أيقونة المكتب
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.business_outlined,
                      size: 50, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 24),

              // حقول المعلومات
              _buildField(
                controller: _nameCtrl,
                label: 'اسم المكتب',
                icon: Icons.business,
                readOnly: !canMutate,
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _phoneCtrl,
                label: 'رقم الهاتف',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                readOnly: !canMutate,
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _emailCtrl,
                label: 'البريد الإلكتروني',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                readOnly: !canMutate,
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _addressCtrl,
                label: 'عنوان المكتب',
                icon: Icons.location_on_outlined,
                maxLines: 2,
                readOnly: !canMutate,
              ),
              const SizedBox(height: 32),

              // معلومات الفريق
              Obx(() {
                final user = auth.currentUser.value;
                if (user?.officeId == null) return const SizedBox();
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.primary.withOpacity(0.2), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline,
                              size: 16, color: AppTheme.primary),
                          const SizedBox(width: 6),
                          Text('معرّف المكتب: ${user!.officeId}',
                              style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'جميع أعضاء الفريق المنتمون لهذا المكتب يشاركونك نفس البيانات',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),

              // زر الحفظ
              if (canMutate)
                Obx(() => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isSaving.value ? null : _save,
                        icon: isSaving.value
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.save_outlined),
                        label: Text(
                            isSaving.value ? 'جاري الحفظ...' : 'حفظ المعلومات'),
                      ),
                    )),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }
}
