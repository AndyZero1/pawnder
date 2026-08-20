import 'package:flutter/material.dart';
import 'event_details_screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final Color primaryColor = const Color(0xFF1F6E6C);

  // Lista demonstrativă
  final List<Map<String, dynamic>> _events = [
    {
      'id': '1',
      'title': 'Întâlnire Corgi & Prietenii',
      'location': 'Parcul Herăstrău',
      'date': 'Sâmbătă, 15 Oct',
      'time': '10:00',
      'attendees': 12,
      'icon': Icons.pets,
      'color': Colors.orangeAccent,
    },
    {
      'id': '2',
      'title': 'Târg de Adopții Animale',
      'location': 'Clinica VetLife',
      'date': 'Duminică, 16 Oct',
      'time': '14:00',
      'attendees': 45,
      'icon': Icons.volunteer_activism,
      'color': Colors.pinkAccent,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fundal ultra-deschis pentru a scoate cardurile albe în evidență
      backgroundColor: const Color(0xFFF8F9FA),

      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER MODERN ---
            Padding(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: 10,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Descoperă',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Evenimente Pawndar',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  // Butonul de adăugare direct în header
                  GestureDetector(
                    onTap: () => _showCreateEventModal(context),
                    child: Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryColor,
                            primaryColor.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 20),
                          SizedBox(width: 5),
                          Text(
                            'Nou',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // --- LISTA DE EVENIMENTE (FEED) ---
            Expanded(
              child: _events.isEmpty
                  ? Center(
                      child: Text(
                        'Niciun eveniment momentan.\nFii primul care organizează unul!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        bottom: 40,
                      ),
                      itemCount: _events.length,
                      itemBuilder: (context, index) {
                        return _buildModernEventCard(_events[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // --- DESIGN-UL MODERN AL CARDULUI ---
  Widget _buildModernEventCard(Map<String, dynamic> event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30), // Colțuri foarte rotunjite
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04), // Umbră extrem de fină
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Iconița stilizată într-un cub colorat
              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  color: event['color'].withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(event['icon'], color: event['color'], size: 30),
              ),
              const SizedBox(width: 15),
              // Detalii
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['title'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    // "Chip" pentru locație
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          color: Colors.grey.shade400,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          event['location'],
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Linia despărțitoare fină
          Divider(color: Colors.grey.shade100, thickness: 2),
          const SizedBox(height: 15),

          // Partea de jos: Data, Ora și Butonul
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Informații Dată & Oră (stil Chip)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      color: Colors.amber.shade700,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${event['date']} • ${event['time']}',
                      style: TextStyle(
                        color: Colors.amber.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // Butonul de participare sub formă de capsulă (Pill Button)
              ElevatedButton(
                onPressed: () async {

                  try {
                    final prefs = await SharedPreferences.getInstance();
                    final String? token = prefs.getString('auth_token');
                    
                    final String joinUrl = 'http://127.0.0.1:8000/api/events/${event['id']}/join/';

                    await http.post(
                      Uri.parse(joinUrl),
                      headers: {
                        'Content-Type': 'application/json',
                        if (token != null) 'Authorization': 'Bearer $token',
                      },
                    );
                  } catch (e) {
                    print("Eroare la conectarea cu serverul pentru Join: $e");
                  }

                  if (!context.mounted) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventDetailsScreen(
                        eventId: event['id']
                            .toString(), 
                        eventName: event['title'],
                        location: event['location'],
                        myName: 'Utilizator',
                        myPetInfo: 'Vezi pe profil',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87, // Contrast modern
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Participă',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- FORMULARUL DE CREARE ULTRA-MODERN (BOTTOM SHEET) ---
  void _showCreateEventModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 25,
            right: 25,
            top: 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(40),
            ), // Colțuri uriașe sus
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grabber Handle
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Organizează un Eveniment',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Adună comunitatea Pawndar la un loc!',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
              ),
              const SizedBox(height: 35),

              _buildModernTextField(
                label: 'Numele evenimentului',
                icon: Icons.event_note_rounded,
              ),
              const SizedBox(height: 20),

              _buildModernTextField(
                label: 'Locația (Adresă sau Parc)',
                icon: Icons.location_on_rounded,
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _buildModernTextField(
                      label: 'Data',
                      icon: Icons.calendar_today_rounded,
                      isReadOnly: true,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildModernTextField(
                      label: 'Ora',
                      icon: Icons.access_time_rounded,
                      isReadOnly: true,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Butonul Mare de Salvare
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Eveniment publicat!'),
                        backgroundColor: primaryColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    elevation: 10,
                    shadowColor: primaryColor.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Publică Evenimentul',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  // Helper pentru a desena textField-uri moderne (gri, rotunjite, fără dungi)
  Widget _buildModernTextField({
    required String label,
    required IconData icon,
    bool isReadOnly = false,
  }) {
    return TextField(
      readOnly: isReadOnly,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
      ),
    );
  }
}