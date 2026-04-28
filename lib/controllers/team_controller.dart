import 'package:get/get.dart';
import '../data/services/api_service.dart';
import '../core/constants/app_constants.dart';
import 'auth_controller.dart';

class TeamController extends GetxController {
  final ApiService _api = ApiService();
  
  final members = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final isSubmitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchMembers();
  }

  Future<void> fetchMembers() async {
    isLoading.value = true;
    try {
      final response = await _api.getList(AppConstants.team);
      List<Map<String, dynamic>> list = [];
      if (response is Map && response['data'] is List) {
        list = List<Map<String, dynamic>>.from(response['data']);
      } else if (response is List) {
        list = List<Map<String, dynamic>>.from(response);
      }
      // إظهار الجميع بما فيهم الـ CLIENT حسب الطلب الجديد
      members.value = list;
    } catch (e) {
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addMember(String email, String role) async {
    final u = Get.find<AuthController>().currentUser.value;
    if (u?.canMutateOfficeContent != true) {
      Get.snackbar('error'.tr, 'viewer_no_edit_permission'.tr,
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }
    isSubmitting.value = true;
    try {
      await _api.post(AppConstants.team, data: {
        'email': email,
        'role': role,
      });
      await fetchMembers();
      _showSuccess('done'.tr);
      return true;
    } catch (e) {
      _showError(e);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> removeMember(int id) async {
    try {
      await _api.delete('${AppConstants.team}/$id');
      await fetchMembers();
      _showSuccess('done'.tr);
      return true;
    } catch (e) {
      _showError(e);
      return false;
    }
  }

  void _showError(dynamic e) {
    Get.snackbar('error'.tr, e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM);
  }

  void _showSuccess(String msg) {
    Get.snackbar('success'.tr, msg, snackPosition: SnackPosition.BOTTOM);
  }
}
