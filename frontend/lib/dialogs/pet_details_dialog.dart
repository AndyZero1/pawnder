import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

class PetDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> pet;

  const PetDetailsDialog({super.key, required this.pet});

  @override
  State<PetDetailsDialog> createState() => _PetDetailsDialogState();
}

class _PetDetailsDialogState extends State<PetDetailsDialog> {
  List<PlatformFile> galerieMedia = [];
  Uint8List? pozaProfilBytes;

  late TextEditingController rasaController;
  late TextEditingController varstaController;
  late TextEditingController greutateController;

  @override
  void initState() {
    super.initState();
    rasaController = TextEditingController(text: widget.pet['rasa']?.toString() ?? '');
    varstaController = TextEditingController(text: widget.pet['varsta']?.toString() ?? '');
    greutateController = TextEditingController(text: widget.pet['greutate']?.toString() ?? '');
  }

  @override
  void dispose() {
    rasaController.dispose();
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
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: pozaProfilBytes != null
                        ? MemoryImage(pozaProfilBytes!) as ImageProvider
                        : NetworkImage(widget.pet['pozaUrl'] ?? 'https://via.placeholder.com/500'),
                  ),
                  GestureDetector(
                    onTap: () async {
                      FilePickerResult? result = await FilePicker.platform.pickFiles(
                        type: FileType.image,
                        withData: true,
                      );
                      if (result != null) {
                        setState(() {
                          pozaProfilBytes = result.files.single.bytes;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1F6E6C),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                widget.pet['nume'] ?? 'Nume necunoscut',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              SizedBox(
                width: 250,
                child: TextField(
                  controller: rasaController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  decoration: const InputDecoration(
                    hintText: 'Introdu rasa',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildEditableInfoBox('Vârstă', varstaController, 'ani'),
                  _buildEditableInfoBox('Greutate', greutateController, 'kg'),
                  _buildInfoBox('Specie', widget.pet['specie'] ?? '-'),
                ],
              ),
              const SizedBox(height: 35),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Galerie Media',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.photo_library, color: Colors.orange),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: galerieMedia.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return GestureDetector(
                      onTap: () async {
                        FilePickerResult? result = await FilePicker.platform.pickFiles(
                          type: FileType.media,
                          allowMultiple: true,
                          withData: true,
                        );
                        if (result != null) {
                          setState(() {
                            galerieMedia.addAll(result.files);
                          });
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange, width: 1.5),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: Colors.orange, size: 30),
                            Text(
                              'Adaugă',
                              style: TextStyle(color: Colors.orange, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final fisier = galerieMedia[index - 1];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: fisier.bytes != null
                        ? Image.memory(fisier.bytes!, fit: BoxFit.cover)
                        : const Icon(Icons.broken_image, color: Colors.grey),
                  );
                },
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      title: const Text('Confirmare'),
                      content: Text('Ești sigur că vrei să ștergi profilul lui ${widget.pet['nume']}?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Anulează', style: TextStyle(color: Colors.grey)),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context, 'sterge');
                          },
                          child: const Text('Șterge', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('Șterge animalul', style: TextStyle(color: Colors.red, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableInfoBox(String title, TextEditingController controller, String suffix) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              IntrinsicWidth(
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(suffix, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(String title, String value) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}