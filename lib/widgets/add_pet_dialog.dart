import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

class AddPetDialog extends StatefulWidget {
  const AddPetDialog({super.key});

  @override
  State<AddPetDialog> createState() => _AddPetDialogState();
}

class _AddPetDialogState extends State<AddPetDialog> {
  late TextEditingController numeController;
  late TextEditingController rasaController;
  late TextEditingController specieController;
  late TextEditingController varstaController;
  late TextEditingController greutateController;

  Uint8List? pozaAnimalBytes;

  @override
  void initState() {
    super.initState();
    numeController = TextEditingController();
    rasaController = TextEditingController();
    specieController = TextEditingController();
    varstaController = TextEditingController();
    greutateController = TextEditingController();
  }

  @override
  void dispose() {
    numeController.dispose();
    rasaController.dispose();
    specieController.dispose();
    varstaController.dispose();
    greutateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const Text(
                'Adaugă un animal',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Poza de profil pentru noul animal
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: pozaAnimalBytes != null
                        ? MemoryImage(pozaAnimalBytes!)
                        : null,
                    child: pozaAnimalBytes == null
                        ? const Icon(Icons.pets, size: 40, color: Colors.grey)
                        : null,
                  ),
                  GestureDetector(
                    onTap: () async {
                      FilePickerResult? result = await FilePicker.platform
                          .pickFiles(type: FileType.image, withData: true);
                      if (result != null) {
                        setState(() {
                          pozaAnimalBytes = result.files.single.bytes;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1F6E6C),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_a_photo,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              _buildInputField('Nume', 'Ex: Max', numeController),
              _buildInputField(
                'Specie',
                'Ex: Câine, Pisică, Papagal',
                specieController,
              ),
              _buildInputField('Rasă', 'Ex: Golden Retriever', rasaController),

            
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      'Vârstă (ani)',
                      'Ex: 3',
                      varstaController,
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildInputField(
                      'Greutate (kg)',
                      'Ex: 15',
                      greutateController,
                      isNumber: true,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                  
                    Navigator.pop(context, {
                      'nume': numeController.text.isEmpty
                          ? 'Fără Nume'
                          : numeController.text,
                      'rasa': rasaController.text.isEmpty
                          ? 'Necunoscută'
                          : rasaController.text,
                      'specie': specieController.text.isEmpty
                          ? 'Necunoscută'
                          : specieController.text,
                      'varsta': varstaController.text.isEmpty
                          ? '0'
                          : varstaController.text,
                      'greutate': greutateController.text.isEmpty
                          ? '0'
                          : greutateController.text,
                    
                      'pozaUrl':
                          'https://images.unsplash.com/photo-1543852786-1cf6624b9987?auto=format&fit=crop&w=500&q=80',
                      'pozaBytes': pozaAnimalBytes,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F6E6C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Adaugă Animalul',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  
  Widget _buildInputField(
    String label,
    String hint,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              hintText: hint,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 15,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF1F6E6C)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
