import 'package:get/get.dart';
import '../../data/services/api_service.dart';
import '../../data/models/case_model.dart';
import '../../data/models/sub_resource_models.dart';
import '../../core/constants/app_constants.dart';

class CaseController extends GetxController {
  final ApiService _api = ApiService();

  final cases = <CaseModel>[].obs;
  final selectedCase = Rx<CaseModel?>(null);
  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final filterStatus = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCases();
  }

  // ─── Fetch all cases ──────────────────────────────────────────────────────
  Future<void> fetchCases() async {
    isLoading.value = true;
    try {
      final response = await _api.getList('${AppConstants.cases}/');
      final list = _parseList(response);
      cases.value = list.map((e) => CaseModel.fromJson(e)).toList();
    } catch (e) {
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Get case by ID ───────────────────────────────────────────────────────
  Future<void> fetchCaseById(int id) async {
    isLoading.value = true;
    try {
      final response = await _api.get('${AppConstants.cases}/$id');
      final data = _extractData(response);
      selectedCase.value = CaseModel.fromJson(data);
    } catch (e) {
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Filtered cases ───────────────────────────────────────────────────────
  List<CaseModel> get filteredCases {
    if (filterStatus.value.isEmpty) return cases;
    return cases
        .where((c) => c.status == filterStatus.value)
        .toList();
  }

  // ─── Create case ──────────────────────────────────────────────────────────
  Future<bool> createCase(CaseModel caseModel, {int? fileId}) async {
    isSubmitting.value = true;
    try {
      final response = await _api.post('${AppConstants.cases}/', data: caseModel.toCreateJson());
      
      if (fileId != null) {
        final newCaseId = response['case']?['id'] ?? response['data']?['id'];
        if (newCaseId != null) {
          await _api.post('/files/attach', data: {
            'file_id': fileId,
            'case_id': newCaseId
          });
        }
      }

      await fetchCases();
      Get.back();
      _showSuccess('Case created / تم إنشاء القضية');
      return true;
    } catch (e) {
      _showError(e);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // ─── Update case ──────────────────────────────────────────────────────────
  Future<bool> updateCase(int id, CaseModel caseModel) async {
    isSubmitting.value = true;
    try {
      await _api.patch(
          '${AppConstants.cases}/$id', caseModel.toCreateJson());
      await fetchCases();
      Get.back();
      _showSuccess('Case updated / تم تحديث القضية');
      return true;
    } catch (e) {
      _showError(e);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // ─── Delete case ──────────────────────────────────────────────────────────
  Future<bool> deleteCase(int id) async {
    try {
      await _api.delete('${AppConstants.cases}/$id');
      cases.removeWhere((c) => c.id == id);
      _showSuccess('Case deleted / تم حذف القضية');
      return true;
    } catch (e) {
      _showError(e);
      return false;
    }
  }

  // ─── Archive/Unarchive ────────────────────────────────────────────────────
  Future<void> archiveCase(int id) async {
    try {
      await _api.post('${AppConstants.cases}/$id/archive');
      await fetchCases();
      _showSuccess('Case archived / تم أرشفة القضية');
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> unarchiveCase(int id) async {
    try {
      await _api.post('${AppConstants.cases}/$id/unarchive');
      await fetchCases();
      _showSuccess('Case unarchived / تم إلغاء أرشفة القضية');
    } catch (e) {
      _showError(e);
    }
  }

  // ─── Sub-resources ────────────────────────────────────────────────────────

  // Sessions
  Future<void> fetchSessions(int caseId) async {
    try {
      final response = await _api.getList('${AppConstants.cases}/$caseId/sessions');
      final list = _parseList(response);
      final listModels = list.map((e) => SessionModel.fromJson(e)).toList();
      if (selectedCase.value?.id == caseId) {
        selectedCase.value = selectedCase.value!.copyWith(sessions: listModels);
      }
    } catch (e) {
      _showError(e);
    }
  }

  Future<bool> addSession(int caseId, Map<String, dynamic> data) async {
    try {
      await _api.post('${AppConstants.cases}/$caseId/sessions', data: data);
      await fetchSessions(caseId);
      return true;
    } catch (e) {
      _showError(e);
      return false;
    }
  }

  Future<void> deleteSession(int id, int caseId) async {
    try {
      await _api.delete('/sessions/$id');
      await fetchSessions(caseId);
      _showSuccess('Session deleted / تم حذف الجلسة');
    } catch (e) {
      _showError(e);
    }
  }

  // Notes
  Future<void> fetchNotes(int caseId) async {
    try {
      final response = await _api.getList('${AppConstants.cases}/$caseId/notes');
      final list = _parseList(response);
      final listModels = list.map((e) => CaseNoteModel.fromJson(e)).toList();
      if (selectedCase.value?.id == caseId) {
        selectedCase.value = selectedCase.value!.copyWith(caseNotes: listModels);
      }
    } catch (e) {
      _showError(e);
    }
  }

  Future<bool> addNote(int caseId, Map<String, dynamic> data) async {
    try {
      await _api.post('${AppConstants.cases}/$caseId/notes', data: data);
      await fetchNotes(caseId);
      return true;
    } catch (e) {
      _showError(e);
      return false;
    }
  }

  Future<void> deleteNote(int id, int caseId) async {
    try {
      await _api.delete('/notes/$id');
      await fetchNotes(caseId);
      _showSuccess('Note deleted / تم حذف الملاحظة');
    } catch (e) {
      _showError(e);
    }
  }

  // Expenses
  Future<void> fetchExpenses(int caseId) async {
    try {
      final response = await _api.getList('${AppConstants.cases}/$caseId/expenses');
      final list = _parseList(response);
      final listModels = list.map((e) => ExpenseModel.fromJson(e)).toList();
      if (selectedCase.value?.id == caseId) {
        selectedCase.value = selectedCase.value!.copyWith(expenses: listModels);
      }
    } catch (e) {
      _showError(e);
    }
  }

  Future<bool> addExpense(int caseId, Map<String, dynamic> data) async {
    try {
      await _api.post('${AppConstants.cases}/$caseId/expenses', data: data);
      await fetchExpenses(caseId);
      return true;
    } catch (e) {
      _showError(e);
      return false;
    }
  }

  Future<void> deleteExpense(int id, int caseId) async {
    try {
      await _api.delete('/expenses/$id');
      await fetchExpenses(caseId);
      _showSuccess('Expense deleted / تم حذف المصروف');
    } catch (e) {
      _showError(e);
    }
  }

  // Fees
  Future<void> fetchFees(int caseId) async {
    try {
      final response = await _api.getList('${AppConstants.cases}/$caseId/fees');
      final list = _parseList(response);
      final listModels = list.map((e) => FeeModel.fromJson(e)).toList();
      if (selectedCase.value?.id == caseId) {
        selectedCase.value = selectedCase.value!.copyWith(fees: listModels);
      }
    } catch (e) {
      _showError(e);
    }
  }

  Future<bool> addFee(int caseId, Map<String, dynamic> data) async {
    try {
      await _api.post('${AppConstants.cases}/$caseId/fees', data: data);
      await fetchFees(caseId);
      return true;
    } catch (e) {
      _showError(e);
      return false;
    }
  }

  Future<void> deleteFee(int id, int caseId) async {
    try {
      await _api.delete('/fees/$id');
      await fetchFees(caseId);
      _showSuccess('Fee record deleted / تم حذف السجل');
    } catch (e) {
      _showError(e);
    }
  }

  // Star Toggle
  Future<void> toggleStar(int id) async {
    try {
      await _api.post('${AppConstants.cases}/$id/star');
      if (selectedCase.value?.id == id) {
        await fetchCaseById(id);
      }
      await fetchCases();
    } catch (e) {
      _showError(e);
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  List<dynamic> _parseList(dynamic response) {
    if (response is List) return response;
    if (response is Map) {
      return response['data'] as List? ?? response['cases'] as List? ?? [];
    }
    return [];
  }

  Map<String, dynamic> _extractData(Map<String, dynamic> response) {
    return (response['data'] as Map<String, dynamic>?) ?? response;
  }

  void _showError(dynamic e) {
    Get.snackbar('Error / خطأ',
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM);
  }

  void _showSuccess(String msg) {
    Get.snackbar('Success / نجاح', msg,
        snackPosition: SnackPosition.BOTTOM);
  }
}
