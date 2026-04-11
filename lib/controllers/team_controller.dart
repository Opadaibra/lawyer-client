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
    fetchTeamMembers();
  }

  Future<void> fetchTeamMembers() async {
    isLoading.value = true;
    try {
      final response = await _api.getList(AppConstants.team);
      if (response is Map && response['data'] is List) {
        members.value = List<Map<String, dynamic>>.from(response['data']);
      } else if (response is List) {
        members.value = List<Map<String, dynamic>>.from(response);
      }
    } catch (e) {
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addMember(Map<String, dynamic> data) async {
    final u = Get.find<AuthController>().currentUser.value;
    if (u?.canMutateOfficeContent != true) {
      Get.snackbar('error'.tr, 'viewer_no_edit_permission'.tr,
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }
    isSubmitting.value = true;
    try {
      await _api.post(AppConstants.team, data: data);
      await fetchTeamMembers();
      _showSuccess('done'.tr);
      return true;
    } catch (e) {
      _showError(e);
      return false;
    } finally {
      isSubmitting.value = false;
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
