import 'package:flutter/material.dart';
import 'dart:typed_data';

// ==========================================
// 1. POP-UP CLINICĂ VETERINARĂ (CU RECENZII REALE)
// ==========================================
void showVetPopup(BuildContext context, Map<String, dynamic> clinicData) {
  // Dacă e prima dată când deschidem clinica, creăm o listă goală de recenzii
  clinicData['recenzii'] ??= <Map<String, dynamic>>[];

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          List<Map<String, dynamic>> recenzii = clinicData['recenzii'];
          
          // Calculăm media notelor
          double medie = 0.0;
          if (recenzii.isNotEmpty) {
            double suma = 0;
            for (var r in recenzii) { suma += r['nota']; }
            medie = suma / recenzii.length;
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.local_hospital, color: Colors.redAccent, size: 28),
                const SizedBox(width: 10),
                Expanded(child: Text(clinicData['nume']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), overflow: TextOverflow.ellipsis)),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min, 
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AFIȘARE STELE MEDII
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 5),
                      Text(recenzii.isEmpty ? 'Nou' : medie.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(width: 5),
                      Text('(${recenzii.length} recenzii)', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Text('Servicii oferite:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(clinicData['detalii']!.isEmpty ? 'Nu au fost adăugate detalii.' : clinicData['detalii']!, style: const TextStyle(fontSize: 15)),
                  
                  const SizedBox(height: 15),
                  const Divider(),
                  const SizedBox(height: 10),
                  
                  // LISTA DE RECENZII (COMENATARIILE OAMENILOR)
                  const Text('Recenzii:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  
                  if (recenzii.isEmpty)
                    const Text('Fii primul care lasă o recenzie!', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true, // Ca să nu ocupe tot ecranul
                        itemCount: recenzii.length,
                        itemBuilder: (context, index) {
                          var recenzie = recenzii[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: List.generate(5, (starIndex) {
                                    return Icon(
                                      starIndex < recenzie['nota'] ? Icons.star : Icons.star_border,
                                      color: Colors.amber, size: 14,
                                    );
                                  }),
                                ),
                                const SizedBox(height: 4),
                                Text(recenzie['text'], style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(), 
                child: const Text('Închide', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  // Deschidem formularul de adăugare recenzie
                  final recenzieNoua = await _showAddReviewForm(context);
                  if (recenzieNoua != null) {
                    setState(() {
                      recenzii.add(recenzieNoua); // Adăugăm recenzia în listă!
                    });
                  }
                },
                icon: const Icon(Icons.rate_review, size: 16, color: Colors.white),
                label: const Text('Adaugă Recenzie', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              ),
            ],
          );
        },
      );
    },
  );
}

// Formularul Secundar (Unde alegi stelele)
Future<Map<String, dynamic>?> _showAddReviewForm(BuildContext context) async {
  int selectedStars = 5;
  TextEditingController textController = TextEditingController();

  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Lasă o recenzie', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < selectedStars ? Icons.star : Icons.star_border,
                        color: Colors.amber, size: 35,
                      ),
                      onPressed: () {
                        setState(() { selectedStars = index + 1; });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: textController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Cum a fost experiența ta la această clinică?',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Anulează', style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                onPressed: () {
                  if (textController.text.isNotEmpty) {
                    Navigator.pop(context, {'nota': selectedStars, 'text': textController.text});
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                child: const Text('Trimite', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          );
        }
      );
    }
  );
}

// ==========================================
// 2. POP-UP ANIMAL PIERDUT 
// ==========================================
void showLostPetPopup(BuildContext context, String nume, String telefon, String detalii, Uint8List? pozaFizica) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.orange, width: 2)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 10),
            Expanded(child: Text('PIERDUT: $nume', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.redAccent), overflow: TextOverflow.ellipsis)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pozaFizica != null) ...[
              ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(pozaFizica, height: 140, width: double.infinity, fit: BoxFit.cover)),
              const SizedBox(height: 15),
            ] else ...[
              Container(height: 80, width: double.infinity, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)), child: const Center(child: Text('Fără fotografie', style: TextStyle(color: Colors.grey)))),
              const SizedBox(height: 15),
            ],
            const Text('Detalii:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 5),
            Text(detalii.isEmpty ? 'Fără detalii suplimentare.' : detalii, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 15),
            const Text('Contact:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 5),
            Row(children: [const Icon(Icons.phone, color: Colors.green, size: 20), const SizedBox(width: 8), Text(telefon.isEmpty ? 'Nespecificat' : telefon, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Închide', style: TextStyle(color: Colors.grey))),
          ElevatedButton.icon(onPressed: () => Navigator.of(context).pop(), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), icon: const Icon(Icons.call, color: Colors.white, size: 18), label: const Text('Sună', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      );
    },
  );
}

// ==========================================
// 3. POP-UP EVENIMENT (Cu dată de încheiere)
// ==========================================
void showEventPopup(BuildContext context, String nume, String dataStart, String oraEnd, String detalii) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.purpleAccent, width: 2)),
        title: Row(
          children: [
            const Icon(Icons.event, color: Colors.purpleAccent, size: 28),
            const SizedBox(width: 10),
            Expanded(child: Text(nume, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.purple), overflow: TextOverflow.ellipsis)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [const Icon(Icons.play_circle_fill, color: Colors.green, size: 20), const SizedBox(width: 8), Text('Începe: $dataStart', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))]),
            const SizedBox(height: 8),
            Row(children: [const Icon(Icons.stop_circle, color: Colors.redAccent, size: 20), const SizedBox(width: 8), Text('Se termină la: $oraEnd', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))]),
            const SizedBox(height: 15),
            const Text('Detalii:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 5),
            Text(detalii.isEmpty ? 'Fără detalii suplimentare.' : detalii, style: const TextStyle(fontSize: 15)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Închide', style: TextStyle(color: Colors.grey))),
          ElevatedButton.icon(onPressed: () => Navigator.of(context).pop(), style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), icon: const Icon(Icons.check, color: Colors.white, size: 18), label: const Text('Particip', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      );
    },
  );
}

// ==========================================
// 4. POP-UP HIDDEN GEM
// ==========================================
void showHiddenGemPopup(BuildContext context, String numeLocatie) { 
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.amber, width: 3)),
        backgroundColor: Colors.amber.shade50, 
        title: const Column(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber, size: 50), 
            SizedBox(height: 10),
            Text('Ai ajuns primul!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.amber), textAlign: TextAlign.center),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Felicitări! Ești primul care a descoperit acest loc secret. 🏆\n\nComoara a fost revendicată și va dispărea de pe hartă pentru ceilalți.', style: TextStyle(fontSize: 16), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Text('📍 ${numeLocatie.isEmpty ? 'Locație necunoscută' : numeLocatie}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.green), textAlign: TextAlign.center),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(onPressed: () => Navigator.of(context).pop(), style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12), elevation: 5), child: const Text('Colectează Premiul', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
          ),
        ],
      );
    },
  );
}