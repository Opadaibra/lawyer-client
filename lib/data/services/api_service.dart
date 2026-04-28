import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../core/constants/app_constants.dart';
import '../services/storage_service.dart';
import '../../controllers/auth_controller.dart';

class ApiService {
  static const String baseUrl = AppConstants.baseUrl;

  Map<String, String> _getHeaders({bool isMultipart = false}) {
    final token = StorageService.getToken();
    return {
      'Accept': 'application/json',
      'Content-Type': isMultipart ? 'multipart/form-data' : 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return {'message': 'فشل في قراءة بيانات الخادم', 'status_code': response.statusCode};
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

      // تعريب بعض الرسائل الشائعة القادمة من السيرفر إذا كانت بالإنجليزية
      if (message.toLowerCase().contains('unauthenticated')) message = 'يرجى تسجيل الدخول للمتابعة';
      if (message.toLowerCase().contains('server error')) message = 'حدث خطأ داخلي في الخادم';

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
        
        final auth = Get.find<AuthController>();
        final success = await auth.refreshToken();
        
        if (success) {
          return await requestFn();
        } else {
          auth.logout();
          throw Exception('انتهت الجلسة، يرجى تسجيل الدخول مجدداً');
        }
      }
      
      _handleError(response);
      return response;
    } on SocketException {
      throw Exception('لا يوجد اتصال بالإنترنت، يرجى التحقق من الشبكة');
    } on HandshakeException {
      throw Exception('فشل الاتصال الآمن بالخادم');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('حدث خطأ غير متوقع');
    }
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await _requestWithRetry(
      () => http.get(Uri.parse('$baseUrl$endpoint'), headers: _getHeaders()),
      endpoint: endpoint,
    );
    return _parseResponse(response);
  }

  Future<dynamic> getList(String endpoint) async {
    final response = await _requestWithRetry(
      () => http.get(Uri.parse('$baseUrl$endpoint'), headers: _getHeaders()),
      endpoint: endpoint,
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? data,
  }) async {
    final response = await _requestWithRetry(
      () => http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(),
        body: data != null ? jsonEncode(data) : null,
      ),
      endpoint: endpoint,
    );
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final response = await _requestWithRetry(
      () => http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(),
        body: jsonEncode(data),
      ),
      endpoint: endpoint,
    );
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    final response = await _requestWithRetry(
      () => http.delete(Uri.parse('$baseUrl$endpoint'), headers: _getHeaders()),
      endpoint: endpoint,
    );
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> uploadFile({
    required String filePath,
    required String fileName,
    String? customEndpoint,
    Map<String, String>? fields,
  }) async {
    final endpoint = customEndpoint ?? AppConstants.filesUpload;
    
    Future<http.Response> doUpload() async {
      final token = StorageService.getToken();
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));
      request.headers.addAll({
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });
      request.files.add(await http.MultipartFile.fromPath('file', filePath, filename: fileName));
      if (fields != null) request.fields.addAll(fields);
      final streamedResponse = await request.send();
      return await http.Response.fromStream(streamedResponse);
    }

    final response = await _requestWithRetry(doUpload, endpoint: endpoint);
    return _parseResponse(response);
  }
}
