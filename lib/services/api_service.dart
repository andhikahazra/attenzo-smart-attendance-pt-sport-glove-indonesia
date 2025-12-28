import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/attendance_record.dart';
import '../models/face_photos.dart';
import '../models/login_response.dart';
import '../models/user.dart';

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  static const String _defaultBaseUrl = 'http://10.0.2.2:8000';
  final http.Client _client;

  // Synchronous getter for backward compatibility
  static String get baseUrl => _defaultBaseUrl;

  Future<String> _getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('base_url') ?? _defaultBaseUrl;
  }

  // Public method to get current base URL
  static Future<String> getCurrentBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('base_url') ?? _defaultBaseUrl;
  }

  Future<Uri> _uri(String path) async {
    final baseUrl = await _getBaseUrl();
    return Uri.parse('$baseUrl$path');
  }

  Map<String, String> _headers({String? token, Map<String, String>? extra}) {
    final headers = <String, String>{
      HttpHeaders.acceptHeader: 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
    }
    if (extra != null) {
      headers.addAll(extra);
    }
    return headers;
  }

  Future<LoginResponse> login({required String email, required String password}) async {
    final url = await _uri('/api/login');
    try {
      final response = await _client
          .post(
            url,
            headers: _headers(extra: {HttpHeaders.contentTypeHeader: 'application/json'}),
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      _logResponse('POST', url, response);
      _ensureSuccess(response);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return LoginResponse.fromJson(data);
    } on SocketException {
      throw const HttpException('Tidak bisa terhubung ke server');
    } on HttpException {
      rethrow;
    } on FormatException catch (e) {
      throw HttpException('Respon tidak valid: ${e.message}');
    } on TimeoutException {
      throw const HttpException('Login timeout, coba lagi');
    }
  }

  Future<User> getUser({required String token}) async {
    final response = await _client.get(
      await _uri('/api/user'),
      headers: _headers(token: token),
    );
    _ensureSuccess(response);
    return User.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<FacePhotosData> getFacePhotos({required String token}) async {
    final response = await _client.get(
      await _uri('/api/face-photos'),
      headers: _headers(token: token),
    );
    _ensureSuccess(response);
    return FacePhotosData.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// Register/encode face photos (exactly 5) via /api/face-photos/encode using images[] multipart.
  Future<Map<String, dynamic>> encodeFacePhotos({
    required String token,
    required List<File> photos,
  }) async {
    final baseUrl = await _getBaseUrl();
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/face-photos/encode'))
      ..headers.addAll(_headers(token: token));

    for (final file in photos) {
      request.files.add(await http.MultipartFile.fromPath('images[]', file.path));
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    _ensureSuccess(response);
    final data = jsonDecode(response.body);
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  Future<void> uploadFacePhotoPaths({
    required String token,
    required int userId,
    required List<String> photoPaths,
  }) async {
    final response = await _client.post(
      await _uri('/api/face-photos'),
      headers: _headers(
        token: token,
        extra: {HttpHeaders.contentTypeHeader: 'application/json'},
      ),
      body: jsonEncode({
        'user_id': userId,
        'photo_path': photoPaths,
      }),
    );
    _ensureSuccess(response);
  }

  Future<User> updateFaceEmbed({
    required String token,
    required int userId,
    required String faceEmbed,
  }) async {
    final response = await _client.post(
      await _uri('/api/update-embed-face'),
      headers: _headers(
        token: token,
        extra: {HttpHeaders.contentTypeHeader: 'application/json'},
      ),
      body: jsonEncode({
        'user_id': userId,
        'face_embed': faceEmbed,
      }),
    );
    _ensureSuccess(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// Send attendance with photo verification. Backend uses token user id; status handled server-side.
  Future<AttendanceRecord> storeAttendance({
    required String token,
    required String type,
    required String attendanceDate,
    required String attendanceTime,
    required File photoFile,
  }) async {
    final baseUrl = await _getBaseUrl();
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/attendance'))
      ..headers.addAll(_headers(token: token))
      ..fields['type'] = type
      ..fields['attendance_date'] = attendanceDate
      ..fields['attendance_time'] = attendanceTime;

    request.files.add(await http.MultipartFile.fromPath('photo', photoFile.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    _ensureSuccess(response);
    final data = jsonDecode(response.body);
    final map = (data is Map<String, dynamic>)
        ? (data['data'] as Map<String, dynamic>? ?? data)
        : <String, dynamic>{};
    return AttendanceRecord.fromJson(map);
  }

  Future<List<AttendanceRecord>> getAttendanceRecords({
    required String token,
  }) async {
    final response = await _client.get(
      await _uri('/api/attendance'),
      headers: _headers(token: token),
    );

    _ensureSuccess(response);
    final body = jsonDecode(response.body);

    List<dynamic> rawList;
    if (body is Map<String, dynamic>) {
      rawList = (body['data'] as List?) ?? (body['attendance'] as List?) ?? <dynamic>[];
    } else if (body is List) {
      rawList = body;
    } else {
      rawList = <dynamic>[];
    }

    return rawList
        .whereType<Map<String, dynamic>>()
        .map(AttendanceRecord.fromJson)
        .toList();
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = _extractErrorMessage(response);
      // Custom handling for face service error
      if (message.contains('Face could not be detected')) {
        throw HttpException(message, uri: response.request?.url);
      }
      if (message.contains('face service error') || message.contains('Face service error')) {
        // Try to extract details from response
        try {
          final body = jsonDecode(response.body);
          if (body is Map<String, dynamic> && body['details'] != null) {
            final details = body['details'];
            if (details is String && details.contains('Face could not be detected')) {
              throw HttpException(details, uri: response.request?.url);
            }
            if (details is Map && details['message'] is String) {
              throw HttpException(details['message'], uri: response.request?.url);
            }
          }
        } catch (_) {}
      }
      throw HttpException(
        message,
        uri: response.request?.url,
      );
    }
  }

  void _logResponse(String method, Uri url, http.Response response) {
    // Debug log to help diagnose backend responses during development.
    // Remove or guard with a debug flag if needed.
    // ignore: avoid_print
    print('[API] $method ${url.toString()} -> ${response.statusCode} ${response.reasonPhrase}');
    // ignore: avoid_print
    print('[API] body: ${response.body}');
  }

  String _extractErrorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        if (body['message'] is String) return body['message'] as String;
        if (body['error'] is String) return body['error'] as String;
        if (body['errors'] != null) return body['errors'].toString();
      }
    } catch (_) {
      // fall through to raw body
    }
    return response.body.isNotEmpty ? response.body : 'Unknown error';
  }

  void dispose() {
    _client.close();
  }
}
