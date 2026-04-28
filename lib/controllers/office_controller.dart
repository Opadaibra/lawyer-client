import 'package:get/get.dart';
import '../data/services/api_service.dart';
import '../core/constants/app_constants.dart';

class OfficeModel {
  final int id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? description;

  OfficeModel({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.description,
  });

  factory OfficeModel.fromJson(Map<String, dynamic> json) => OfficeModel(
        id: json['id'] as int? ?? 0,
        name: json['name']?.toString() ?? '',
        phone: json['phone']?.toString(),
        email: json['email']?.toString(),
        address: json['address']?.toString(),
        description: json['description']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'description': description,
      };
}

class OfficeController extends GetxController {
  final ApiService _api = ApiService();

  final office = Rx<OfficeModel?>(null);
  final isLoading = false.obs;
  final isUpdating = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchOffice();
  }

  Future<void> fetchOffice() async {
    isLoading.value = true;
    try {
      final response = await _api.get(AppConstants.offices);
      // السيرفر قد يعيد كائن مباشرة أو مصفوفة
      final data = response['data'] ?? response;
      if (data != null) {
        office.value = OfficeModel.fromJson(data);
      }
    } catch (e) {
      print('Fetch office error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateOffice({
    required String name,
    String? phone,
    String? email,
    String? address,
    String? description,
  }) async {
    isUpdating.value = true;
    try {
      final response = await _api.patch(AppConstants.offices, {
        'name': name,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (address != null) 'address': address,
        if (description != null) 'description': description,
      });
      final data = response['data'] ?? response;
      office.value = OfficeModel.fromJson(data);
      Get.snackbar('success'.tr, 'تم تحديث البيانات بنجاح');
      return true;
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
      return false;
    } finally {
      isUpdating.value = false;
    }
  }
}
