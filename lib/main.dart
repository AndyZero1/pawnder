import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OwnerProfileScreen(), // Aici îi spunem să încarce ecranul tău
    ),
  );
}

class OwnerProfileScreen extends StatefulWidget {
  const OwnerProfileScreen({super.key});

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  // Am schimbat în "dynamic" ca să putem reține fișierul pozei noi
  Map<String, dynamic> ownerInfo = {
    'nume': 'Olteanu Adrian-Ionuț',
    'username': '',
    'pozaUrl':
        'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=200&q=80',
    'bio': 'Iubitor de animale, pasionat de tehnologie.',
    'email': 'adrian@example.com',
    'dataNasterii': '08/10/2000',
    'pozaBytes': null, // Aici se va salva poza dacă o schimbi
  };

  final List<Map<String, dynamic>> myPets = [
    // ... păstrează animalele tale aici (Max și Luna) ...
    {
      'nume': 'Max',
      'rasa': 'Golden Retriever',
      'specie': 'Câine',
      'varsta': 3,
      'greutate': 32,
      'pozaUrl':
          'https://images.unsplash.com/photo-1552053831-71594a27632d?auto=format&fit=crop&w=1000&q=80',
    },
    {
      'nume': 'Luna',
      'rasa': 'Pisică Europeană',
      'specie': 'Pisică',
      'varsta': 1,
      'greutate': 4,
      'pozaUrl':
          'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&w=1000&q=80',
    },
  ];

  @override
  Widget build(BuildContext context) {
    String numeAfisat =
        (ownerInfo['username'] != null && ownerInfo['username']!.isNotEmpty)
        ? ownerInfo['username']!
        : ownerInfo['nume']!;

    return Scaffold(
      // 1. Noul tău fundal roz
      backgroundColor: const Color(0xFFF8D7DF),
      appBar: AppBar(
        title: const Text(
          'Profilul Meu',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        centerTitle: true,
        // 2. Facem AppBar-ul să se contopească perfect cu fundalul
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    // Aici poți lăsa avatarul cum era
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: ownerInfo['pozaBytes'] != null
                          ? MemoryImage(ownerInfo['pozaBytes']) as ImageProvider
                          : NetworkImage(ownerInfo['pozaUrl']),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      numeAfisat,
                      // Text mai vizibil pe roz
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      ownerInfo['bio']!,
                      // Gri mai închis pentru contrast bun
                      style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),
                    // Butonul NOU de Editează profilul, care iese în evidență
                    ElevatedButton.icon(
                      onPressed: () async {
                        final dateNoi = await showDialog<Map<String, dynamic>>(
                          context: context,
                          builder: (context) =>
                              EditProfileDialog(currentInfo: ownerInfo),
                        );
                        if (dateNoi != null) {
                          setState(() {
                            ownerInfo = dateNoi;
                          });
                        }
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text(
                        'Editează profilul',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors
                            .white, // Fundal alb ca să sară în ochi pe roz
                        foregroundColor: const Color(
                          0xFF1F6E6C,
                        ), // Textul și iconița teal
                        elevation: 4, // Aceasta este umbra care îl face 3D
                        shadowColor: Colors.black.withValues(
                          alpha: 0.3,
                        ), // Culoarea umbrei
                        padding: const EdgeInsets.symmetric(
                          horizontal: 25,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // O linie despărțitoare subtilă (alb cu transparență sau teal foarte deschis)
              Divider(color: Colors.black.withValues(alpha: 0.1)),
              const SizedBox(height: 20),
              const Text(
                'Animalele mele',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: myPets.length + 1,
                  itemBuilder: (context, index) {
                    if (index == myPets.length) return _buildAddPetCard();
                    return _buildPetCard(context, myPets[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget separat pentru cardul unui animal existent
  Widget _buildPetCard(BuildContext context, Map<String, dynamic> pet) {
    return GestureDetector(
      onTap: () async {
        final actiune = await showDialog(
          context: context,
          builder: (context) => PetDetailsDialog(pet: pet),
        );
        if (actiune == 'sterge') {
          setState(() {
            myPets.remove(pet);
          });
        }
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(
          right: 15,
          bottom: 5,
        ), // Am lăsat loc pentru umbră jos
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08), // Umbră mai definită
              spreadRadius: 0,
              blurRadius: 10, // Difuzată frumos
              offset: const Offset(0, 4), // Împinsă puțin în jos, 3D effect
            ),
          ],
        ),
        // ... (păstrează restul conținutului cardului intact)
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: pet['pozaBytes'] != null
                  ? MemoryImage(pet['pozaBytes']) as ImageProvider
                  : NetworkImage(
                      pet['pozaUrl'] ??
                          'https://images.unsplash.com/photo-1543852786-1cf6624b9987',
                    ),
            ),
            const SizedBox(height: 10),
            Text(
              pet['nume'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              pet['rasa'],
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPetCard() {
    return GestureDetector(
      onTap: () async {
        // Aici am pus la loc logica care deschide fereastra
        final animalNou = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => const AddPetDialog(),
        );

        if (animalNou != null) {
          setState(() {
            myPets.add(animalNou);
          });
        }
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(
          bottom: 5,
        ), // Asortat cu marginea cardurilor albe
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFF1F6E6C), width: 1.5),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: Color(0xFF1F6E6C), size: 40),
            SizedBox(height: 8),
            Text(
              'Adaugă Animal',
              style: TextStyle(
                color: Color(0xFF1F6E6C),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- CĂSUȚA (POP-UP) PENTRU DETALII ANIMAL ȘI GALERIE ---
// Am transformat-o în StatefulWidget pentru a putea folosi setState!
class PetDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> pet;

  const PetDetailsDialog({super.key, required this.pet});

  @override
  State<PetDetailsDialog> createState() => _PetDetailsDialogState();
}

class _PetDetailsDialogState extends State<PetDetailsDialog> {
  List<PlatformFile> galerieMedia = [];

  // --- VARIABILE NOI PENTRU EDITARE FRONTEND ---
  Uint8List? pozaProfilBytes; // Aici vom stoca temporar noua poză aleasă

  // Controlere pentru a putea scrie direct peste text
  late TextEditingController rasaController;
  late TextEditingController varstaController;
  late TextEditingController greutateController;

  @override
  void initState() {
    super.initState();
    // Când se deschide fereastra, umplem căsuțele cu datele pe care le avea animalul
    rasaController = TextEditingController(
      text: widget.pet['rasa']?.toString() ?? '',
    );
    varstaController = TextEditingController(
      text: widget.pet['varsta']?.toString() ?? '',
    );
    greutateController = TextEditingController(
      text: widget.pet['greutate']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    // Este o regulă bună de frontend să eliberăm memoria când închidem fereastra
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

              // 1. POZA DE PROFIL EDITABILĂ CU CREION
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    // Dacă am ales o poză nouă, o arătăm. Dacă nu, o arătăm pe cea veche.
                    backgroundImage: pozaProfilBytes != null
                        ? MemoryImage(pozaProfilBytes!) as ImageProvider
                        : NetworkImage(
                            widget.pet['pozaUrl'] ??
                                'https://via.placeholder.com/500',
                          ),
                  ),
                  // Creionul verde pe care dai click
                  GestureDetector(
                    onTap: () async {
                      // Deschidem selectorul DOAR pentru o singură imagine
                      FilePickerResult? result = await FilePicker.platform
                          .pickFiles(type: FileType.image, withData: true);

                      if (result != null) {
                        setState(() {
                          pozaProfilBytes = result.files.single.bytes;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1F6E6C), // Culoarea ta Teal
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Numele rămâne text fix (sau îl poți face și pe el la fel dacă vrei)
              Text(
                widget.pet['nume'] ?? 'Nume necunoscut',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),

              // 2. RASA EDITABILĂ (doar dai click și scrii)
              SizedBox(
                width: 250,
                child: TextField(
                  controller: rasaController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  decoration: const InputDecoration(
                    hintText: 'Introdu rasa',
                    border: InputBorder
                        .none, // Scoatem linia ca să pară text normal
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // 3. INFORMAȚIILE EDITABILE (Vârstă și Greutate)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildEditableInfoBox('Vârstă', varstaController, 'ani'),
                  _buildEditableInfoBox('Greutate', greutateController, 'kg'),
                  _buildInfoBox(
                    'Specie',
                    widget.pet['specie'] ?? '-',
                  ), // Specia o lăsăm nemodificabilă momentan
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

              // GALERIA TA MEDIA RĂMÂNE INTACTĂ AICI
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
                        FilePickerResult? result = await FilePicker.platform
                            .pickFiles(
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
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                              ),
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
              const SizedBox(height: 20), // Puțin spațiu
              // Butonul de ștergere
              TextButton.icon(
                onPressed: () {
                  // Când e apăsat, deschidem o mică alertă de confirmare
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      title: const Text('Confirmare'),
                      content: Text(
                        'Ești sigur că vrei să ștergi profilul lui ${widget.pet['nume']}?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context), // Închide doar alerta
                          child: const Text(
                            'Anulează',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(
                              context,
                            ); // 1. Închide alerta de confirmare
                            Navigator.pop(
                              context,
                              'sterge',
                            ); // 2. Închide profilul și trimite cuvântul "sterge" către pagina principală
                          },
                          child: const Text(
                            'Șterge',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text(
                  'Șterge animalul',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET MODIFICAT: Căsuța de informații cu aliniere perfectă ---
  Widget _buildEditableInfoBox(
    String title,
    TextEditingController controller,
    String suffix,
  ) {
    return Container(
      width: 100, // Dimensiune identică cu căsuța "Specie"
      padding: const EdgeInsets.symmetric(
        vertical: 15,
      ), // Padding identic cu "Specie"
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            // Aliniem textul pe aceeași linie de bază ca să nu "sară" pe verticală
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              IntrinsicWidth(
                // Acest widget forțează textfield-ul să se muleze pe cifră
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 4), // Spațiul minuscul dintre "1" și "ani"
              Text(
                suffix,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Căsuța veche doar pentru afișare (folosită la Specie)
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
          Text(
            title,
            style: const TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// --- CĂSUȚA (POP-UP) PENTRU EDITARE PROFIL ---
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

// --- CĂSUȚA (POP-UP) PENTRU ADĂUGARE ANIMAL NOU ---
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

              // Vârsta și Greutatea puse pe același rând ca să arate mai bine
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
                    // Împachetăm animalul și îl trimitem la lista principală
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
                      // Dacă nu pune poză, îi dăm un placeholder generic
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

  // Funcție ajutătoare pentru design-ul input-urilor
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
