import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'api_service.dart';

class UserAuthProvider extends ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;

  final _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isLoggedIn => _token != null;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('userToken');
    final name = prefs.getString('userName');
    final email = prefs.getString('userEmail');
    if (_token != null && email != null) {
      _user = {'name': name, 'email': email};
    }
    notifyListeners();
  }

  /// Step 1: request OTP — returns null on success, error string on failure
  Future<String?> sendOtp(String email) async {
    try {
      await ApiService().post('/user/send-otp', {'email': email});
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  /// Step 2: verify OTP — returns null on success, error string on failure
  Future<String?> verifyOtp(String email, String otp, {String? name}) async {
    try {
      final res = await ApiService().post('/user/verify-otp', {
        'email': email,
        'otp': otp,
        if (name != null && name.isNotEmpty) 'name': name,
      });
      debugPrint('[verifyOtp] response: $res');
      await _save(res);
      return null;
    } catch (e) {
      debugPrint('[verifyOtp] error: $e');
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  /// Google Sign-In — returns null on success, error string on failure
  Future<String?> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return 'Sign in cancelled';
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) return 'Could not get Google token';
      final res = await ApiService().post('/user/google', {'idToken': idToken});
      await _save(res);
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<void> _save(Map<String, dynamic> res) async {
    final token = res['token'] as String?;
    final userMap = res['user'] as Map<String, dynamic>?;

    if (token == null || userMap == null) {
      throw Exception('Invalid server response: missing token or user');
    }

    _token = token;
    _user = userMap;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userToken', _token!);
    await prefs.setString('userName', (_user!['name'] as String?) ?? '');
    await prefs.setString('userEmail', (_user!['email'] as String?) ?? '');
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userToken');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
    notifyListeners();
  }
}
