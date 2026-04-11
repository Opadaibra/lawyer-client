import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/services/api_service.dart';
import '../../data/models/file_model.dart';
import '../../core/constants/app_constants.dart';

class FileController extends GetxController {
  final ApiService _api = ApiService();

  final files = <FileModel>[].obs;
  final isLoading = false.obs;
  final isUploading = false.obs;
  final uploadProgress = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchFiles();
  }

  Future<void> fetchFiles() async {
    isLoading.value = true;
    try {
      final response = await _api.getList(AppConstants.files);
      final list = _parseList(response);
      files.value = list.map((e) => FileModel.fromJson(e)).toList();
    } catch (e) {
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchFilesByCase(int caseId) async {
    isLoading.value = true;
    try {
      final response = await _api.getList('/files/by-case/$caseId');
      final list = _parseList(response);
      files.value = list.map((e) => FileModel.fromJson(e)).toList();
    } catch (e) {
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchFilesByMinute(int minuteId) async {
    isLoading.value = true;
    try {
      final response = await _api.getList('/files/by-minute/$minuteId');
      final list = _parseList(response);
      files.value = list.map((e) => FileModel.fromJson(e)).toList();
    } catch (e) {
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> pickAndUpload({
    Map<String, String>? extraFields,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
      );

      if (result == null || result.files.isEmpty) return false;

      final file = result.files.first;
      if (file.path == null) {
        _showError(Exception('No file path available'));
        return false;
      }

      isUploading.value = true;
      final response = await _api.uploadFile(
        filePath: file.path!,
        fileName: file.name,
        fields: extraFields,
      );

      final data = (response['data'] as Map<String, dynamic>?) ?? response;
      if (data.isNotEmpty) {
        files.insert(0, FileModel.fromJson(data));
      }
      _showSuccess('File uploaded / تم رفع الملف');
      return true;
    } catch (e) {
      _showError(e);
      return false;
    } finally {
      isUploading.value = false;
    }
  }

  Future<bool> deleteFile(int id) async {
    try {
      await _api.delete('${AppConstants.files}/$id');
      files.removeWhere((f) => f.id == id);
      _showSuccess('File deleted / تم حذف الملف');
      return true;
    } catch (e) {
      _showError(e);
      return false;
    }
  }

  List<dynamic> _parseList(dynamic response) {
    if (response is List) return response;
    if (response is Map) {
      return response['data'] as List? ?? response['files'] as List? ?? [];
    }
    return [];
  }

  void _showError(dynamic e) {
    Get.snackbar('Error / خطأ',
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM);
  }

  void _showSuccess(String msg) {
    Get.snackbar('Success / نجاح', msg, snackPosition: SnackPosition.BOTTOM);
  }
}
