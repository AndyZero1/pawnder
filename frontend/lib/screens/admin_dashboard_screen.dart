import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  
  final List<Map<String, dynamic>> _cereriVerificare = [
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

  // --- MODERATION: REPORTED USERS ---
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
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Pawnder",
                            style: GoogleFonts.pacifico(
                              fontSize: 30,
                              color: const Color(0xFF1F6E6C),
                            ),
                          ),
                        ],
                      ),
                      // Logout
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
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    tabs: const [
                      Tab(icon: Icon(Icons.pending_actions_rounded), text: "Verification Requests"),
                      Tab(icon: Icon(Icons.gavel_rounded), text: "Moderation Tools"),
                    ],
                  ),
                ],
              ),
            ),

           
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildVerificariTab(),
                  _buildModerareTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  
  Widget _buildVerificariTab() {
    if (_cereriVerificare.isEmpty) {
      return const Center(
        child: Text(
          "No pending verification requests 🎉",
          style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cereriVerificare.length,
      itemBuilder: (context, index) {
        final cerere = _cereriVerificare[index];
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
                    // Reject
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _cereriVerificare.removeAt(index);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Verification request rejected.')),
                        );
                      },
                      child: const Text("Reject", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    // Approve
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _cereriVerificare.removeAt(index);
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
