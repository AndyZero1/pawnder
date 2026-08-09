import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/primary_button.dart';
import '../widgets/auth_toggle.dart';
import '../widgets/custom_text_field.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isSignIn = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: 390,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  Text(
                    "Pawnder",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.pacifico(
                      fontSize: 60,
                      color: AppColors.brown,
                    ),
                  ),

                  Image.asset(
                    "assets/images/login.png",
                    width: 250,
                  ),

                  AuthToggle(
                      isSignIn: isSignIn,
                      onChanged: (value) {
                        setState(() {
                          isSignIn = value;
                        });
                      },
                    ),

                  const SizedBox(height: 15),

                  Text(
                    isSignIn
                        ? "Please sign in to continue"
                        : "Please sign up to continue",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.brown,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 20),

                  CustomTextField(
                  hint: "E mail / username",
                  icon: Icons.mail,
                ),

                 CustomTextField(
                  hint: "Password",
                  icon: Icons.lock_open,
                  obscure: true,
                ),

                  if (!isSignIn)
                    CustomTextField(
                      hint: "Confirm password",
                      icon: Icons.lock_open,
                      obscure: true,
                    ),
                      

                  PrimaryButton(
                  text: isSignIn ? "Sign In" : "Sign up",
                  onPressed: () {},
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

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  }

