import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const PawnderApp());
}

class PawnderApp extends StatelessWidget {
  const PawnderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}