import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

class EditProfileDialog extends StatefulWidget {
  final Map<String, dynamic> currentInfo;

  const EditProfileDialog({super.key, required this.currentInfo});

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late TextEditingController numeController;
  late TextEditingController usernameController;
  late TextEditingController bioController;
  late TextEditingController emailController;
  late TextEditingController dataNasteriiController;

  Uint8List? pozaNouaBytes;

  @override
  void initState() {
    super.initState();
    numeController = TextEditingController(text: widget.currentInfo['nume']);
    usernameController = TextEditingController(
      text: widget.currentInfo['username'],
    );
    bioController = TextEditingController(text: widget.currentInfo['bio']);
    emailController = TextEditingController(text: widget.currentInfo['email']);
    dataNasteriiController = TextEditingController(
      text: widget.currentInfo['dataNasterii'],
    );

    pozaNouaBytes = widget.currentInfo['pozaBytes'];
  }

  @override
  void dispose() {
    numeController.dispose();
    usernameController.dispose();
    bioController.dispose();
    emailController.dispose();
    dataNasteriiController.dispose();
    super.dispose();
  }

  // --- FUNCȚIA PENTRU AFIȘAREA CALENDARULUI ---
  Future<void> _selecteazaData(BuildContext context) async {
    final DateTime? dataAleasa = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 10, 8), // Data de pornire a calendarului
      firstDate: DateTime(1900), // Anul minim
      lastDate: DateTime.now(), // Nu putem alege o dată din viitor
      builder: (context, child) {
        return Theme(
          // Am colorat calendarul cu nuanța ta de Teal
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1F6E6C),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    // Dacă utilizatorul a ales o dată, o formatăm ca ZZ/LL/AAAA și o punem în căsuța de text
    if (dataAleasa != null) {
      setState(() {
        String zi = dataAleasa.day.toString().padLeft(2, '0');
        String luna = dataAleasa.month.toString().padLeft(2, '0');
        dataNasteriiController.text = "$zi/$luna/${dataAleasa.year}";
      });
    }
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
                'Edit Profile',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: pozaNouaBytes != null
                        ? MemoryImage(pozaNouaBytes!) as ImageProvider
                        : NetworkImage(widget.currentInfo['pozaUrl']),
                  ),
                  GestureDetector(
                    onTap: () async {
                      FilePickerResult? result = await FilePicker.platform
                          .pickFiles(type: FileType.image, withData: true);

                      if (result != null) {
                        setState(() {
                          pozaNouaBytes = result.files.single.bytes;
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
                        Icons.edit,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              _buildInputField(
                'Nume Complet',
                'Ex: Nume Prenume',
                numeController,
                null,
                isRequired: true,
              ),
              _buildInputField(
                'Username',
                '@username',
                usernameController,
                null,
                isRequired: true,
              ),
              _buildInputField(
                'Descriere (Bio)',
                'Scrie ceva despre tine',
                bioController,
                null,
                maxLines: 3,
                isRequired: false,
              ),
              _buildInputField(
                'E-mail',
                'example123@gmail.com',
                emailController,
                Icons.email_outlined,
                isRequired: true,
              ),

              // Câmpul modificat pentru Calendar
              _buildInputField(
                'Data nașterii',
                'ZZ/LL/AAAA',
                dataNasteriiController,
                Icons.calendar_today_outlined,
                isRequired: true,
                readOnly:
                    true, // Foarte important: împiedică tastatura să se deschidă
                onTap: () =>
                    _selecteazaData(context), // Deschide calendarul la click
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      'nume': numeController.text,
                      'username': usernameController.text,
                      'bio': bioController.text,
                      'email': emailController.text,
                      'dataNasterii': dataNasteriiController.text,
                      'pozaUrl': widget.currentInfo['pozaUrl'],
                      'pozaBytes': pozaNouaBytes,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F6E6C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Save',
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

  // --- AM MODIFICAT FUNCȚIA PENTRU A SUPORTA CALENDAR ȘI STELUȚĂ ---
  Widget _buildInputField(
    String label,
    String hint,
    TextEditingController controller,
    IconData? icon, {
    int maxLines = 1,
    bool isRequired = false,
    bool readOnly = false,
    VoidCallback? onTap,
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
            maxLines: maxLines,
            readOnly: readOnly, // Dacă e true, doar faci click, nu poți scrie
            onTap:
                onTap, // Funcția care se execută la click (ex: deschidere calendar)
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
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

          // Dacă isRequired e true, desenăm și steluța cu textul
          if (isRequired) ...[
            const SizedBox(height: 4),
            const Text(
              '* Acest câmp este obligatoriu',
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}
