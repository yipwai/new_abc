import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:my_app_card/gong_ju/snackbar_utils.dart';
import 'package:my_app_card/login_page/login.dart';
import 'package:my_app_card/main.dart';
import 'package:http/http.dart' as http;

class RegisterPage extends StatelessWidget {
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
            colors: [Colors.blue, Colors.purple],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: RegisterForm(),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterForm extends StatefulWidget {
  @override
  _RegisterFormState createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _phoneNumberError;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool isValidPassword(String password) {
    return RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$').hasMatch(password);
  }

  bool isValidPhoneNumber(String phoneNumber) {
    return RegExp(r'^\d{8,}$').hasMatch(phoneNumber);
  }

  Future<void> _register() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _phoneNumberError = null;
    });

    if (!isValidEmail(_emailController.text)) {
      setState(() {
        _emailError = '請輸入有效的電子郵件地址';
      });
      return;
    }

    if (!isValidPassword(_passwordController.text)) {
      setState(() {
        _passwordError = '密碼必須至少8個字符，包含至少一個字母和一個數字';
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _confirmPasswordError = '兩次輸入的密碼不匹配';
      });
      return;
    }

    if (!isValidPhoneNumber(_phoneNumberController.text)) {
      setState(() {
        _phoneNumberError = '請輸入有效的電話號碼（至少8位數字）';
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://192.168.31.171:8080/register'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'user_name': _usernameController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
          'phone': _phoneNumberController.text,
        }),
      );

      if (response.statusCode == 200) {
        showSuccessSnackBar(context, '註冊成功');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } else {
        showErrorSnackBar(context, '註冊失敗: ${response.body}');
      }
    } catch (e) {
      showErrorSnackBar(context, '網絡錯誤: $e');
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    String? errorText,
    bool isPassword = false,
    TextInputType? keyboardType,
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
          contentPadding: EdgeInsets.fromLTRB(15, 10, 10, 10), // 設置左邊距為5px
          errorText: errorText,
          border: InputBorder.none,
          prefixIcon: Icon(prefixIcon, color: Colors.white70),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    controller == _passwordController
                        ? (_obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility)
                        : (_obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                    color: Colors.white70,
                  ),
                  onPressed: () {
                    setState(() {
                      if (controller == _passwordController) {
                        _obscurePassword = !_obscurePassword;
                      } else {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      }
                    });
                  },
                )
              : null,
        ),
        obscureText: isPassword
            ? (controller == _passwordController
                ? _obscurePassword
                : _obscureConfirmPassword)
            : false,
        keyboardType: keyboardType,
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
          '創建新帳戶',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 30),
        _buildTextField(
          controller: _usernameController,
          labelText: '用戶名（可選）',
          prefixIcon: Icons.person,
        ),
        SizedBox(height: 20),
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
        SizedBox(height: 20),
        _buildTextField(
          controller: _confirmPasswordController,
          labelText: '確認密碼',
          prefixIcon: Icons.lock,
          errorText: _confirmPasswordError,
          isPassword: true,
        ),
        SizedBox(height: 20),
        _buildTextField(
          controller: _phoneNumberController,
          labelText: '電話號碼',
          prefixIcon: Icons.phone,
          errorText: _phoneNumberError,
          keyboardType: TextInputType.phone,
        ),
        SizedBox(height: 30),
        ElevatedButton(
          onPressed: _register,
          child: Text('註冊'),
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
              MaterialPageRoute(builder: (context) => LoginPage()),
            );
          },
          child: Text('已有帳戶？登錄',
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
