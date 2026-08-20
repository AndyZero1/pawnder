import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

Future<Map<String, dynamic>?> showAddEventForm(
  BuildContext context,
  double lat,
  double lng,
) async {
  final nameController = TextEditingController();
  final detailsController = TextEditingController();
  
  DateTime? selectedDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          String getFormattedStart() {
            if (selectedDate == null || startTime == null) return 'Alege data și ora de start';
            final day = selectedDate!.day.toString().padLeft(2, '0');
            final month = selectedDate!.month.toString().padLeft(2, '0');
            final h = startTime!.hour.toString().padLeft(2, '0');
            final m = startTime!.minute.toString().padLeft(2, '0');
            return '$day.$month.${selectedDate!.year} - $h:$m';
          }

          String getFormattedEnd() {
            if (endTime == null) return 'Alege ora de încheiere';
            final h = endTime!.hour.toString().padLeft(2, '0');
            final m = endTime!.minute.toString().padLeft(2, '0');
            return '$h:$m';
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.event, color: Colors.purpleAccent, size: 28),
                SizedBox(width: 10),
                Text('Nou Eveniment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Nume (ex: Joacă în parc)',
                      prefixIcon: const Icon(Icons.celebration, color: Colors.purpleAccent),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context, initialDate: DateTime.now(),
                        firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (pickedDate != null && context.mounted) {
                        final pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                        if (pickedTime != null) {
                          setState(() { selectedDate = pickedDate; startTime = pickedTime; });
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month, color: Colors.blueAccent),
                          const SizedBox(width: 12),
                          Expanded(child: Text('Începe: ${getFormattedStart()}', style: TextStyle(color: selectedDate != null ? Colors.black87 : Colors.grey.shade700))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      if (selectedDate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alege întâi data de start!')));
                        return;
                      }
                      final pickedTime = await showTimePicker(context: context, initialTime: startTime ?? TimeOfDay.now());
                      if (pickedTime != null) setState(() { endTime = pickedTime; });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_off, color: Colors.redAccent),
                          const SizedBox(width: 12),
                          Expanded(child: Text('Se termină la: ${getFormattedEnd()}', style: TextStyle(color: endTime != null ? Colors.black87 : Colors.grey.shade700))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: detailsController, maxLines: 3,
                    decoration: InputDecoration(labelText: 'Detalii', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Anulează', style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty || selectedDate == null || startTime == null || endTime == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completează toate datele!'), backgroundColor: Colors.redAccent));
                    return;
                  }
                  
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.purpleAccent)),
                  );

                  try {
                    DateTime startDateTime = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day, startTime!.hour, startTime!.minute);
                    DateTime endDateTime = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day, endTime!.hour, endTime!.minute);

                    final prefs = await SharedPreferences.getInstance();
                    final String? token = prefs.getString('auth_token');
                    
                    final String apiUrl = 'http://127.0.0.1:8000/api/events/create/';

                    final response = await http.post(
                      Uri.parse(apiUrl),
                      headers: {
                        'Content-Type': 'application/json',
                        if (token != null) 'Authorization': 'Bearer $token',
                      },
                      body: jsonEncode({
                        "name": nameController.text.trim(),
                        "details": detailsController.text.trim(),
                        "latitude": lat,
                        "longitude": lng,
                        "start_date": startDateTime.toIso8601String(),
                        "end_time": endDateTime.toIso8601String(),
                      }),
                    );

                    Navigator.pop(context);

                    if (response.statusCode == 200 || response.statusCode == 201) {
                      Navigator.of(context).pop({
                        'nume': nameController.text.trim(),
                        'dataStart': getFormattedStart(),
                        'oraEnd': getFormattedEnd(),
                        'detalii': detailsController.text.trim(),
                        'expiraLa': endDateTime, 
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Eroare salvare: ${response.statusCode}')));
                    }
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Eroare de conexiune la server.')));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
                child: const Text('Creează', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    },
  );
}