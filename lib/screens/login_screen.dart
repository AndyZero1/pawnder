import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';
import '../constants/colors.dart';
import '../widgets/auth_toggle.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import 'admin_dashboard_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isSignIn = true;
  bool isLoading = false;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in both email and password.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!isSignIn && password != confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Admin bypass for local admin testing
    if (email.toLowerCase() == 'admin' || email.toLowerCase() == 'admin@pawnder.com') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', 'admin_token');
      await prefs.setString('user_role', 'ADMIN');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
      );
      return;
    }

    setState(() => isLoading = true);

    final baseUrl = ApiConstants.baseUrl;
    try {
      final endpoint = isSignIn ? '$baseUrl/api/auth/login' : '$baseUrl/api/auth/register';
      final body = isSignIn
          ? jsonEncode({'email': email, 'password': password})
          : jsonEncode({
              'email': email.contains('@') ? email : '$email@pawnder.com',
              'password': password,
              'username': email.contains('@') ? email.split('@')[0] : email,
            });

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 5));

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final prefs = await SharedPreferences.getInstance();
        if (token != null) {
          await prefs.setString('auth_token', token);
        }
        if (data['user'] != null) {
          final user = data['user'];
          await prefs.setString('user_id', user['id'] ?? '');
          await prefs.setString('user_name', user['username'] ?? 'Adrian');
          await prefs.setString('user_email', user['email'] ?? email);
        }

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        // Fallback demo mode if backend error or custom credential
        String errorMsg = 'Authentication failed (${response.statusCode})';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['detail'] != null) {
            errorMsg = errorData['detail'];
          }
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      // If backend is not reached, provide quick local login with demo user credentials
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', email.split('@')[0]);
      await prefs.setString('user_email', email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notice: Connecting to $baseUrl ($e). Continuing...'),
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }

  }

  Future<void> _quickDemoLogin() async {
    setState(() => isLoading = true);
    final baseUrl = ApiConstants.baseUrl;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': 'adrian@pawnder.com',
          'password': 'password123',
        }),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['token']);
        await prefs.setString('user_id', data['user']['id']);
        await prefs.setString('user_name', data['user']['username']);
      }
    } catch (_) {}

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isCompact = constraints.maxHeight < 760;
            final bool needScroll = constraints.maxHeight < 560;

            Widget content = SizedBox(
              width: 390,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: isCompact ? 8 : 16),

                  Text(
                    "Pawnder",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.pacifico(
                      fontSize: isCompact ? 44 : 54,
                      color: AppColors.brown,
                    ),
                  ),

                  Image.asset(
                    "assets/images/login.png",
                    height: isCompact ? 135 : 185,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.pets,
                      size: 100,
                      color: Color(0xFF1F6E6C),
                    ),
                  ),
                  SizedBox(height: isCompact ? 8 : 12),

                  AuthToggle(
                    isSignIn: isSignIn,
                    onChanged: (value) {
                      setState(() {
                        isSignIn = value;
                      });
                    },
                  ),

                  SizedBox(height: isCompact ? 8 : 12),

                  Text(
                    isSignIn
                        ? "Please sign in to continue"
                        : "Please sign up to continue",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.brown,
                      fontSize: isCompact ? 14 : 16,
                    ),
                  ),

                  SizedBox(height: isCompact ? 10 : 16),

                  CustomTextField(
                    hint: "E mail / username",
                    icon: Icons.mail,
                    controller: emailController,
                  ),

                  CustomTextField(
                    hint: "Password",
                    icon: Icons.lock_open,
                    obscure: true,
                    controller: passwordController,
                  ),

                  if (!isSignIn)
                    CustomTextField(
                      hint: "Confirm password",
                      icon: Icons.lock_open,
                      obscure: true,
                      controller: confirmPasswordController,
                    ),

                  const SizedBox(height: 6),

                  PrimaryButton(
                    text: isLoading
                        ? "Processing..."
                        : (isSignIn ? "Sign In" : "Sign up"),
                    onPressed: isLoading ? () {} : _handleAuth,
                  ),

                  if (isSignIn) ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _quickDemoLogin,
                        child: const Text(
                          "Quick Demo Login 🚀",
                          style: TextStyle(
                            color: Color(0xFF1F6E6C),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isSignIn
                            ? "New to Hoomans ? "
                            : "Already a user? ",
                        style: const TextStyle(
                          color: AppColors.brown,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => isSignIn = !isSignIn),
                        child: Text(
                          isSignIn ? "Sign up" : "Sign In",
                          style: const TextStyle(
                            color: AppColors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: isCompact ? 10 : 20),
                ],
              ),
            );

            return Center(
              child: needScroll
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      child: content,
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: content,
                    ),
            );
          },
        ),
      ),
    );
  }
}
