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
  bool _isVerifying = false;
  bool _isLoadingRemote = false;
  String? _error;

  Map<String, XFile?> get captures => _captures;
  Map<String, String> get remoteUrls => _remoteUrls;
  bool get isSaving => _isSaving;
  bool get isVerifying => _isVerifying;
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
        _remoteUrls[angles[i]] = await _normalizeUrl(data.photoUrls[i]);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingRemote = false;
      notifyListeners();
    }
  }

  Future<String> _normalizeUrl(String raw) async {
    // If backend returns relative path, prefix with baseUrl.
    if (!raw.startsWith('http')) {
      final baseUrl = await ApiService.getCurrentBaseUrl();
      final base = baseUrl.endsWith('/')
          ? baseUrl.substring(0, baseUrl.length - 1)
          : baseUrl;
      final path = raw.startsWith('/') ? raw : '/$raw';
      return '$base$path';
    }
    // If backend returns localhost/127.0.0.1, swap host to match baseUrl host.
    final uri = Uri.tryParse(raw);
    if (uri == null) return raw;
    if (uri.host == '127.0.0.1' || uri.host == 'localhost') {
      final baseUri = Uri.parse(await ApiService.getCurrentBaseUrl());
      return uri.replace(host: baseUri.host, port: baseUri.port).toString();
    }
    return raw;
  }

  Future<void> savePhotos({required String token}) async {
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
      await _api.encodeFacePhotos(token: token, photos: files);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setSaving(false);
    }
  }

  Future<void> verifyLocalSet({required String token}) async {
    if (!allLocalComplete) {
      throw const FormatException('Lengkapi 5 foto sebelum verifikasi.');
    }

    final files = angles
        .map((angle) => _captures[angle])
        .whereType<XFile>()
        .map((x) => File(x.path))
        .toList(growable: false);

    _setVerifying(true);
    _error = null;
    try {
      await _api.encodeFacePhotos(token: token, photos: files);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setVerifying(false);
    }
  }

  void _setSaving(bool value) {
    _isSaving = value;
    notifyListeners();
  }

  void _setVerifying(bool value) {
    _isVerifying = value;
    notifyListeners();
  }
}
