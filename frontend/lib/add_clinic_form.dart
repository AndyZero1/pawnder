import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

Future<Map<String, String>?> showAddClinicForm(
  BuildContext context,
  double lat,
  double lng,
) async {
  final nameController = TextEditingController();
  final detailsController = TextEditingController();

  return showDialog<Map<String, String>>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.local_hospital, color: Colors.redAccent),
            SizedBox(width: 10),
            Text('Adaugă Clinică', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Numele clinicii',
                  prefixIcon: const Icon(Icons.business),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailsController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Servicii (ex: vaccin, chirurgie)',
                  prefixIcon: const Icon(Icons.pets, color: Colors.orangeAccent),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
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
                  const SnackBar(content: Text('Numele clinicii este obligatoriu!')),
                );
                return;
              }

              // Loading state
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.redAccent)),
              );

              try {
                final prefs = await SharedPreferences.getInstance();
                final String? token = prefs.getString('auth_token');
                
                final String apiUrl = 'http://10.0.2.2:8000/api/map/add-clinic/';

                final response = await http.post(
                  Uri.parse(apiUrl),
                  headers: {
                    'Content-Type': 'application/json',
                    if (token != null) 'Authorization': 'Bearer $token',
                  },
                  body: jsonEncode({
                    "name": nameController.text.trim(),
                    "details": detailsController.text.trim(),
                    "latitude": lat,
                    "longitude": lng,
                  }),
                );

                Navigator.pop(context); // Close loading

                if (response.statusCode == 200 || response.statusCode == 201) {
                  // Trimitere cu succes la server, returnam datele pt a le pune si pe harta local
                  Navigator.of(context).pop({
                    'nume': nameController.text.trim(),
                    'detalii': detailsController.text.trim(),
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Eroare salvare: ${response.statusCode}')),
                  );
                }
              } catch (e) {
                Navigator.pop(context); // Close loading
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Eroare de conexiune la server.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Salvează', style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  );
}