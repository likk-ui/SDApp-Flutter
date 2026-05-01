import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool autoLogin;

  const LoginScreen({super.key, this.autoLogin = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorText = '';

  @override
  void initState() {
    super.initState();
    if (widget.autoLogin) {
      _autoLogin();
    }
  }

  Future<void> _autoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? '';
    final password = prefs.getString('password') ?? '';

    if (username.isNotEmpty && password.isNotEmpty) {
      _doLogin(username, password);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  const Text(
                    '视力训练',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Vision Training',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 48),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: '用户名',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: '密码',
                            prefixIcon: Icon(Icons.lock),
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _handleLogin(),
                        ),
                        if (_errorText.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            _errorText,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('登录', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorText = '请输入用户名和密码');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = '';
    });

    await _doLogin(username, password);
  }

  Future<void> _doLogin(String username, String password) async {
    final result = await ApiService.login(username, password);

    if (!mounted) return;

    if (result['success'] == true) {
      final expiry = result['expiry'] ?? '';
      if (_isExpired(expiry)) {
        setState(() {
          _isLoading = false;
          _errorText = '账号已过期';
        });
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', username);
      await prefs.setString('password', password);
      await prefs.setString('expiry', expiry);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorText = result['error'] ?? '登录失败';
      });
    }
  }

  bool _isExpired(String expiry) {
    if (expiry.isEmpty || expiry == '永久') return expiry != '永久';
    return true;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}