import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<Map<String, dynamic>?> showAddLostPetForm(
  BuildContext context,
  double lat,
  double lng,
) async {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final detailsController = TextEditingController();

  Uint8List? imageBytes;

  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                SizedBox(width: 10),
                Text('Animal Pierdut', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
                      
                      if (pickedFile != null) {
                        final bytes = await pickedFile.readAsBytes();
                        setState(() {
                          imageBytes = bytes;
                        });
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange, width: 1.5, style: BorderStyle.solid),
                        image: imageBytes != null
                            ? DecorationImage(image: MemoryImage(imageBytes!), fit: BoxFit.cover)
                            : null,
                      ),
                      child: imageBytes == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, color: Colors.orange, size: 35),
                                SizedBox(height: 5),
                                Text('Apasă pentru galerie', style: TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.bold)),
                              ],
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Nume / Rasă animal',
                      prefixIcon: const Icon(Icons.pets),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone, 
                    decoration: InputDecoration(
                      labelText: 'Telefon de contact',
                      prefixIcon: const Icon(Icons.phone, color: Colors.green),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: detailsController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Detalii',
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
                  if (nameController.text.trim().isEmpty || phoneController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Numele și telefonul sunt obligatorii!')));
                    return;
                  }

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.orange)),
                  );

                  try {
                    final prefs = await SharedPreferences.getInstance();
                    final String? token = prefs.getString('auth_token');
                    
                    // ATENȚIE: Serverul cere user_id explicit aici. Asigură-te că la login îl salvați cu prefs.setString('user_id', ...)
                    final String userId = prefs.getString('user_id') ?? '0'; 

                    final uri = Uri.parse('http://127.0.0.1:8000/api/map/report-missing/');
                    var request = http.MultipartRequest('POST', uri);

                    if (token != null) {
                      request.headers['Authorization'] = 'Bearer $token';
                    }

                    // Adăugăm câmpurile text
                    request.fields['user_id'] = userId;
                    request.fields['latitude'] = lat.toString();
                    request.fields['longitude'] = lng.toString();
                    request.fields['description'] = "Nume/Rasă: ${nameController.text.trim()}\nTelefon: ${phoneController.text.trim()}\nDetalii: ${detailsController.text.trim()}";
                    request.fields['missing_date'] = DateTime.now().toIso8601String();

                    // Adăugăm poza dacă există
                    if (imageBytes != null) {
                      request.files.add(
                        http.MultipartFile.fromBytes('file', imageBytes!, filename: 'pet_image.jpg'),
                      );
                    }

                    var streamedResponse = await request.send();
                    var response = await http.Response.fromStream(streamedResponse);

                    Navigator.pop(context); 

                    if (response.statusCode == 200 || response.statusCode == 201) {
                      Navigator.of(context).pop({
                        'nume': nameController.text.trim(),
                        'telefon': phoneController.text.trim(),
                        'detalii': detailsController.text.trim(),
                        'poza': imageBytes, 
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Eroare salvare: ${response.statusCode}')));
                    }
                  } catch (e) {
                    Navigator.pop(context); 
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Eroare de conexiune la server.')));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Raportează', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    },
  );
}