import 'package:flutter/material.dart';
import '../dialogs/edit_profile_dialog.dart';
import '../dialogs/pet_details_dialog.dart';
import '../dialogs/add_pet_dialog.dart';

class OwnerProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const OwnerProfileScreen({super.key, this.userData});

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
      'pozaUrl': user['photo_url'] ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=200&q=80',
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
      pet['pozaUrl'] ?? 'https://images.unsplash.com/photo-1543852786-1cf6624b9987',
    );
  }

  @override
  Widget build(BuildContext context) {
    String numeAfisat = (ownerInfo['username'] != null && ownerInfo['username']!.isNotEmpty)
        ? ownerInfo['username']!
        : ownerInfo['nume']!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8D7DF),
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        centerTitle: true,
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
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _getProfileImage(),
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
                      style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final dateNoi = await showDialog<Map<String, dynamic>>(
                          context: context,
                          builder: (context) => EditProfileDialog(currentInfo: ownerInfo),
                        );
                        if (dateNoi != null) {
                          setState(() {
                            ownerInfo = dateNoi;
                          });
                        }
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text(
                        'Edit Profile',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1F6E6C),
                        elevation: 4,
                        shadowColor: Colors.black.withOpacity(0.3),
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Divider(color: Colors.black.withOpacity(0.1)),
              const SizedBox(height: 20),
              const Text(
                'My Pets',
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

  Widget _buildPetCard(BuildContext context, Map<String, dynamic> pet) {
    return GestureDetector(
      onTap: () async {
        final actiune = await showDialog(
          context: context,
          builder: (context) => PetDetailsDialog(pet: pet),
        );
        if (actiune == 'delete') {
          setState(() {
            myPets.remove(pet);
          });
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
              backgroundImage: _getPetImage(pet),
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
