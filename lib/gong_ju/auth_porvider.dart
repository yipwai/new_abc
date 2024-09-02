import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

class AuthProvider with ChangeNotifier {
  int? _userId;
  bool _isLoggedIn = false;
  String? _username;
  String? _phoneNumber;
  String? _shortTermToken;
  String? _longTermToken;
  final _storage = FlutterSecureStorage();
  Timer? _refreshTimer;

  int? get userId => _userId;
  bool get isLoggedIn => _isLoggedIn;
  String? get username => _username;
  String? get phoneNumber => _phoneNumber;
  String? get shortTermToken => _shortTermToken;

  Future<void> login(String shortTermToken, String longTermToken, int userId, {String? username, String? phoneNumber}) async {
    _shortTermToken = shortTermToken;
    _longTermToken = longTermToken;
    _userId = userId;
    _isLoggedIn = true;
    _username = username;
    _phoneNumber = phoneNumber;
    await _storage.write(key: 'short_term_token', value: shortTermToken);
    await _storage.write(key: 'long_term_token', value: longTermToken);
    notifyListeners();
    print('User logged in: userId=$_userId, username=$_username, phoneNumber=$_phoneNumber');
    
    // 開始定期刷新短期令牌
    _startTokenRefreshTimer();
  }

  Future<void> logout() async {
    _shortTermToken = null;
    _longTermToken = null;
    _userId = null;
    _isLoggedIn = false;
    _username = null;
    _phoneNumber = null;
    await _storage.delete(key: 'short_term_token');
    await _storage.delete(key: 'long_term_token');
    _stopTokenRefreshTimer();
    notifyListeners();
    print('User logged out');
  }

  Future<void> setUserInfo(String shortTermToken, String longTermToken, int userId, String username, String phoneNumber) async {
    _shortTermToken = shortTermToken;
    _longTermToken = longTermToken;
    _userId = userId;
    _username = username;
    _phoneNumber = phoneNumber;
    _isLoggedIn = true;
    await _storage.write(key: 'short_term_token', value: shortTermToken);
    await _storage.write(key: 'long_term_token', value: longTermToken);
    notifyListeners();
  }

  void updateUserInfo(String? newUsername, String? newPhoneNumber) {
    if (newUsername != null && newUsername.isNotEmpty) {
      _username = newUsername;
    }
    if (newPhoneNumber != null && newPhoneNumber.isNotEmpty) {
      _phoneNumber = newPhoneNumber;
    }
    notifyListeners();
    print('User info updated: username=$_username, phoneNumber=$_phoneNumber');
  }

  Future<bool> tryAutoLogin() async {
    _shortTermToken = await _storage.read(key: 'short_term_token');
    _longTermToken = await _storage.read(key: 'long_term_token');
    if (_shortTermToken != null && _longTermToken != null) {
      _isLoggedIn = true;
      notifyListeners();
      _startTokenRefreshTimer();
      return true;
    }
    return false;
  }

  Future<bool> refreshToken() async {
    if (_shortTermToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('http://192.168.31.171:8080/refresh-short-term-token'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $_shortTermToken',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final newShortTermToken = responseData['short_term_token'];
        if (newShortTermToken != null) {
          _shortTermToken = newShortTermToken;
          await _storage.write(key: 'short_term_token', value: newShortTermToken);
          notifyListeners();
          print('Short-term token refreshed successfully');
          return true;
        }
      } else if (response.statusCode == 401) {
        // 如果短期令牌已過期，嘗試使用長期令牌重新登錄
        return await refreshWithLongTermToken();
      }
    } catch (e) {
      print('Error refreshing token: $e');
    }
    return false;
  }

  Future<bool> refreshWithLongTermToken() async {
    if (_longTermToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('http://192.168.31.171:8080/login'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'token': _longTermToken!,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final newShortTermToken = responseData['short_term_token'];
        final newLongTermToken = responseData['long_term_token'];
        if (newShortTermToken != null && newLongTermToken != null) {
          _shortTermToken = newShortTermToken;
          _longTermToken = newLongTermToken;
          await _storage.write(key: 'short_term_token', value: newShortTermToken);
          await _storage.write(key: 'long_term_token', value: newLongTermToken);
          notifyListeners();
          print('Logged in with long-term token successfully');
          return true;
        }
      }
    } catch (e) {
      print('Error logging in with long-term token: $e');
    }
    return false;
  }

  void _startTokenRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(Duration(minutes: 2), (_) {
      refreshToken();
    });
  }

  void _stopTokenRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void dispose() {
    _stopTokenRefreshTimer();
    super.dispose();
  }
}