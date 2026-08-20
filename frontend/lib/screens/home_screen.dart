import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../modern_nav_bar.dart';
import '../map_screen.dart';
import '../events_screen.dart';

class HomeScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const HomeScreen({
    super.key,
    this.userData = const {},
  });

  static const Color _teal = Color(0xFF1F6E6C);
  static const Color _bgPink = Color(0xFFF8D7DF);

  static final List<Map<String, dynamic>> _upcomingEvents = [
    {
      'title': 'Corgi & Friends Meeting',
      'location': 'Herastrau Park',
      'date': 'Sat, Oct 15',
      'time': '10:00',
      'color': const Color(0xFFFF9A3C),
      'icon': Icons.pets,
    },
    {
      'title': 'Animal Adoption Fair',
      'location': 'VetLife Clinic',
      'date': 'Sun, Oct 16',
      'time': '14:00',
      'color': const Color(0xFFFF6B8A),
      'icon': Icons.volunteer_activism,
    },
  ];

  static final List<Map<String, dynamic>> _nearbyClinics = [
    {
      'name': 'VetLife Clinic',
      'address': 'Bd. Unirii 14, Bucharest',
      'rating': 4.8,
      'open': true,
    },
    {
      'name': 'PetCare Center',
      'address': 'Calea Victoriei 32, Bucharest',
      'rating': 4.5,
      'open': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final username = (userData['user'] != null ? userData['user']['username'] : userData['username']) ?? 'User';

    return Scaffold(
      backgroundColor: _bgPink,
      body: SafeArea(
        child: Column(
          children: [
            ModernNavBar(
              currentPage: 'Main Page',
              userData: userData,
              onMapTap: () => Navigator.push(
                context,
                smoothRoute(
                  MapScreen(myPets: const [], userName: username),
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;
                  return Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWide ? 40 : 16,
                        vertical: isWide ? 16 : 18,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: isWide
                            ? _buildWideLayout(context)
                            : _buildNarrowLayout(context),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildEventsSection(context)),
        const SizedBox(width: 24),
        Expanded(child: _buildClinicsSection(context)),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEventsSection(context),
        const SizedBox(height: 28),
        _buildClinicsSection(context),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildEventsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          'Upcoming Events',
          onSeeAll: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EventsScreen()),
          ),
        ),
        const SizedBox(height: 12),
        ..._upcomingEvents.map((e) => _buildEventCard(context, e)),
      ],
    );
  }

  Widget _buildClinicsSection(BuildContext context) {
    final username = (userData['user'] != null ? userData['user']['username'] : userData['username']) ?? 'User';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          'Nearby Clinics',
          onSeeAll: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MapScreen(myPets: const [], userName: username),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ..._nearbyClinics.map((c) => _buildClinicCard(context, c)),
      ],
    );
  }

  Widget _buildEventCard(BuildContext context, Map<String, dynamic> event) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EventsScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (event['color'] as Color).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(event['icon'] as IconData,
                  color: event['color'] as Color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event['title'],
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 13, color: Colors.grey),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(event['location'],
                          style: GoogleFonts.outfit(
                              fontSize: 13, color: Colors.grey.shade500),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(event['date'],
                    style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _teal)),
                Text(event['time'],
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: Colors.grey.shade400)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClinicCard(BuildContext context, Map<String, dynamic> clinic) {
    final username = (userData['user'] != null ? userData['user']['username'] : userData['username']) ?? 'User';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MapScreen(myPets: const [], userName: username),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.local_hospital_rounded,
                  color: Colors.redAccent, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(clinic['name'],
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Colors.black87)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 13, color: Colors.grey),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(clinic['address'],
                          style: GoogleFonts.outfit(
                              fontSize: 13, color: Colors.grey.shade500),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(children: [
                  const Icon(Icons.star_rounded,
                      color: Colors.amber, size: 16),
                  const SizedBox(width: 3),
                  Text(clinic['rating'].toString(),
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Colors.black87)),
                ]),
                const SizedBox(height: 5),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: clinic['open'] == true
                        ? Colors.green.withValues(alpha: 0.12)
                        : Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    clinic['open'] == true ? 'Open' : 'Closed',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: clinic['open'] == true
                          ? Colors.green.shade700
                          : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, {required VoidCallback onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87)),
        GestureDetector(
          onTap: onSeeAll,
          child: Text('See all',
              style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _teal)),
        ),
      ],
    );
  }
}
