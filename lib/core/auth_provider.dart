import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _admin;
  bool _loading = false;

  String? get token => _token;
  Map<String, dynamic>? get admin => _admin;
  bool get loading => _loading;
  bool get isLoggedIn => _token != null;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    final name = prefs.getString('adminName');
    final email = prefs.getString('adminEmail');
    if (_token != null && name != null) {
      _admin = {'name': name, 'email': email};
    }
    notifyListeners();
  }

  Future<String?> login(String email, String password) async {
    _loading = true;
    notifyListeners();
    try {
      final res = await ApiService().post('/auth/login', {
        'email': email,
        'password': password,
      });
      _token = res['token'];
      _admin = res['admin'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await prefs.setString('adminName', _admin!['name']);
      await prefs.setString('adminEmail', _admin!['email']);
      return null; // no error
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _token = null;
    _admin = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}
