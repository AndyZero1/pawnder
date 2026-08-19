import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8D7DF),
      ),
      home: const LoginScreen(),
    ),
  );
}
