import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
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
    'email': 'adrian@pawnder.com',
    'dataNasterii': '20/05/1998',
    'pozaBytes': null,
  };

  bool isIdentityVerified = false;
  bool isDocumentPending = false;
  bool isUploadingDoc = false;

  final List<Map<String, dynamic>> myPets = [
    {
      'nume': 'Luna',
      'rasa': 'Golden Retriever',
      'specie': 'Dog',
      'varsta': 2.5,
      'greutate': 28,
      'pozaUrl':
          'https://images.unsplash.com/photo-1552053831-71594a27632d?auto=format&fit=crop&w=1000&q=80',
      'vaccinari': <Map<String, dynamic>>[],
      'documenteMedicale': <Map<String, dynamic>>[],
    },
  ];

  Future<void> _uploadIdCard() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null) return;

      setState(() => isUploadingDoc = true);

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '10000000-0000-0000-0000-000000000001';

      final baseUrl = ApiConstants.baseUrl;
      final uri = Uri.parse('$baseUrl/api/upload/id-card/');

      final request = http.MultipartRequest('POST', uri);
      request.fields['user_id'] = userId;
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          file.bytes!,
          filename: file.name,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          isDocumentPending = true;
          isIdentityVerified = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ID document uploaded successfully! Pending review.'),
            backgroundColor: Color(0xFF1F6E6C),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${response.body}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => isUploadingDoc = false);
    }
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

                      // Identity Verification Card
                      _buildIdentityVerificationSection(),

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

  Widget _buildIdentityVerificationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isIdentityVerified
                ? const Color(0xFF2ECC40).withValues(alpha: 0.15)
                : (isDocumentPending
                    ? Colors.amber.withValues(alpha: 0.15)
                    : const Color(0xFF1F6E6C).withValues(alpha: 0.15)),
            child: Icon(
              isIdentityVerified
                  ? Icons.verified
                  : (isDocumentPending ? Icons.hourglass_top : Icons.badge_outlined),
              color: isIdentityVerified
                  ? const Color(0xFF2ECC40)
                  : (isDocumentPending ? Colors.orange : const Color(0xFF1F6E6C)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Identity Verification",
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isIdentityVerified
                      ? "Your identity is verified ✅"
                      : (isDocumentPending
                          ? "Document pending review ⏳"
                          : "Upload ID card to verify identity"),
                  style: TextStyle(
                    color: isIdentityVerified
                        ? const Color(0xFF2ECC40)
                        : (isDocumentPending ? Colors.orange[800] : Colors.grey[600]),
                    fontSize: 12,
                    fontWeight: isIdentityVerified ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          if (!isIdentityVerified)
            ElevatedButton.icon(
              onPressed: isUploadingDoc ? null : _uploadIdCard,
              icon: isUploadingDoc
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.upload_file, size: 16),
              label: Text(
                isDocumentPending ? "Re-upload" : "Upload ID",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F6E6C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
        ],
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
          ],
        ),
      ),
    );
  }

  Widget _buildAddPetCard() {
    return GestureDetector(
      onTap: () async {
        final dateAnimalNou = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (_) => const AddPetDialog(),
        );
        if (dateAnimalNou != null) {
          setState(() => myPets.add(dateAnimalNou));
        }
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 15, bottom: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0xFF1F6E6C),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: Color(0xFFF8D7DF),
              child: Icon(Icons.add, size: 30, color: Color(0xFF1F6E6C)),
            ),
            SizedBox(height: 10),
            Text(
              'Add Pet',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF1F6E6C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
