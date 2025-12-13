import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/api_service.dart';

class AuthState extends ChangeNotifier {
  AuthState({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _token != null && _user != null;

  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    _error = null;
    try {
      final res = await _api.login(email: email, password: password);
      _user = res.user;
      _token = res.token;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void logout() {
    _user = null;
    _token = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
