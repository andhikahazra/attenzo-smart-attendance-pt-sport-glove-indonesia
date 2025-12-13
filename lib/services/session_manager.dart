import '../models/user.dart';

class SessionManager {
  SessionManager._();
  static final SessionManager _instance = SessionManager._();
  factory SessionManager() => _instance;

  String? token;
  User? user;

  void setSession({required String tokenValue, required User userValue}) {
    token = tokenValue;
    user = userValue;
  }

  void clear() {
    token = null;
    user = null;
  }

  bool get isLoggedIn => token != null && user != null;
}
