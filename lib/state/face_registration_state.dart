import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../models/face_photos.dart';
import '../services/api_service.dart';

class FaceRegistrationState extends ChangeNotifier {
  FaceRegistrationState({ApiService? api, List<String>? angles})
      : _api = api ?? ApiService(),
        angles = angles ?? const [
          'Center',
          'Kanan',
          'Kiri',
          'Agak ke atas',
          'Agak ke bawah',
        ];

  final ApiService _api;
  final List<String> angles;

  final Map<String, XFile?> _captures = {};
  final Map<String, String> _remoteUrls = {};
  bool _isSaving = false;
  bool _isLoadingRemote = false;
  String? _error;

  Map<String, XFile?> get captures => _captures;
  Map<String, String> get remoteUrls => _remoteUrls;
  bool get isSaving => _isSaving;
  bool get isLoadingRemote => _isLoadingRemote;
  String? get error => _error;
  bool get hasLocalCapture => _captures.values.any((f) => f != null);
  bool get allLocalComplete => angles.every((angle) => _captures[angle] != null);
  bool get hasRemoteSet => angles.every((angle) => (_remoteUrls[angle] ?? '').isNotEmpty);
  bool get isComplete => allLocalComplete;

  void setCapture(String angle, XFile file) {
    _captures[angle] = file;
    notifyListeners();
  }

  void clear() {
    _captures.clear();
    _remoteUrls.clear();
    notifyListeners();
  }

  Future<void> loadExisting({required String token}) async {
    _isLoadingRemote = true;
    _error = null;
    notifyListeners();
    try {
      final FacePhotosData data = await _api.getFacePhotos(token: token);
      _remoteUrls.clear();
      for (int i = 0; i < angles.length && i < data.photoUrls.length; i++) {
        _remoteUrls[angles[i]] = _normalizeUrl(data.photoUrls[i]);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingRemote = false;
      notifyListeners();
    }
  }

  String _normalizeUrl(String raw) {
    // If backend returns relative path, prefix with baseUrl.
    if (!raw.startsWith('http')) {
      final base = ApiService.baseUrl.endsWith('/')
          ? ApiService.baseUrl.substring(0, ApiService.baseUrl.length - 1)
          : ApiService.baseUrl;
      final path = raw.startsWith('/') ? raw : '/$raw';
      return '$base$path';
    }
    // If backend returns localhost/127.0.0.1, swap host to match baseUrl host.
    final uri = Uri.tryParse(raw);
    if (uri == null) return raw;
    if (uri.host == '127.0.0.1' || uri.host == 'localhost') {
      final baseUri = Uri.parse(ApiService.baseUrl);
      return uri.replace(host: baseUri.host, port: baseUri.port).toString();
    }
    return raw;
  }

  Future<void> savePhotos({required String token, required int userId}) async {
    if (!allLocalComplete) {
      throw const FormatException('Harus mengambil 5 foto sebelum menyimpan.');
    }

    final files = angles
        .map((angle) => _captures[angle])
        .whereType<XFile>()
        .map((x) => File(x.path))
        .toList(growable: false);

    _setSaving(true);
    _error = null;
    try {
      await _api.uploadFacePhotos(token: token, userId: userId, photos: files);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setSaving(false);
    }
  }

  void _setSaving(bool value) {
    _isSaving = value;
    notifyListeners();
  }
}
