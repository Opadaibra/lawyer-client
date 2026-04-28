import 'dart:async';
import 'package:get/get.dart';
import '../../data/services/api_service.dart';
import '../../data/services/storage_service.dart';
import '../../data/models/user_model.dart';
import '../../app/routes/app_routes.dart';
import '../../core/constants/app_constants.dart';
import 'notification_controller.dart';

class AuthController extends GetxController {
  final ApiService _api = ApiService();

  final isLoading = false.obs;
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  @override
  void onInit() {
    super.onInit();
    _loadUserFromStorage();
  }

  void _loadUserFromStorage() {
    final userData = StorageService.getUser();
    if (userData != null) {
      currentUser.value = UserModel.fromJson(userData);
    }
  }

  // ─── Login ────────────────────────────────────────────────────────────────
  Future<void> login(String email, String password) async {
    isLoading.value = true;
    try {
      final response = await _api.post(
        '/login',
        data: {'email': email.trim(), 'password': password},
      );

      final token = response['authorization']?['token'] as String? ??
          response['access_token'] as String?;
      final refreshToken = response['authorization']?['refresh_token'] as String? ??
          response['refresh_token'] as String?;

      if (token == null) {
        throw Exception(response['message'] ?? 'Login failed');
      }

      await StorageService.setToken(token);
      if (refreshToken != null) {
        await StorageService.setRefreshToken(refreshToken);
      }

      // Parse user from response
      final userData = response['user'] as Map<String, dynamic>? ??
          response['data']?['user'] as Map<String, dynamic>?;

      if (userData != null) {
        currentUser.value = UserModel.fromJson(userData);
        await StorageService.setUser(userData);
      }

      if (Get.isRegistered<NotificationController>()) {
        unawaited(Get.find<NotificationController>().loadNotifications());
      }

      // توجيه الموكل لشاشته الخاصة
      if (currentUser.value?.isClient == true) {
        Get.offAllNamed(AppRoutes.clientPortal);
      } else {
        Get.offAllNamed(AppRoutes.dashboard);
      }
    } catch (e) {
      Get.snackbar(
        'Login Failed / فشل تسجيل الدخول',
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Register ─────────────────────────────────────────────────────────────
  Future<void> register(String name, String email, String password) async {
    isLoading.value = true;
    try {
      final response = await _api.post(
        '/register',
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
          'password_confirmation': password,
          'role': 'LAWYER',
        },
      );

      final token = response['token'] as String? ??
          response['access_token'] as String? ??
          response['data']?['token'] as String?;

      if (token != null) {
        final refreshToken = response['authorization']?['refresh_token'] as String? ??
            response['refresh_token'] as String? ??
            response['data']?['refresh_token'] as String?;

        await StorageService.setToken(token);
        if (refreshToken != null) {
          await StorageService.setRefreshToken(refreshToken);
        }

        final userData = response['user'] as Map<String, dynamic>? ??
            response['data']?['user'] as Map<String, dynamic>?;
        if (userData != null) {
          currentUser.value = UserModel.fromJson(userData);
          await StorageService.setUser(userData);
        }
        if (Get.isRegistered<NotificationController>()) {
          unawaited(Get.find<NotificationController>().loadNotifications());
        }
        Get.offAllNamed(AppRoutes.dashboard);
      } else {
        Get.snackbar(
          'Success',
          response['message'] ?? 'Registered! Please login.',
          snackPosition: SnackPosition.BOTTOM,
        );
        Get.offAllNamed(AppRoutes.login);
      }
    } catch (e) {
      Get.snackbar(
        'Registration Failed / فشل التسجيل',
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await StorageService.clearAll();
    currentUser.value = null;
    if (Get.isRegistered<NotificationController>()) {
      Get.find<NotificationController>().resetForLogout();
    }
    Get.offAllNamed(AppRoutes.login);
  }

  // ─── Refresh Token ────────────────────────────────────────────────────────
  Future<bool> refreshToken() async {
    final oldRefreshToken = StorageService.getRefreshToken();
    if (oldRefreshToken == null) return false;

    try {
      final response = await _api.post(
        AppConstants.refresh,
        data: {'refresh_token': oldRefreshToken},
      );

      final token = response['authorization']?['token'] as String? ??
          response['access_token'] as String?;
      final nextRefreshToken = response['authorization']?['refresh_token'] as String? ??
          response['refresh_token'] as String?;

      if (token != null) {
        await StorageService.setToken(token);
        if (nextRefreshToken != null) {
          await StorageService.setRefreshToken(nextRefreshToken);
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Refresh token failed: $e');
      return false;
    }
  }

  String get userName => currentUser.value?.name ?? 'محامي';
  String get userEmail => currentUser.value?.email ?? '';
  String get userRole => currentUser.value?.role ?? '';
  bool get isClient => currentUser.value?.isClient ?? false;
}
