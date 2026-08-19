import 'package:flutter/material.dart';
import 'map_screen.dart'; 

void main() {
  runApp(const PawnderApp());
}

class PawnderApp extends StatelessWidget {
  const PawnderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pawnder',
      debugShowCheckedModeBanner: false, 
      theme: ThemeData(
        primaryColor: const Color(0xFF1F6E6C),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F6E6C)),
      ),

      home: MapScreen(
        userName: 'Edyra', 
        myPets: const [
          {'nume': 'Max', 'rasa': 'Golden Retriever'},
        ],
      ), 
    );
  }
}