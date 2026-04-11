import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/client_controller.dart';
import '../../../data/models/client_model.dart';
import '../../../core/utils/validators.dart';
import '../../widgets/custom_app_bar.dart';

class ClientFormScreen extends StatefulWidget {
  const ClientFormScreen({super.key});

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _poaCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  ClientModel? _editClient;
  bool get _isEditing => _editClient != null;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    if (args?['client'] != null) {
      _editClient = args!['client'] as ClientModel;
      _nameCtrl.text = _editClient!.name;
      _phoneCtrl.text = _editClient!.phone ?? '';
      _emailCtrl.text = _editClient!.email ?? '';
      _addressCtrl.text = _editClient!.address ?? '';
      _notesCtrl.text = _editClient!.notes ?? '';
      _poaCtrl.text = _editClient!.powerOfAttorneyNumber ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    _poaCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final password = _passwordCtrl.text.trim();
    final client = ClientModel(
      id: _editClient?.id ?? 0,
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
      email: _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : null,
      address:
          _addressCtrl.text.trim().isNotEmpty ? _addressCtrl.text.trim() : null,
      notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
      powerOfAttorneyNumber:
          _poaCtrl.text.trim().isNotEmpty ? _poaCtrl.text.trim() : null,
      password: (!_isEditing && password.isNotEmpty) ? password : null,
    );
    final ctrl = Get.find<ClientController>();
    if (_isEditing) {
      ctrl.updateClient(_editClient!.id, client);
    } else {
      ctrl.createClient(client);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ClientController>();

    return Scaffold(
      appBar: CustomAppBar(
        title: _isEditing ? 'edit_client'.tr : 'add_client'.tr,
        showNotification: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildField(
                controller: _nameCtrl,
                label: 'client_full_name'.tr,
                icon: Icons.person_outlined,
                validator: AppValidators.name,
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _phoneCtrl,
                label: 'phone'.tr,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: AppValidators.phone,
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _emailCtrl,
                label: 'email'.tr,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  // الباك-إند يطلب إيميل دائماً عند الإنشاء
                  if (v == null || v.trim().isEmpty) return 'البريد الإلكتروني مطلوب';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _poaCtrl,
                label: 'power_of_attorney_number'.tr,
                icon: Icons.description_outlined,
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _addressCtrl,
                label: 'address'.tr,
                icon: Icons.location_on_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _notesCtrl,
                label: 'notes'.tr,
                icon: Icons.notes_outlined,
                maxLines: 4,
              ),
              if (!_isEditing) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                // عنوان قسم الحساب
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    'client_account_section'.tr,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _passwordCtrl,
                  label: 'client_password_hint'.tr,
                  icon: Icons.lock_outline,
                  obscureText: true,
                  validator: (v) {
                    if (!_isEditing && (v == null || v.length < 6)) {
                      return 'كلمة المرور مطلوبة ويجب أن تكون 6 أحرف على الأقل';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 24),
              Obx(() => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: ctrl.isSubmitting.value ? null : _submit,
                      child: ctrl.isSubmitting.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Text(_isEditing
                              ? 'update_client'.tr
                              : 'add_client'.tr),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: obscureText ? 1 : maxLines,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        alignLabelWithHint: maxLines > 1 && !obscureText,
      ),
      validator: validator,
    );
  }
}
