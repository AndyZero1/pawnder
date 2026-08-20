import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _pendingIdentities = [];
  bool _isLoadingIdentities = true;
  String? _identitiesError;

  final List<Map<String, dynamic>> _cereriClinici = [
    {
      'id': '1',
      'nume': 'Pipera Veterinary Clinic',
      'adresa': '45 Pipera Boulevard, Ilfov',
      'solicitant': 'Dr. Michael Jones',
      'data': '18.08.2026',
    },
    {
      'id': '2',
      'nume': 'HappyPets Medical Center',
      'adresa': '180 Mosilor Avenue, Bucharest',
      'solicitant': 'Dr. Mary Smith',
      'data': '19.08.2026',
    },
  ];

  final List<Map<String, dynamic>> _anunturiRaportate = [
    {
      'id': '1',
      'titlu': 'Rocky (Beagle)',
      'detalii': 'Lost in Herastrau Park area. Red collar.',
      'motiv': 'False information / Duplicate post',
      'raportatDe': 'Alex22',
    },
  ];

  final List<Map<String, dynamic>> _utilizatoriRaportati = [
    {
      'nume': 'Spammer Bot',
      'email': 'spam_bot@badguy.com',
      'motiv': 'Repeatedly posting suspicious links',
      'raportari': 5,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchPendingIdentities();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchPendingIdentities() async {
    setState(() {
      _isLoadingIdentities = true;
      _identitiesError = null;
    });

    final baseUrl = ApiConstants.baseUrl;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/pending-identities/'),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _pendingIdentities = data.map((e) => Map<String, dynamic>.from(e)).toList();
          _isLoadingIdentities = false;
        });
      } else {
        setState(() {
          _identitiesError = 'Status: ${response.statusCode}';
          _isLoadingIdentities = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _identitiesError = '$e';
        _isLoadingIdentities = false;
      });
    }
  }

  Future<void> _approveIdentity(String userId, String username) async {
    final baseUrl = ApiConstants.baseUrl;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/approve-identity/$userId'),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _pendingIdentities.removeWhere((item) => item['id'] == userId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Identity for $username approved successfully! 🟢'),
            backgroundColor: const Color(0xFF2ECC40),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error approving identity: ${response.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error: $e')),
      );
    }
  }

  Future<void> _rejectIdentity(String userId, String username) async {
    final baseUrl = ApiConstants.baseUrl;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/reject-identity/$userId'),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _pendingIdentities.removeWhere((item) => item['id'] == userId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document for $username rejected.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rejecting: ${response.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error: $e')),
      );
    }
  }

  void _showDocumentPreview(String imageUrl, String username) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ID Document - $username',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    padding: const EdgeInsets.all(40),
                    child: const Column(
                      children: [
                        Icon(Icons.broken_image, size: 60, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Document image unavailable'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8D7DF),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Pawnder",
                            style: GoogleFonts.pacifico(
                              fontSize: 30,
                              color: const Color(0xFF1F6E6C),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F6E6C).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "Admin Panel",
                              style: TextStyle(
                                color: Color(0xFF1F6E6C),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[50],
                          foregroundColor: Colors.red[700],
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Logout", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: const Color(0xFF1F6E6C),
                    labelColor: const Color(0xFF1F6E6C),
                    unselectedLabelColor: Colors.grey[600],
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    tabs: const [
                      Tab(icon: Icon(Icons.badge_outlined), text: "ID Verification"),
                      Tab(icon: Icon(Icons.local_hospital_outlined), text: "Clinics & Vets"),
                      Tab(icon: Icon(Icons.gavel_rounded), text: "Moderation"),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildIdentitiesTab(),
                  _buildCliniciTab(),
                  _buildModerareTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentitiesTab() {
    if (_isLoadingIdentities) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1F6E6C)),
      );
    }

    if (_identitiesError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 50, color: Color(0xFF1F6E6C)),
            const SizedBox(height: 12),
            Text('Eroare: $_identitiesError'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchPendingIdentities,
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    if (_pendingIdentities.isEmpty) {
      return const Center(
        child: Text(
          "No pending ID verification requests",
          style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchPendingIdentities,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingIdentities.length,
        itemBuilder: (context, index) {
          final user = _pendingIdentities[index];
          final String userId = user['id'] ?? '';
          final String username = user['username'] ?? 'User';
          final String email = user['email'] ?? '';
          final int age = user['age'] ?? 18;
          final String idCardUrl = user['id_card_url'] ?? '';
          final String dateStr = user['created_at'] ?? 'Azi';

          return Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.only(bottom: 14),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFF1F6E6C).withValues(alpha: 0.1),
                            child: const Icon(Icons.person, color: Color(0xFF1F6E6C)),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                username,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                email,
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber),
                        ),
                        child: const Text(
                          "Pending Review",
                          style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text("Age: $age yrs", style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                      const SizedBox(width: 16),
                      Text("Date: $dateStr", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (idCardUrl.isNotEmpty) ...[
                    GestureDetector(
                      onTap: () => _showDocumentPreview(idCardUrl, username),
                      child: Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                idCardUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: Colors.grey[100],
                                  child: const Center(
                                    child: Icon(Icons.badge, size: 40, color: Colors.grey),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 8,
                                bottom: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.zoom_in, color: Colors.white, size: 14),
                                      SizedBox(width: 4),
                                      Text(
                                        "View Document",
                                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _rejectIdentity(userId, username),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text("Reject", style: TextStyle(fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _approveIdentity(userId, username),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text("Approve Identity", style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2ECC40),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCliniciTab() {
    if (_cereriClinici.isEmpty) {
      return const Center(
        child: Text(
          "No pending clinic verification requests",
          style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cereriClinici.length,
      itemBuilder: (context, index) {
        final cerere = _cereriClinici[index];
        return Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      cerere['nume'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F6E6C)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber),
                      ),
                      child: const Text(
                        "Pending",
                        style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text("Address: ${cerere['adresa']}", style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                Text("Applicant: ${cerere['solicitant']}", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Text("Request Date: ${cerere['data']}", style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _cereriClinici.removeAt(index);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Verification request rejected.')),
                        );
                      },
                      child: const Text("Reject", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _cereriClinici.removeAt(index);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Clinic successfully verified! 🟢')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2ECC40),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Approve & Verify", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModerareTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text("Reported Announcements", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          _buildReportedAnnouncements(),
          const SizedBox(height: 25),
          const Row(
            children: [
              Icon(Icons.person_outline, color: Colors.red),
              SizedBox(width: 8),
              Text("Reported Users", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          _buildReportedUsers(),
        ],
      ),
    );
  }

  Widget _buildReportedAnnouncements() {
    if (_anunturiRaportate.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("No active reported announcements."),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _anunturiRaportate.length,
      itemBuilder: (context, index) {
        final anunt = _anunturiRaportate[index];
        return Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  anunt['titlu'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(anunt['detalii'], style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    "Reason: ${anunt['motiv']} (Reported by: ${anunt['raportatDe']})",
                    style: TextStyle(color: Colors.red[700], fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _anunturiRaportate.removeAt(index);
                        });
                      },
                      child: const Text("Keep", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _anunturiRaportate.removeAt(index);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reported announcement deleted.')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Delete Post", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportedUsers() {
    if (_utilizatoriRaportati.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("No reported users."),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _utilizatoriRaportati.length,
      itemBuilder: (context, index) {
        final user = _utilizatoriRaportati[index];
        return Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      user['nume'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      "Reports: ${user['raportari']}",
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
                Text(user['email'], style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(height: 6),
                Text("Report reason: ${user['motiv']}", style: TextStyle(color: Colors.grey[800], fontSize: 13)),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _utilizatoriRaportati.removeAt(index);
                        });
                      },
                      child: const Text("Ignore", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _utilizatoriRaportati.removeAt(index);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('User has been blocked (Banned).')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Block User", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
