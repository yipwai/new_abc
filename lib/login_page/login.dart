import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_app_card/gong_ju/auth_porvider.dart';
import 'package:my_app_card/gong_ju/snackbar_utils.dart';
import 'package:my_app_card/login_page/register.dart';
import 'package:my_app_card/main.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade700, Colors.purple.shade700],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: LoginForm(),
            ),
          ),
        ),
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _emailError;
  String? _passwordError;
  bool _obscurePassword = true;

  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool isValidPassword(String password) {
    return RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$').hasMatch(password);
  }

  Future<void> _login() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    if (!isValidEmail(_emailController.text)) {
      setState(() {
        _emailError = 'Please enter a valid email address';
      });
      return;
    }

    if (!isValidPassword(_passwordController.text)) {
      setState(() {
        _passwordError =
            'Password must be at least 8 characters long and contain at least one letter and one number';
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://192.168.31.171:8080/login'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      print('Server response: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final shortTermToken = responseData['short_term_token'];
        final longTermToken = responseData['long_term_token'];
        final userId = responseData['user_id'];
        if (shortTermToken != null && longTermToken != null && userId != null) {
          final int userIdInt = userId is int ? userId : int.parse(userId.toString());

          await _fetchUserInfo(shortTermToken, userIdInt);

          Provider.of<AuthProvider>(context, listen: false).login(
            shortTermToken,
            longTermToken,
            userIdInt,
            username: responseData['user_name'],
            phoneNumber: responseData['phone'],
          );

          showSuccessSnackBar(context, '登入成功');

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => BottomNavBarExample()),
          );
        } else {
          showErrorSnackBar(context, '登入失敗：無效的回應數據');
        }
      } else {
        showErrorSnackBar(context, '登入失敗: ${response.body}');
      }
    } catch (e) {
      showErrorSnackBar(context, '網路錯誤: $e');
    }
  }

  Future<void> _fetchUserInfo(String token, int userId) async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.31.171:8080/get-user-info?user_id=$userId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        Provider.of<AuthProvider>(context, listen: false).updateUserInfo(
          userData['user_name'],
          userData['phone'],
        );
      } else {
        throw Exception('Failed to load user info');
      }
    } catch (e) {
      print('Error fetching user info: $e');
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    String? errorText,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(color: Colors.white70),
          contentPadding: EdgeInsets.fromLTRB(15, 10, 10, 10),
          errorText: errorText,
          border: InputBorder.none,
          prefixIcon: Icon(prefixIcon, color: Colors.white70),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white70,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                )
              : null,
        ),
        obscureText: isPassword ? _obscurePassword : false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 50),
        Text(
          '歡迎回來',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 50),
        _buildTextField(
          controller: _emailController,
          labelText: '電子郵件',
          prefixIcon: Icons.email,
          errorText: _emailError,
        ),
        SizedBox(height: 20),
        _buildTextField(
          controller: _passwordController,
          labelText: '密碼',
          prefixIcon: Icons.lock,
          errorText: _passwordError,
          isPassword: true,
        ),
        SizedBox(height: 30),
        ElevatedButton(
          onPressed: _login,
          child: Text('登錄'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.blue.shade700,
            backgroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        SizedBox(height: 20),
        TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => RegisterPage()),
            );
          },
          child: Text('未有帳戶？前往註冊',
              style: TextStyle(
                color: Colors.white,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white,
              )),
        ),
        SizedBox(height: 20),
        TextButton(
          onPressed: () {
            // 添加忘記密碼功能
          },
          child: Text('忘記密碼？',
              style: TextStyle(
                color: Colors.white,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white,
              )),
        ),
        SizedBox(height: 16),
        TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => BottomNavBarExample()),
            );
          },
          child: Text('跳過',
              style: TextStyle(
                color: Colors.white,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white,
              )),
        ),
      ],
    );
  }
}