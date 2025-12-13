import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/attendance_record.dart';
import '../models/face_photos.dart';
import '../models/login_response.dart';
import '../models/user.dart';

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  // static const String baseUrl = 'http://127.0.0.1:8000';
  // Base Url Via Real Device
  static const String baseUrl = 'http://192.168.101.21:8000';
  final http.Client _client;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

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
    final url = _uri('/api/login');
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
      _uri('/api/user'),
      headers: _headers(token: token),
    );
    _ensureSuccess(response);
    return User.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<FacePhotosData> getFacePhotos({required String token}) async {
    final response = await _client.get(
      _uri('/api/face-photos'),
      headers: _headers(token: token),
    );
    _ensureSuccess(response);
    return FacePhotosData.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// Upload face photos as multipart. Server is expected to accept `photos[]` files.
  Future<FacePhotosData> uploadFacePhotos({
    required String token,
    required int userId,
    required List<File> photos,
  }) async {
    final request = http.MultipartRequest('POST', _uri('/api/face-photos'))
      ..headers.addAll(_headers(token: token))
      ..fields['user_id'] = userId.toString();

    for (final file in photos) {
      request.files.add(await http.MultipartFile.fromPath('photos[]', file.path));
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    _ensureSuccess(response);
    return FacePhotosData.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> uploadFacePhotoPaths({
    required String token,
    required int userId,
    required List<String> photoPaths,
  }) async {
    final response = await _client.post(
      _uri('/api/face-photos'),
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
      _uri('/api/update-embed-face'),
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

  Future<AttendanceRecord> storeAttendance({
    required String token,
    required int userId,
    required String status,
    required String type,
    required String attendanceDate,
    required String attendanceTime,
    String? photoPath,
    File? photoFile,
  }) async {
    if (photoFile != null) {
      final request = http.MultipartRequest('POST', _uri('/api/attendance'))
        ..headers.addAll(_headers(token: token))
        ..fields['user_id'] = userId.toString()
        ..fields['status'] = status
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

    final response = await _client.post(
      _uri('/api/attendance'),
      headers: _headers(
        token: token,
        extra: {HttpHeaders.contentTypeHeader: 'application/json'},
      ),
      body: jsonEncode({
        'user_id': userId,
        'status': status,
        'type': type,
        'attendance_date': attendanceDate,
        'attendance_time': attendanceTime,
        if (photoPath != null) 'photo_path': photoPath,
      }),
    );
    _ensureSuccess(response);
    final data = jsonDecode(response.body);
    final map = (data is Map<String, dynamic>)
        ? (data['data'] as Map<String, dynamic>? ?? data)
        : <String, dynamic>{};
    return AttendanceRecord.fromJson(map);
  }

  Future<List<AttendanceRecord>> getAttendanceRecords({
    required String token,
    required int userId,
  }) async {
    final response = await _client.get(
      _uri('/api/attendance?user_id=$userId'),
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
      throw HttpException(
        'Request failed (${response.statusCode}): $message',
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
