import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../core/constants/app_constants.dart';
import '../services/storage_service.dart';
import '../../controllers/auth_controller.dart';
import 'offline_sync_service.dart';

class ApiService {
  static const String baseUrl = AppConstants.baseUrl;

  Map<String, String> _getHeaders({bool isMultipart = false}) {
    final token = StorageService.getToken();
    return {
      'Accept': 'application/json',
      'Content-Type': isMultipart ? 'multipart/form-data' : 'application/json',
      if (token != null && token != 'offline') 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return {
        'message': 'فشل في قراءة بيانات الخادم',
        'status_code': response.statusCode
      };
    }
  }

  void _handleError(http.Response response) {
    if (response.statusCode == 401) {
      throw Exception('دخول غير مصرح به');
    }
    if (response.statusCode >= 400) {
      Map<String, dynamic> body = {};
      try {
        body = jsonDecode(response.body);
      } catch (_) {}

      String message = 'حدث خطأ في الخادم (${response.statusCode})';

      if (body.containsKey('errors') && body['errors'] != null) {
        if (body['errors'] is Map) {
          final errMap = body['errors'] as Map;
          message = errMap.values.expand((e) => e is List ? e : [e]).join('\n');
        } else {
          message = body['errors'].toString();
        }
      } else if (body['message'] != null) {
        message = body['message'].toString();
      } else if (body['error'] != null) {
        message = body['error'].toString();
      }

      if (message.toLowerCase().contains('unauthenticated'))
        message = 'يرجى تسجيل الدخول للمتابعة';
      if (message.toLowerCase().contains('server error'))
        message = 'حدث خطأ داخلي في الخادم';

      throw Exception(message);
    }
  }

  Future<http.Response> _requestWithRetry(
    Future<http.Response> Function() requestFn, {
    required String endpoint,
    bool isRetry = false,
  }) async {
    try {
      final response = await requestFn();

      if (response.statusCode == 401 &&
          !isRetry &&
          endpoint != AppConstants.refresh &&
          endpoint != AppConstants.login) {
        // Skip refresh if token is offline
        if (StorageService.getToken() == 'offline') {
          throw Exception('لا يمكن اتمام العملية بهذه الصلاحيات (أوفلاين)');
        }

        final auth = Get.find<AuthController>();
        final success = await auth.refreshToken();

        if (success) {
          return await requestFn();
        } else {
          throw Exception(
              'انتهت الجلسة، يرجى تسجيل الخروج والدخول مجدداً أو العمل في وضع عدم الاتصال');
        }
      }

      _handleError(response);
      return response;
    } on SocketException {
      throw const SocketException(
          'لا يوجد اتصال بالإنترنت، يرجى التحقق من الشبكة');
    } on HandshakeException {
      throw Exception('فشل الاتصال الآمن بالخادم');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('حدث خطأ غير متوقع');
    }
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    if (StorageService.isOfflineMode()) {
      final cached = OfflineSyncService.getCachedResponse(endpoint);
      if (cached != null) return cached;

      // Fallback for individual item fetch when created offline (negative ID)
      // e.g. /cases/-123456
      final parts = endpoint.split('/');
      if (parts.length >= 3 && parts.last.isNotEmpty) {
        final possibleId = int.tryParse(parts.last);
        if (possibleId != null && possibleId < 0) {
          final prefixIdx = endpoint.lastIndexOf('/');
          final listEndpoint = endpoint.substring(0, prefixIdx);
          final listCache = OfflineSyncService.getCachedResponse(listEndpoint);
          if (listCache != null) {
            List<dynamic> items = [];
            if (listCache is List)
              items = listCache;
            else if (listCache is Map && listCache['data'] is List)
              items = listCache['data'];
            else if (listCache is Map && listCache[parts[1]] is List)
              items = listCache[parts[1]];

            try {
              final item = items.firstWhere((e) => e['id'] == possibleId,
                  orElse: () => null);
              if (item != null) {
                // Wrap it in a 'data' envelope to mimic standard individual payload
                return {'data': Map<String, dynamic>.from(item)};
              }
            } catch (_) {}
          }
        }
      }
      return {};
    }
    try {
      final response = await _requestWithRetry(
        () => http.get(Uri.parse('$baseUrl$endpoint'), headers: _getHeaders()),
        endpoint: endpoint,
      );
      final json = _parseResponse(response);
      OfflineSyncService.cacheResponse(endpoint, json);
      return json;
    } catch (e) {
      if (e is SocketException || e.toString().contains('الإنترنت')) {
        final cached = OfflineSyncService.getCachedResponse(endpoint);
        if (cached != null) return cached;
        return {};
      }
      rethrow;
    }
  }

  Future<dynamic> getList(String endpoint) async {
    if (StorageService.isOfflineMode()) {
      final cached = OfflineSyncService.getCachedResponse(endpoint);
      if (cached != null) return cached;
      return [];
    }
    try {
      final response = await _requestWithRetry(
        () => http.get(Uri.parse('$baseUrl$endpoint'), headers: _getHeaders()),
        endpoint: endpoint,
      );
      final json = jsonDecode(response.body);
      OfflineSyncService.cacheResponse(endpoint, json);
      return json;
    } catch (e) {
      if (e is SocketException || e.toString().contains('الإنترنت')) {
        final cached = OfflineSyncService.getCachedResponse(endpoint);
        if (cached != null) return cached;
        return [];
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? data,
    bool isSyncCall = false,
  }) async {
    if (StorageService.isOfflineMode() && !isSyncCall) {
      final tempId = OfflineSyncService.generateTempId();
      await OfflineSyncService.queueAction(
          method: 'POST', endpoint: endpoint, data: data, tempId: tempId);
      final mockItem = {'id': tempId, ...?data};

      await OfflineSyncService.appendToCacheList(endpoint, mockItem);

      // Update related lists (e.g. /cases/1/minutes)
      if (data != null) {
        if (endpoint.contains(AppConstants.minutes)) {
          final caseId = data['case_file_id'] ?? data['case_id'];
          if (caseId != null) {
            await OfflineSyncService.appendToCacheList(
                '/cases/$caseId/minutes', mockItem);
          }
        }
        if (endpoint.contains(AppConstants.tasks)) {
          final caseId = data['case_file_id'] ?? data['case_id'];
          if (caseId != null) {
            await OfflineSyncService.appendToCacheList(
                '/tasks/by-case/$caseId', mockItem);
          }
        }
      }

      return {
        'message': 'تم الحفظ محلياً',
        'id': tempId,
        'data': mockItem,
        'status': 'success'
      };
    }

    try {
      final response = await _requestWithRetry(
        () => http.post(
          Uri.parse('$baseUrl$endpoint'),
          headers: _getHeaders(),
          body: data != null ? jsonEncode(data) : null,
        ),
        endpoint: endpoint,
      );
      return _parseResponse(response);
    } catch (e) {
      if (!isSyncCall &&
          (e is SocketException || e.toString().contains('الإنترنت'))) {
        final tempId = OfflineSyncService.generateTempId();
        await OfflineSyncService.queueAction(
            method: 'POST', endpoint: endpoint, data: data, tempId: tempId);
        final mockItem = {'id': tempId, ...?data};

        await OfflineSyncService.appendToCacheList(endpoint, mockItem);

        // Update related lists
        if (data != null) {
          if (endpoint.contains(AppConstants.minutes)) {
            final caseId = data['case_file_id'] ?? data['case_id'];
            if (caseId != null) {
              await OfflineSyncService.appendToCacheList(
                  '/cases/$caseId/minutes', mockItem);
            }
          }
          if (endpoint.contains(AppConstants.tasks)) {
            final caseId = data['case_file_id'] ?? data['case_id'];
            if (caseId != null) {
              await OfflineSyncService.appendToCacheList(
                  '/tasks/by-case/$caseId', mockItem);
            }
          }
        }

        return {
          'message': 'تم الحفظ محلياً',
          'id': tempId,
          'data': mockItem,
          'status': 'success'
        };
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? data,
    bool isSyncCall = false,
  }) async {
    final Map<String, dynamic> requestData = data ?? {};
    if (StorageService.isOfflineMode() && !isSyncCall) {
      await OfflineSyncService.queueAction(
          method: 'PATCH', endpoint: endpoint, data: requestData);
      await OfflineSyncService.updateCacheObject(endpoint, requestData);
      return {'message': 'تم التعديل محلياً', 'status': 'success'};
    }

    try {
      final response = await _requestWithRetry(
        () => http.patch(
          Uri.parse('$baseUrl$endpoint'),
          headers: _getHeaders(),
          body: jsonEncode(requestData),
        ),
        endpoint: endpoint,
      );
      print(response);

      return _parseResponse(response);
    } catch (e) {
      if (!isSyncCall &&
          (e is SocketException || e.toString().contains('الإنترنت'))) {
        await OfflineSyncService.queueAction(
            method: 'PATCH', endpoint: endpoint, data: requestData);
        return {'message': 'تم التعديل محلياً', 'status': 'success'};
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? data,
    bool isSyncCall = false,
  }) async {
    final Map<String, dynamic> requestData = data ?? {};
    if (StorageService.isOfflineMode() && !isSyncCall) {
      await OfflineSyncService.queueAction(
          method: 'PUT', endpoint: endpoint, data: requestData);
      return {'message': 'تم التعديل محلياً', 'status': 'success'};
    }

    try {
      final response = await _requestWithRetry(
        () => http.put(
          Uri.parse('$baseUrl$endpoint'),
          headers: _getHeaders(),
          body: jsonEncode(requestData),
        ),
        endpoint: endpoint,
      );
      return _parseResponse(response);
    } catch (e) {
      if (!isSyncCall &&
          (e is SocketException || e.toString().contains('الإنترنت'))) {
        await OfflineSyncService.queueAction(
            method: 'PUT', endpoint: endpoint, data: requestData);
        return {'message': 'تم التعديل محلياً', 'status': 'success'};
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> delete(String endpoint,
      {bool isSyncCall = false}) async {
    if (StorageService.isOfflineMode() && !isSyncCall) {
      await OfflineSyncService.queueAction(
          method: 'DELETE', endpoint: endpoint);
      return {'message': 'تم الحذف محلياً', 'status': 'success'};
    }

    try {
      final response = await _requestWithRetry(
        () =>
            http.delete(Uri.parse('$baseUrl$endpoint'), headers: _getHeaders()),
        endpoint: endpoint,
      );
      return _parseResponse(response);
    } catch (e) {
      if (!isSyncCall &&
          (e is SocketException || e.toString().contains('الإنترنت'))) {
        await OfflineSyncService.queueAction(
            method: 'DELETE', endpoint: endpoint);
        return {'message': 'تم الحذف محلياً', 'status': 'success'};
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadFile({
    required String filePath,
    required String fileName,
    String? customEndpoint,
    Map<String, String>? fields,
    bool isSyncCall = false,
  }) async {
    final endpoint = customEndpoint ?? AppConstants.filesUpload;

    if (StorageService.isOfflineMode() && !isSyncCall) {
      final tempId = OfflineSyncService.generateTempId();
      await OfflineSyncService.queueAction(
        method: 'UPLOAD',
        endpoint: endpoint,
        localFilePath: filePath,
        fileName: fileName,
        fileCustomEndpoint: endpoint,
        fields: fields,
        tempId: tempId,
      );

      final mockItem = {
        'id': tempId,
        'original_name': fileName,
        'file_name': fileName,
        'created_at': DateTime.now().toIso8601String(),
        'local_path': filePath,
        ...?fields,
      };

      await OfflineSyncService.appendToCacheList(AppConstants.files, mockItem);
      if (fields != null) {
        if (fields.containsKey('case_id')) {
          await OfflineSyncService.appendToCacheList(
              '/files/by-case/${fields['case_id']}', mockItem);
        }
        if (fields.containsKey('minute_id')) {
          await OfflineSyncService.appendToCacheList(
              '/files/by-minute/${fields['minute_id']}', mockItem);
        }
      }

      return {
        'message': 'تم حفظ الملف محلياً للمزامنة',
        'status': 'success',
        'data': mockItem
      };
    }

    Future<http.Response> doUpload() async {
      final token = StorageService.getToken();
      final request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));
      request.headers.addAll({
        'Accept': 'application/json',
        if (token != null && token != 'offline')
          'Authorization': 'Bearer $token',
      });
      request.files.add(await http.MultipartFile.fromPath('file', filePath,
          filename: fileName));
      if (fields != null) request.fields.addAll(fields);
      final streamedResponse = await request.send();
      return await http.Response.fromStream(streamedResponse);
    }

    try {
      final response = await _requestWithRetry(doUpload, endpoint: endpoint);
      return _parseResponse(response);
    } catch (e) {
      if (!isSyncCall &&
          (e is SocketException || e.toString().contains('الإنترنت'))) {
        final tempId = OfflineSyncService.generateTempId();
        await OfflineSyncService.queueAction(
          method: 'UPLOAD',
          endpoint: endpoint,
          localFilePath: filePath,
          fileName: fileName,
          fileCustomEndpoint: endpoint,
          fields: fields,
          tempId: tempId,
        );

        final mockItem = {
          'id': tempId,
          'original_name': fileName,
          'file_name': fileName,
          'created_at': DateTime.now().toIso8601String(),
          ...?fields,
        };

        await OfflineSyncService.appendToCacheList(
            AppConstants.files, mockItem);
        if (fields != null) {
          if (fields.containsKey('case_id')) {
            await OfflineSyncService.appendToCacheList(
                '/files/by-case/${fields['case_id']}', mockItem);
          }
          if (fields.containsKey('minute_id')) {
            await OfflineSyncService.appendToCacheList(
                '/files/by-minute/${fields['minute_id']}', mockItem);
          }
        }

        return {
          'message': 'تم حفظ الملف محلياً للمزامنة',
          'status': 'success',
          'data': mockItem
        };
      }
      rethrow;
    }
  }
}
