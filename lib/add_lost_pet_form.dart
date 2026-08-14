import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data'; // <--- NOU: Asta se folosește pe Web în loc de dart:io

Future<Map<String, dynamic>?> showAddLostPetForm(BuildContext context) async {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final detailsController = TextEditingController();

  Uint8List? imageBytes; // <--- Aici ținem poza sub formă de memorie

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
                        // Citim fișierul ca memorie (bytes) ca să meargă pe Chrome!
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
                        // Afișăm poza din memorie folosind MemoryImage
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
                onPressed: () {
                  Navigator.of(context).pop({
                    'nume': nameController.text,
                    'telefon': phoneController.text,
                    'detalii': detailsController.text,
                    'poza': imageBytes, // Trimitem memoria mai departe
                  });
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