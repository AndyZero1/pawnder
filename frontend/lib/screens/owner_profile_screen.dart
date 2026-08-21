import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../modern_nav_bar.dart';
import '../map_screen.dart';
import '../dialogs/edit_profile_dialog.dart';
import '../dialogs/pet_details_dialog.dart';
import '../dialogs/add_pet_dialog.dart';
import '../constants/api_constants.dart';

class OwnerProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const OwnerProfileScreen({super.key, this.userData = const {}});

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  late Map<String, dynamic> ownerInfo;
  List<Map<String, dynamic>> myPets = [];
  bool _isLoadingPets = false;

  bool isIdentityVerified = false;
  bool isDocumentPending = false;
  bool isUploadingDoc = false;

  String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
  }

  String get userId {
    final data = widget.userData ?? {};
    if (data['user'] != null && data['user'] is Map) {
      return data['user']['id']?.toString() ?? data['user']['user_id']?.toString() ?? '';
    }
    return data['id']?.toString() ?? data['user_id']?.toString() ?? '';
  }

  @override
  void initState() {
    super.initState();
    final user = (widget.userData?['user'] is Map)
        ? widget.userData!['user']
        : (widget.userData ?? {});

    isIdentityVerified = user['is_identity_verified'] == true;
    isDocumentPending = (user['id_card_url'] != null && user['id_card_url'].toString().isNotEmpty) && !isIdentityVerified;

    ownerInfo = {
      'id': userId,
      'nume': user['username'] ?? 'User',
      'username': user['username'] ?? '',
      'pozaUrl': user['photo_url'] ??
          'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=200&q=80',
      'bio': user['bio'] ?? 'Pet lover, Pawnder member.',
      'email': user['email'] ?? '',
      'dataNasterii': user['date_of_birth'] ?? user['birth_date'] ?? '',
      'pozaBytes': null,
    };

    _fetchUserProfile();
    _fetchPets();
  }

  Future<String?> _uploadImageBytes(Uint8List bytes, String filename) async {
    try {
      final uri = Uri.parse('$baseUrl/api/users/upload-photo');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'];
      }
    } catch (e) {
      debugPrint('Upload error: $e');
    }
    return null;
  }

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

      final uri = Uri.parse('$baseUrl/api/admin/upload-id/$userId');
      final request = http.MultipartRequest('POST', uri);
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

  Future<void> _fetchUserProfile() async {
    if (userId.isEmpty) return;
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/users/$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          ownerInfo['username'] = data['username'] ?? ownerInfo['username'];
          ownerInfo['nume'] = data['username'] ?? ownerInfo['nume'];
          ownerInfo['email'] = data['email'] ?? ownerInfo['email'];
          ownerInfo['bio'] = data['bio'] ?? ownerInfo['bio'];
          ownerInfo['dataNasterii'] = data['date_of_birth'] ?? data['birth_date'] ?? '';
          if (data['photo_url'] != null && data['photo_url'].toString().isNotEmpty) {
            ownerInfo['pozaUrl'] = data['photo_url'];
          }
          isIdentityVerified = data['is_identity_verified'] == true;
          if (data['id_card_url'] != null && data['id_card_url'].toString().isNotEmpty && !isIdentityVerified) {
            isDocumentPending = true;
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    }
  }

  Future<void> _updateUserProfile(Map<String, dynamic> dateNoi) async {
    String? photoUrl = dateNoi['pozaUrl'];
    
    if (dateNoi['pozaBytes'] != null) {
      final uploadedUrl = await _uploadImageBytes(dateNoi['pozaBytes'], 'avatar.jpg');
      if (uploadedUrl != null) {
        photoUrl = uploadedUrl;
      }
    }

    setState(() {
      ownerInfo = Map.from(dateNoi);
      if (photoUrl != null) ownerInfo['pozaUrl'] = photoUrl;
    });

    if (userId.isEmpty) return;

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/users/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': dateNoi['username'] ?? dateNoi['nume'],
          'email': dateNoi['email'],
          'bio': dateNoi['bio'],
          'date_of_birth': dateNoi['dataNasterii'],
          'photo_url': photoUrl,
        }),
      );

      if (response.statusCode == 200) {
        _fetchUserProfile();
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
    }
  }

  Future<void> _fetchPets() async {
    if (userId.isEmpty) return;
    setState(() => _isLoadingPets = true);

    try {
      final response = await http.get(Uri.parse('$baseUrl/api/pets/$userId'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          myPets = data.map((item) => {
            'id': item['id'],
            'nume': item['name'],
            'rasa': item['breed'] ?? '',
            'specie': item['species'] ?? '',
            'varsta': item['age']?.toString() ?? '0',
            'greutate': item['weight']?.toString() ?? '0',
            'pozaUrl': item['photo_url'] ?? 'https://images.unsplash.com/photo-1543852786-1cf6624b9987',
            'pozaBytes': null,
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching pets: $e');
    } finally {
      if (mounted) setState(() => _isLoadingPets = false);
    }
  }

  Future<void> _addNewPet(Map<String, dynamic> animalNou) async {
    String? photoUrl = animalNou['pozaUrl'];
    
    if (animalNou['pozaBytes'] != null) {
      final uploaded = await _uploadImageBytes(animalNou['pozaBytes'], 'pet.jpg');
      if (uploaded != null) photoUrl = uploaded;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/pets/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'owner_id': userId,
          'name': animalNou['nume'],
          'species': animalNou['specie'],
          'breed': animalNou['rasa'],
          'age': double.tryParse(animalNou['varsta'].toString()) ?? 0.0,
          'weight': double.tryParse(animalNou['greutate'].toString()) ?? 0.0,
          'photo_url': photoUrl,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _fetchPets();
      }
    } catch (e) {
      debugPrint('Error creating pet: $e');
    }
  }

  Future<void> _deletePet(String petId) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/api/pets/$petId'));
      if (response.statusCode == 200) {
        _fetchPets();
      }
    } catch (e) {
      debugPrint('Error deleting pet: $e');
    }
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
    return NetworkImage(pet['pozaUrl'] ?? 'https://images.unsplash.com/photo-1543852786-1cf6624b9987');
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
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
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
                              ownerInfo['bio'] ?? '',
                              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: () async {
                                final dateNoi = await showDialog<Map<String, dynamic>>(
                                  context: context,
                                  builder: (_) => EditProfileDialog(currentInfo: ownerInfo),
                                );
                                if (dateNoi != null) {
                                  _updateUserProfile(dateNoi);
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
                                side: const BorderSide(color: Color(0xFF1F6E6C), width: 1.5),
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Divider(color: Colors.black.withOpacity(0.08)),
                      const SizedBox(height: 12),

                      // Identity Verification Section
                      _buildIdentityVerificationSection(),

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
                        child: _isLoadingPets
                            ? const Center(child: CircularProgressIndicator())
                            : ListView.builder(
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
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isIdentityVerified
                ? const Color(0xFF2ECC40).withOpacity(0.15)
                : (isDocumentPending
                    ? Colors.amber.withOpacity(0.15)
                    : const Color(0xFF1F6E6C).withOpacity(0.15)),
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
                          : "Upload ID card to verify identity (18+)"),
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
        if (actiune == 'delete' || actiune == 'sterge') {
          if (pet['id'] != null) {
            _deletePet(pet['id']);
          } else {
            setState(() => myPets.remove(pet));
          }
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
              pet['nume'] ?? '',
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
          _addNewPet(animalNou);
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