import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/primary_button.dart';
import '../widgets/auth_toggle.dart';
import '../widgets/custom_text_field.dart';
import 'admin_dashboard_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isSignIn = true;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
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
                    ),

                  PrimaryButton(
                    text: isSignIn ? "Sign In" : "Sign up",
                    onPressed: () {
                      final email = emailController.text.trim().toLowerCase();
                      if (email == 'admin' || email == 'admin@pawnder.com') {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminDashboardScreen(),
                          ),
                        );
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HomeScreen(),
                          ),
                        );
                      }
                    },
                  ),

                  if (isSignIn)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text(
                          "Forgot password ?",
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),

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
