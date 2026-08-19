import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  Map<String, dynamic> ownerInfo = {
    'nume': 'Adrian Olteanu',
    'username': '',
    'pozaUrl':
        'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=200&q=80',
    'bio': 'Animal lover, tech enthusiast.',
    'email': 'adrian@example.com',
    'dataNasterii': '08/10/2000',
    'pozaBytes': null,
  };

  final List<Map<String, dynamic>> myPets = [
    {
      'nume': 'Max',
      'rasa': 'Golden Retriever',
      'specie': 'Dog',
      'varsta': 3,
      'greutate': 32,
      'pozaUrl':
          'https://images.unsplash.com/photo-1552053831-71594a27632d?auto=format&fit=crop&w=1000&q=80',
      'vaccinari': <Map<String, dynamic>>[],
      'documenteMedicale': <Map<String, dynamic>>[],
    },
    {
      'nume': 'Luna',
      'rasa': 'European Shorthair',
      'specie': 'Cat',
      'varsta': 1,
      'greutate': 4,
      'pozaUrl':
          'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&w=1000&q=80',
      'vaccinari': <Map<String, dynamic>>[],
      'documenteMedicale': <Map<String, dynamic>>[],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final String numeAfisat =
        (ownerInfo['username'] != null && ownerInfo['username']!.isNotEmpty)
            ? ownerInfo['username']!
            : ownerInfo['nume']!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8D7DF),
      body: SafeArea(
        child: Column(
          children: [
            
            ModernNavBar(
              currentPage: 'My Profile',
              onMapTap: () => Navigator.push(
                context,
                smoothRoute(
                  MapScreen(myPets: myPets, userName: numeAfisat),
                ),
              ),
            ),

            
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 12.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 46,
                              backgroundImage:
                                  ownerInfo['pozaBytes'] != null
                                      ? MemoryImage(ownerInfo['pozaBytes'])
                                            as ImageProvider
                                      : NetworkImage(ownerInfo['pozaUrl']),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              numeAfisat,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              ownerInfo['bio']!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: () async {
                                final dateNoi =
                                    await showDialog<Map<String, dynamic>>(
                                  context: context,
                                  builder: (_) =>
                                      EditProfileDialog(currentInfo: ownerInfo),
                                );
                                if (dateNoi != null) {
                                  setState(() => ownerInfo = dateNoi);
                                }
                              },
                              icon: const Icon(Icons.edit_outlined, size: 15),
                              label: Text(
                                'Edit Profile',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF1F6E6C),
                                side: const BorderSide(
                                    color: Color(0xFF1F6E6C), width: 1.5),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      Divider(color: Colors.black.withValues(alpha: 0.08)),
                      const SizedBox(height: 12),

                      Text(
                        'My Pets',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),

                      SizedBox(
                        height: 145,
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
          builder: (_) => PetDetailsDialog(pet: pet),
        );
        if (actiune == 'sterge' || actiune == 'delete') {
          setState(() => myPets.remove(pet));
        }
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 15, bottom: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
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
          builder: (_) => const AddPetDialog(),
        );
        if (animalNou != null) {
          setState(() => myPets.add(animalNou));
        }
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(bottom: 5),
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
              'Add Pet',
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
