import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../core/constants/app_constants.dart';
import '../services/storage_service.dart';

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

  // ─── Helper: parse response ────────────────────────────────────────────────
  Map<String, dynamic> _parseResponse(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return {'message': response.body, 'status_code': response.statusCode};
    }
  }

  void _handleError(http.Response response) {
    if (response.statusCode == 401) {
      StorageService.clearAll();
      Get.offAllNamed('/login');
      throw Exception('Unauthorized. Please login again.');
    }
    if (response.statusCode >= 400) {
      Map<String, dynamic> body = {};
      try {
        body = jsonDecode(response.body);
      } catch (_) {}
      
      String message = 'Server error (${response.statusCode})';

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

      throw Exception(message);
    }
  }

  // ─── GET ──────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(),
      );
      _handleError(response);
      return _parseResponse(response);
    } on SocketException {
      throw Exception('No internet connection / لا يوجد اتصال بالإنترنت');
    }
  }

  // ─── GET list (returns dynamic — could be list or map) ────────────────────
  Future<dynamic> getList(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(),
      );
      _handleError(response);
      return jsonDecode(response.body);
    } on SocketException {
      throw Exception('No internet connection');
    }
  }

  // ─── POST ─────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(),
        body: data != null ? jsonEncode(data) : null,
      );
      _handleError(response);
      return _parseResponse(response);
    } on SocketException {
      throw Exception('No internet connection');
    }
  }

  // ─── PATCH ────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(),
        body: jsonEncode(data),
      );
      _handleError(response);
      return _parseResponse(response);
    } on SocketException {
      throw Exception('No internet connection');
    }
  }

  // ─── DELETE ───────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(),
      );
      _handleError(response);
      return _parseResponse(response);
    } on SocketException {
      throw Exception('No internet connection');
    }
  }

  // ─── FILE UPLOAD ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> uploadFile({
    required String filePath,
    required String fileName,
    Map<String, String>? fields,
  }) async {
    try {
      final token = StorageService.getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl${AppConstants.filesUpload}'),
      );

      request.headers.addAll({
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });

      request.files.add(
        await http.MultipartFile.fromPath('file', filePath, filename: fileName),
      );

      if (fields != null) request.fields.addAll(fields);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      _handleError(response);
      return _parseResponse(response);
    } on SocketException {
      throw Exception('No internet connection');
    }
  }
}
