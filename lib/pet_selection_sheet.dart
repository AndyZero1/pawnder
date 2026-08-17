import 'package:flutter/material.dart';
import 'event_details_screen.dart';

void showPetSelectionSheet(BuildContext context, String eventId, String eventName, List<dynamic> userPets, String userName) { 
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.only(left: 20, right: 20, top: 15, bottom: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50, 
              height: 5, 
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))
            ),
            const SizedBox(height: 20),
            
            const Text(
              'Cu cine vii la eveniment?', 
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)
            ),
            const SizedBox(height: 20),

            if (userPets.isEmpty)
               const Text(
                 'Nu ai adăugat niciun animal încă pe profilul tău.', 
                 style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)
               )
            else
              ...userPets.map((pet) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
                color: Colors.purple.shade50,
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.pets, color: Colors.purpleAccent), 
                  ),
                  title: Text(pet['nume'] ?? 'Nume Necunoscut', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(pet['rasa'] ?? ''),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.purpleAccent),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventDetailsScreen(
                          eventId: eventId, // <-- ADAUGAT AICI PENTRU SERVER
                          eventName: eventName,
                          location: 'Vii cu: ${pet['nume']}', 
                          myName: userName, 
                          myPetInfo: '${pet['rasa']} - ${pet['nume']}', 
                        ),
                      ),
                    );
                  },
                ),
              )),
          ],
        ),
      );
    },
  );
}