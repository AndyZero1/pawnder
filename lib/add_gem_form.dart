import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

Future<String?> showAddGemForm(
  BuildContext context,
  double lat,
  double lng,
) async {
  final nameController = TextEditingController();

  return showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.diamond, color: Colors.amber, size: 28),
            SizedBox(width: 10),
            Text('Ascunde Comoara', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
          ],
        ),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Numele locului (ex: Parcul X)',
            prefixIcon: const Icon(Icons.location_on, color: Colors.green),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anulează', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Numele locului este obligatoriu!'), backgroundColor: Colors.redAccent),
                );
                return;
              }

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.amber)),
              );

              try {
                final prefs = await SharedPreferences.getInstance();
                final String? token = prefs.getString('auth_token');
                
                final String apiUrl = 'http://10.0.2.2:8000/api/map/add-gem/';

                final response = await http.post(
                  Uri.parse(apiUrl),
                  headers: {
                    'Content-Type': 'application/json',
                    if (token != null) 'Authorization': 'Bearer $token',
                  },
                  body: jsonEncode({
                    "name": nameController.text.trim(),
                    "latitude": lat,
                    "longitude": lng,
                  }),
                );

                Navigator.pop(context); 

                if (response.statusCode == 200 || response.statusCode == 201) {
                  Navigator.of(context).pop(nameController.text.trim());
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Eroare salvare: ${response.statusCode}')),
                  );
                }
              } catch (e) {
                Navigator.pop(context); 
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Eroare de conexiune la server.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Ascunde', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    },
  );
}