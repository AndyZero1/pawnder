import 'package:flutter/material.dart';
import '../modern_nav_bar.dart';
import '../map_screen.dart';
import '../widgets/edit_profile_dialog.dart';
import '../widgets/pet_details_dialog.dart';
import '../widgets/add_pet_dialog.dart';

class OwnerProfileScreen extends StatefulWidget {
  const OwnerProfileScreen({super.key});

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  // am schimbat în dynamic ca să putem reține fișierul pozei noi
  Map<String, dynamic> ownerInfo = {
    'nume': 'Olteanu Adrian-Ionuț',
    'username': '',
    'pozaUrl':
        'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=200&q=80',
    'bio': 'Iubitor de animale, pasionat de tehnologie.',
    'email': 'adrian@example.com',
    'dataNasterii': '08/10/2000',
    'pozaBytes': null,
  };

  final List<Map<String, dynamic>> myPets = [
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
      backgroundColor: const Color(0xFFF8D7DF),
      body: SafeArea(
        child: Column(
          children: [
            ModernNavBar(
              currentPage: 'Profilul Meu',
              onMapTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        MapScreen(myPets: myPets, userName: numeAfisat),
                  ),
                );
              },
              onEditTap: () async {
                final dateNoi = await showDialog<Map<String, dynamic>>(
                  context: context,
                  builder: (context) =>
                      EditProfileDialog(currentInfo: ownerInfo),
                );
                if (dateNoi != null) {
                  setState(() => ownerInfo = dateNoi);
                }
              },
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: ownerInfo['pozaBytes'] != null
                                  ? MemoryImage(ownerInfo['pozaBytes'])
                                        as ImageProvider
                                  : NetworkImage(ownerInfo['pozaUrl']),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              numeAfisat,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              ownerInfo['bio']!,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[800],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
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
                            if (index == myPets.length) {
                              return _buildAddPetCard();
                            }
                            return _buildPetCard(context, myPets[index]);
                          },
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
    );
  }

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
        ), 
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
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
        ),
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
