import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'add_vaccinare_dialog.dart';


class _VaccinStatus {
  final String label;
  final Color color;
  _VaccinStatus(this.label, this.color);
}


class PetDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> pet;

  const PetDetailsDialog({super.key, required this.pet});

  @override
  State<PetDetailsDialog> createState() => _PetDetailsDialogState();
}

class _PetDetailsDialogState extends State<PetDetailsDialog> {
  List<PlatformFile> galerieMedia = [];

  Uint8List? pozaProfilBytes; 

  int _medicalTabIndex = 0; 
  late List<Map<String, dynamic>> _vaccinari;
  late List<Map<String, dynamic>> _documenteMedicale;

  late TextEditingController rasaController;
  late TextEditingController varstaController;
  late TextEditingController greutateController;

  @override
  void initState() {
    super.initState();
    rasaController = TextEditingController(
      text: widget.pet['rasa']?.toString() ?? '',
    );
    varstaController = TextEditingController(
      text: widget.pet['varsta']?.toString() ?? '',
    );
    greutateController = TextEditingController(
      text: widget.pet['greutate']?.toString() ?? '',
    );

    _vaccinari = List<Map<String, dynamic>>.from(
      widget.pet['vaccinari'] ?? [],
    );
    _documenteMedicale = List<Map<String, dynamic>>.from(
      widget.pet['documenteMedicale'] ?? [],
    );
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
                        : NetworkImage(
                            widget.pet['pozaUrl'] ??
                                'https://via.placeholder.com/500',
                          ),
                  ),
                  
                  GestureDetector(
                    onTap: () async {
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
                        color: Color(0xFF1F6E6C),
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

              Text(
                widget.pet['nume'] ?? 'Nume necunoscut',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
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
                    border: InputBorder
                        .none, 
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
                  _buildInfoBox(
                    'Specie',
                    widget.pet['specie'] ?? '-',
                  ), 
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


  Widget _buildEditableInfoBox(
    String title,
    TextEditingController controller,
    String suffix,
  ) {
    return Container(
      width: 100, 
      padding: const EdgeInsets.symmetric(
        vertical: 15,
      ), 
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
           
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              IntrinsicWidth(
                
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
              const SizedBox(width: 4), 
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


  Widget _buildDocumenteTab() {
    return Column(
      key: const ValueKey('documente_tab'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // buton adăugare document
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
                      // iconita PDF
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
                      // info document
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
                      // buton ștergere
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

  
  Widget _buildVaccinariTab() {
    return Column(
      key: const ValueKey('vaccinari_tab'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // buton adăugare vaccinare
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
                  // card vaccin
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
                            // nume vaccin + badge status + ștergere
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
                            // detalii
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

  //  calc status vaccin pe baza datei rapel
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

              // conținut preview
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

              // buton închidere
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
