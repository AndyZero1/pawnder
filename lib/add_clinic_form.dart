import 'package:flutter/material.dart';

// Funcția acum returnează date (un Map cu numele și descrierea) în viitor (Future)
Future<Map<String, String>?> showAddClinicForm(BuildContext context) async {
  // Acestea citesc exact ce scrie utilizatorul în căsuțe
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
                controller: nameController, // Am legat controller-ul aici
                decoration: InputDecoration(
                  labelText: 'Numele clinicii',
                  prefixIcon: const Icon(Icons.business),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailsController, // Și aici
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
            onPressed: () => Navigator.of(context).pop(), // Închide fără să trimită nimic
            child: const Text('Anulează', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              // Când apeși salvează, trimitem datele înapoi la ecranul principal
              Navigator.of(context).pop({
                'nume': nameController.text,
                'detalii': detailsController.text,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Salvează', style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  );
}