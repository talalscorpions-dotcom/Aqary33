import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import 'api_client.dart';

/// Session state for the signed-in user, backed by SharedPreferences so a
/// login survives an app restart. Not a StatefulWidget/ChangeNotifier —
/// screens that need to react to sign-in/sign-out should read
/// [currentUser] after awaiting [logIn]/[signUp]/[logOut] rather than
/// listen for changes, which matches how this app navigates today
/// (push straight to HomeScreen on success).
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _tokenKey = 'aqary_auth_token';
  static const _userKey = 'aqary_auth_user';

  AppUser? currentUser;

  /// Call once at startup so a previously-issued token is attached to
  /// every subsequent [ApiClient] request without asking the user to log
  /// in again on every cold start.
  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final userJson = prefs.getString(_userKey);
    if (token == null || userJson == null) return;
    ApiClient.instance.setToken(token);
    currentUser = AppUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
  }

  Future<AppUser> logIn({required String email, required String password}) async {
    final body = await ApiClient.instance.post('/auth/log-in', {
      'email': email,
      'password': password,
    });
    return _saveSession(token: body['token'] as String, userJson: body['user'] as Map<String, dynamic>);
  }

  /// role must be buyer | seller | professional.
  /// professionalCategory (development_building | maintenance_service) and
  /// professionalType are only required when role is professional.
  Future<AppUser> signUp({
    required String email,
    required String phone,
    required String password,
    required String role,
    String? professionalCategory,
    String? professionalType,
  }) async {
    await ApiClient.instance.post('/auth/sign-up', {
      'email': email,
      'phone': phone,
      'password': password,
      'role': role,
      if (professionalCategory != null) 'professionalCategory': professionalCategory,
      if (professionalType != null) 'professionalType': professionalType,
    });
    // Sign-up doesn't return a token itself — log in right after so the
    // app has an active session immediately, matching the existing UI
    // flow that goes straight to HomeScreen on submit.
    return logIn(email: email, password: password);
  }

  Future<AppUser> _saveSession({
    required String token,
    required Map<String, dynamic> userJson,
  }) async {
    final user = AppUser.fromJson(userJson);
    ApiClient.instance.setToken(token);
    currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    return user;
  }

  Future<void> logOut() async {
    currentUser = null;
    ApiClient.instance.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}
