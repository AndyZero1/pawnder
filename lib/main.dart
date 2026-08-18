import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';

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
      'vaccinari': <Map<String, dynamic>>[
        {
          'numeVaccin': 'Antirabic',
          'dataAdministrarii': '15/03/2026',
          'dataRapel': '15/03/2027',
          'veterinar': 'Dr. Popescu',
          'note': 'Fără reacții adverse',
        },
        {
          'numeVaccin': 'Polivalent (DHPPi)',
          'dataAdministrarii': '10/01/2026',
          'dataRapel': '10/01/2027',
          'veterinar': 'Dr. Ionescu',
          'note': 'Rapel anual necesar',
        },
        {
          'numeVaccin': 'Leptospiroză',
          'dataAdministrarii': '20/06/2025',
          'dataRapel': '20/06/2026',
          'veterinar': 'Dr. Popescu',
          'note': '',
        },
      ],
      'documenteMedicale': <Map<String, dynamic>>[
        {
          'nume': 'Analize_sange_Max.pdf',
          'bytes': null,
          'dataAdaugarii': '17/08/2026',
          'dimensiune': '2.3 MB',
        },
      ],
    },
    {
      'nume': 'Luna',
      'rasa': 'Pisică Europeană',
      'specie': 'Pisică',
      'varsta': 1,
      'greutate': 4,
      'pozaUrl':
          'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&w=1000&q=80',
      'vaccinari': <Map<String, dynamic>>[
        {
          'numeVaccin': 'Antirabic',
          'dataAdministrarii': '01/05/2026',
          'dataRapel': '01/05/2027',
          'veterinar': 'Dr. Marinescu',
          'note': 'Prima doză',
        },
        {
          'numeVaccin': 'Tricat (RCP)',
          'dataAdministrarii': '15/02/2026',
          'dataRapel': '15/08/2026',
          'veterinar': 'Dr. Marinescu',
          'note': 'Rapel necesar la 6 luni',
        },
      ],
      'documenteMedicale': <Map<String, dynamic>>[],
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

  // --- DOSAR MEDICAL ---
  int _medicalTabIndex = 0; // 0 = Documente, 1 = Vaccinări
  late List<Map<String, dynamic>> _vaccinari;
  late List<Map<String, dynamic>> _documenteMedicale;

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

    // Inițializăm listele medicale din datele pet-ului
    _vaccinari = List<Map<String, dynamic>>.from(
      widget.pet['vaccinari'] ?? [],
    );
    _documenteMedicale = List<Map<String, dynamic>>.from(
      widget.pet['documenteMedicale'] ?? [],
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
              const SizedBox(height: 20),

              // ============================================
              // === SECȚIUNEA DOSAR MEDICAL ===
              // ============================================
              Divider(color: Colors.grey.withValues(alpha: 0.3)),
              const SizedBox(height: 15),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F6E6C).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.medical_services_rounded,
                      color: Color(0xFF1F6E6C),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Dosar Medical',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // --- TAB BAR SEGMENTAT ---
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _medicalTabIndex = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _medicalTabIndex == 0
                                ? const Color(0xFF1F6E6C)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _medicalTabIndex == 0
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF1F6E6C)
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.description_outlined,
                                size: 18,
                                color: _medicalTabIndex == 0
                                    ? Colors.white
                                    : Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Documente',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _medicalTabIndex == 0
                                      ? Colors.white
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _medicalTabIndex = 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _medicalTabIndex == 1
                                ? const Color(0xFF1F6E6C)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _medicalTabIndex == 1
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF1F6E6C)
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.vaccines_outlined,
                                size: 18,
                                color: _medicalTabIndex == 1
                                    ? Colors.white
                                    : Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Vaccinări',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _medicalTabIndex == 1
                                      ? Colors.white
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              // --- CONȚINUTUL TABURILOR ---
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.05, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _medicalTabIndex == 0
                    ? _buildDocumenteTab()
                    : _buildVaccinariTab(),
              ),

              const SizedBox(height: 25),
              Divider(color: Colors.grey.withValues(alpha: 0.3)),
              const SizedBox(height: 10),

              // Butonul de ștergere
              TextButton.icon(
                onPressed: () {
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
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Anulează',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context, 'sterge');
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

  // ============================================
  // === TAB DOCUMENTE MEDICALE ===
  // ============================================
  Widget _buildDocumenteTab() {
    return Column(
      key: const ValueKey('documente_tab'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Buton adăugare document
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['pdf'],
                withData: true,
              );
              if (result != null) {
                final file = result.files.single;
                final dimensiune = file.size > 1024 * 1024
                    ? '${(file.size / (1024 * 1024)).toStringAsFixed(1)} MB'
                    : '${(file.size / 1024).toStringAsFixed(0)} KB';
                setState(() {
                  _documenteMedicale.add({
                    'nume': file.name,
                    'bytes': file.bytes,
                    'dataAdaugarii': DateFormat('dd/MM/yyyy').format(DateTime.now()),
                    'dimensiune': dimensiune,
                  });
                });
              }
            },
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Adaugă Document PDF'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1F6E6C),
              side: const BorderSide(color: Color(0xFF1F6E6C), width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        if (_documenteMedicale.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 30),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Icon(Icons.folder_open, size: 40, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'Niciun document medical',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Adaugă un PDF folosind butonul de mai sus',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          )
        else
          ...List.generate(_documenteMedicale.length, (index) {
            final doc = _documenteMedicale[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => DocumentPreviewDialog(document: doc),
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Iconița PDF
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.picture_as_pdf_rounded,
                          color: Colors.red[600],
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Info document
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doc['nume'] ?? 'Document.pdf',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    size: 12, color: Colors.grey[500]),
                                const SizedBox(width: 4),
                                Text(
                                  doc['dataAdaugarii'] ?? '-',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(Icons.data_usage,
                                    size: 12, color: Colors.grey[500]),
                                const SizedBox(width: 4),
                                Text(
                                  doc['dimensiune'] ?? '-',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Buton ștergere
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _documenteMedicale.removeAt(index);
                          });
                        },
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red[400],
                          size: 22,
                        ),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  // ============================================
  // === TAB VACCINĂRI (TIMELINE) ===
  // ============================================
  Widget _buildVaccinariTab() {
    return Column(
      key: const ValueKey('vaccinari_tab'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Buton adăugare vaccinare
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              final vaccinNou = await showDialog<Map<String, dynamic>>(
                context: context,
                builder: (context) => const AddVaccinareDialog(),
              );
              if (vaccinNou != null) {
                setState(() {
                  _vaccinari.insert(0, vaccinNou);
                });
              }
            },
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Adaugă Vaccinare'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1F6E6C),
              side: const BorderSide(color: Color(0xFF1F6E6C), width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        if (_vaccinari.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 30),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Icon(Icons.vaccines_outlined, size: 40, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'Nicio vaccinare înregistrată',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Adaugă o vaccinare folosind butonul de mai sus',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          )
        else
          ...List.generate(_vaccinari.length, (index) {
            final vaccin = _vaccinari[index];
            final status = _getVaccinStatus(vaccin['dataRapel']);
            final isLast = index == _vaccinari.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline (linia verticală + cercul colorat)
                  SizedBox(
                    width: 32,
                    child: Column(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: status.color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: status.color.withValues(alpha: 0.4),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: const Color(0xFF1F6E6C).withValues(alpha: 0.2),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Card vaccin
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: Nume vaccin + badge status + ștergere
                            Row(
                              children: [
                                Icon(Icons.vaccines_rounded,
                                    size: 20, color: status.color),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    vaccin['numeVaccin'] ?? '-',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: status.color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    status.label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: status.color,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _vaccinari.removeAt(index);
                                    });
                                  },
                                  child: Icon(
                                    Icons.close,
                                    size: 18,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Detalii
                            _buildVaccinDetail(
                              Icons.calendar_today,
                              'Administrat',
                              vaccin['dataAdministrarii'] ?? '-',
                            ),
                            if (vaccin['dataRapel'] != null &&
                                vaccin['dataRapel'].toString().isNotEmpty)
                              _buildVaccinDetail(
                                Icons.event_repeat,
                                'Rapel',
                                vaccin['dataRapel'],
                              ),
                            if (vaccin['veterinar'] != null &&
                                vaccin['veterinar'].toString().isNotEmpty)
                              _buildVaccinDetail(
                                Icons.person_outline,
                                'Veterinar',
                                vaccin['veterinar'],
                              ),
                            if (vaccin['note'] != null &&
                                vaccin['note'].toString().isNotEmpty)
                              _buildVaccinDetail(
                                Icons.notes,
                                'Note',
                                vaccin['note'],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildVaccinDetail(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[500]),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Calculează statusul vaccinului pe baza datei de rapel
  _VaccinStatus _getVaccinStatus(String? dataRapelStr) {
    if (dataRapelStr == null || dataRapelStr.isEmpty) {
      return _VaccinStatus('Fără rapel', Colors.grey);
    }
    try {
      final parts = dataRapelStr.split('/');
      final dataRapel = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
      final acum = DateTime.now();
      final diferenta = dataRapel.difference(acum).inDays;

      if (diferenta < 0) {
        return _VaccinStatus('Expirat', Colors.red);
      } else if (diferenta <= 30) {
        return _VaccinStatus('Expiră curând', Colors.orange);
      } else {
        return _VaccinStatus('Valid', const Color(0xFF2ECC40));
      }
    } catch (_) {
      return _VaccinStatus('Necunoscut', Colors.grey);
    }
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

// ============================================
// === HELPER CLASS: STATUS VACCIN ===
// ============================================
class _VaccinStatus {
  final String label;
  final Color color;
  _VaccinStatus(this.label, this.color);
}

// ============================================
// === DIALOG: ADĂUGARE VACCINARE ===
// ============================================
class AddVaccinareDialog extends StatefulWidget {
  const AddVaccinareDialog({super.key});

  @override
  State<AddVaccinareDialog> createState() => _AddVaccinareDialogState();
}

class _AddVaccinareDialogState extends State<AddVaccinareDialog> {
  final numeVaccinController = TextEditingController();
  final veterinarController = TextEditingController();
  final noteController = TextEditingController();
  final dataAdministrariiController = TextEditingController();
  final dataRapelController = TextEditingController();

  @override
  void dispose() {
    numeVaccinController.dispose();
    veterinarController.dispose();
    noteController.dispose();
    dataAdministrariiController.dispose();
    dataRapelController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(
    BuildContext context,
    TextEditingController controller, {
    bool allowFuture = false,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: allowFuture ? DateTime(2035) : DateTime.now(),
      builder: (context, child) {
        return Theme(
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
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F6E6C).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.vaccines_rounded,
                      color: Color(0xFF1F6E6C),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Adaugă Vaccinare',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Nume vaccin (obligatoriu)
              _buildField(
                'Numele vaccinului *',
                'Ex: Antirabic, Polivalent',
                numeVaccinController,
                Icons.vaccines_outlined,
              ),

              // Data administrării (obligatoriu, date picker)
              _buildDateField(
                'Data administrării *',
                'ZZ/LL/AAAA',
                dataAdministrariiController,
                allowFuture: false,
              ),

              // Data rapel (opțional, date picker, permite viitor)
              _buildDateField(
                'Data rapel (opțional)',
                'ZZ/LL/AAAA',
                dataRapelController,
                allowFuture: true,
              ),

              // Veterinar (opțional)
              _buildField(
                'Veterinar (opțional)',
                'Ex: Dr. Popescu',
                veterinarController,
                Icons.person_outline,
              ),

              // Note (opțional)
              _buildField(
                'Note (opțional)',
                'Ex: Fără reacții adverse',
                noteController,
                Icons.notes,
                maxLines: 2,
              ),

              const SizedBox(height: 10),

              // Buton salvare
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (numeVaccinController.text.isEmpty ||
                        dataAdministrariiController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Completează numele vaccinului și data administrării!',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    Navigator.pop(context, {
                      'numeVaccin': numeVaccinController.text,
                      'dataAdministrarii': dataAdministrariiController.text,
                      'dataRapel': dataRapelController.text,
                      'veterinar': veterinarController.text,
                      'note': noteController.text,
                    });
                  },
                  icon: const Icon(Icons.check, size: 20),
                  label: const Text(
                    'Salvează Vaccinarea',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F6E6C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    String hint,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, color: Colors.grey, size: 20),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF1F6E6C)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(
    String label,
    String hint,
    TextEditingController controller, {
    bool allowFuture = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            readOnly: true,
            onTap: () => _pickDate(context, controller, allowFuture: allowFuture),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: const Icon(
                Icons.calendar_today_outlined,
                color: Colors.grey,
                size: 20,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF1F6E6C)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// === DIALOG: PREVIEW DOCUMENT PDF ===
// ============================================
class DocumentPreviewDialog extends StatelessWidget {
  final Map<String, dynamic> document;

  const DocumentPreviewDialog({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450, maxHeight: 500),
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.picture_as_pdf_rounded,
                      color: Colors.red[600],
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          document['nume'] ?? 'Document.pdf',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Adăugat: ${document['dataAdaugarii'] ?? '-'}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // Conținut preview
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 60,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 15),
                      Text(
                        document['nume'] ?? 'Document.pdf',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Dimensiune: ${document['dimensiune'] ?? '-'}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Text(
                          'Vizualizarea completă a PDF-ului va fi disponibilă cu integrarea backend-ului.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Buton închidere
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1F6E6C),
                    side: const BorderSide(color: Color(0xFF1F6E6C)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Închide'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
