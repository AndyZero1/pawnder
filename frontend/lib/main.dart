import 'package:flutter/material.dart';
import 'screens/consultation_screen.dart';

void main() {
  runApp(const PawnderApp());
}

class PawnderApp extends StatelessWidget {
  const PawnderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ConsultationScreen(
        userData: {
          'id': '93bf9b6e-c51a-4838-936e-9e959fc38336',
          'username': 'maria.maria',
          'rol': 'VETERINARY',
          'is_premium': false,
        },
      ),
    );
  }
}