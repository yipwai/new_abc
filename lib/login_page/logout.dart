import 'package:flutter/material.dart';
import 'package:my_app_card/gong_ju/auth_porvider.dart';
import 'package:my_app_card/login_page/login.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class Logout extends StatefulWidget {
  const Logout({Key? key}) : super(key: key);

  @override
  State<Logout> createState() => _LogoutState();
}

class _LogoutState extends State<Logout> {
Future<void> _logout() async {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  int retryCount = 0;
  const maxRetries = 3;

  while (retryCount < maxRetries) {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.31.171:8080/logout'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer ${authProvider.shortTermToken}',
        },
      );

      if (response.statusCode == 200) {
        await authProvider.logout();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('登出成功')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
        return;
      } else if (response.statusCode == 401) {
        // 令牌可能已過期，嘗試刷新
        bool refreshed = await authProvider.refreshToken();
        if (!refreshed) {
          throw Exception('無法刷新令牌');
        }
        retryCount++;
      } else {
        throw Exception('登出請求失敗');
      }
    } catch (e) {
      retryCount++;
      if (retryCount >= maxRetries) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('登出失敗: ${e.toString()}')),
        );
        return;
      }
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('主頁'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: const Center(
        child: Text('你好，這是主頁'),
      ),
    );
  }
}