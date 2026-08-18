import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

              // Nume vaccin 
              _buildField(
                'Numele vaccinului *',
                'Ex: Antirabic, Polivalent',
                numeVaccinController,
                Icons.vaccines_outlined,
              ),

              // Data administrării 
              _buildDateField(
                'Data administrării *',
                'ZZ/LL/AAAA',
                dataAdministrariiController,
                allowFuture: false,
              ),

              // Data rapel 
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

              // Note 
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
