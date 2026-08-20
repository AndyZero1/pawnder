import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../modern_nav_bar.dart';
import '../map_screen.dart';
import '../dialogs/edit_profile_dialog.dart';
import '../dialogs/pet_details_dialog.dart';
import '../dialogs/add_pet_dialog.dart';

class OwnerProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const OwnerProfileScreen({super.key, this.userData = const {}});

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  late Map<String, dynamic> ownerInfo;
  final List<Map<String, dynamic>> myPets = [];

  @override
  void initState() {
    super.initState();
    final user = widget.userData?['user'] ?? widget.userData ?? {};

    ownerInfo = {
      'nume': user['username'] ?? 'User',
      'username': user['username'] ?? '',
      'pozaUrl': user['photo_url'] ??
          'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=200&q=80',
      'bio': 'Pet lover, Pawnder member.',
      'email': user['email'] ?? '',
      'dataNasterii': '',
      'pozaBytes': null,
    };
  }

  ImageProvider _getProfileImage() {
    if (ownerInfo['pozaBytes'] != null) {
      return MemoryImage(ownerInfo['pozaBytes']);
    }
    return NetworkImage(ownerInfo['pozaUrl']);
  }

  ImageProvider _getPetImage(Map<String, dynamic> pet) {
    if (pet['pozaBytes'] != null) {
      return MemoryImage(pet['pozaBytes']);
    }
    return NetworkImage(
      pet['pozaUrl'] ??
          'https://images.unsplash.com/photo-1543852786-1cf6624b9987',
    );
  }

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
              userData: widget.userData ?? {},
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
                              backgroundImage: _getProfileImage(),
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
                                  color: Color(0xFF1F6E6C),
                                  width: 1.5,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Divider(color: Colors.black.withOpacity(0.08)),
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
        if (actiune == 'delete' || actiune == 'sterge') {
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
              color: Colors.black.withOpacity(0.08),
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
              backgroundImage: _getPetImage(pet),
            ),
            const SizedBox(height: 10),
            Text(
              pet['nume'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              pet['rasa'] ?? '',
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
          color: Colors.white.withOpacity(0.5),
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
