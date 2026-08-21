import 'package:flutter/material.dart';
import 'event_details_screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final Color primaryColor = const Color(0xFF1F6E6C);

  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRealEvents();
  }

  Future<void> _fetchRealEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      
      final url = 'http://127.0.0.1:8000/api/events/nearby/?min_lat=-90&max_lat=90&min_lon=-180&max_lon=180';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        
        setState(() {
          _events = data.map((ev) {
            DateTime? startDate = ev['start_date'] != null ? DateTime.parse(ev['start_date']) : null;
            String formattedDate = startDate != null ? '${startDate.day}.${startDate.month}.${startDate.year}' : 'No date';
            String formattedTime = startDate != null ? '${startDate.hour.toString().padLeft(2, '0')}:${startDate.minute.toString().padLeft(2, '0')}' : '--:--';

            return {
              'id': ev['event_id'],
              'title': ev['title'] ?? 'Event',
              'location': ev['location_name'] ?? 'Unknown location',
              'date': formattedDate,
              'time': formattedTime,
              'attendees': ev['attendees_count'] ?? 0,
              'is_participating': ev['is_participating'] ?? false,
              'is_organizer': ev['is_organizer'] ?? false,
              'icon': Icons.pets,
              'color': Colors.purpleAccent, 
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- JOIN / LEAVE LOGIC ---
  Future<void> _joinEvent(String eventId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final url = 'http://127.0.0.1:8000/api/events/$eventId/join/';

      await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      // Refresh list after successful join
      _fetchRealEvents();
    } catch (e) {
      print("Join Error: $e");
    }
  }

  Future<void> _leaveEvent(String eventId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final url = 'http://127.0.0.1:8000/api/events/$eventId/leave/';

      await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      // Refresh list after successful leave
      _fetchRealEvents();
    } catch (e) {
      print("Leave Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // MODERN HEADER
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 10),
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
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Discover',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, height: 1.1, color: Colors.black87),
                      ),
                      Text(
                        'Pawnder Events',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _showCreateEventModal(context),
                    child: Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [primaryColor, primaryColor.withValues(alpha: 0.7)]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: primaryColor.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 20),
                          SizedBox(width: 5),
                          Text('New', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: _isLoading 
                ? Center(child: CircularProgressIndicator(color: primaryColor))
                : _events.isEmpty
                  ? Center(
                      child: Text(
                        'No events right now.\nBe the first to organize one!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40),
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

  Widget _buildModernEventCard(Map<String, dynamic> event) {
    bool isParticipating = event['is_participating'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 25, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 65, height: 65,
                decoration: BoxDecoration(
                  color: event['color'].withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(event['icon'], color: event['color'], size: 30),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['title'],
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, color: Colors.grey.shade400, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          event['location'],
                          style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.grey.shade100, thickness: 2),
          const SizedBox(height: 15),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, color: Colors.amber.shade700, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${event['date']} • ${event['time']}',
                      style: TextStyle(color: Colors.amber.shade800, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),

              // --- DYNAMIC BUTTONS (LEAVE / CHAT vs JOIN) ---
              Row(
                children: [
                  if (isParticipating) ...[
                    // LEAVE Button (Red)
                    TextButton(
                      onPressed: () => _leaveEvent(event['id'].toString()),
                      child: const Text('Leave', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    ),
                    // CHAT Button
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EventDetailsScreen(
                              eventId: event['id'].toString(), 
                              eventName: event['title'],
                              location: event['location'],
                              myName: 'User',
                              myPetInfo: 'See on profile',
                              isOrganizer: event['is_organizer'] == true,
                            ),
                          ),
                        ).then((_) => _fetchRealEvents());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('View Chat', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ] else ...[
                    // JOIN Button
                    ElevatedButton(
                      onPressed: () async {
                        await _joinEvent(event['id'].toString());
                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EventDetailsScreen(
                              eventId: event['id'].toString(), 
                              eventName: event['title'],
                              location: event['location'],
                              myName: 'User',
                              myPetInfo: 'See on profile',
                              isOrganizer: event['is_organizer'] == true,
                            ),
                          ),
                        ).then((_) => _fetchRealEvents());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('Join', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ]
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCreateEventModal(BuildContext context) {
    final nameController = TextEditingController();
    final detailsController = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            String getFormattedStart() {
              if (selectedDate == null || startTime == null) return 'Select start date and time';
              final day = selectedDate!.day.toString().padLeft(2, '0');
              final month = selectedDate!.month.toString().padLeft(2, '0');
              final h = startTime!.hour.toString().padLeft(2, '0');
              final m = startTime!.minute.toString().padLeft(2, '0');
              return '$day.$month.${selectedDate!.year} - $h:$m';
            }

            String getFormattedEnd() {
              if (endTime == null) return 'Select end time';
              final h = endTime!.hour.toString().padLeft(2, '0');
              final m = endTime!.minute.toString().padLeft(2, '0');
              return '$h:$m';
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 25, right: 25, top: 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 5,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text('Organize an Event', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.black87)),
                  const SizedBox(height: 5),
                  Text('Bring the Pawnder community together!', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                  const SizedBox(height: 35),
                  
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Event Name',
                      prefixIcon: Icon(Icons.event_note_rounded, color: Colors.grey.shade600),
                      filled: true, fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  TextField(
                    controller: detailsController,
                    decoration: InputDecoration(
                      labelText: 'Location (Details)',
                      prefixIcon: Icon(Icons.location_on_rounded, color: Colors.grey.shade600),
                      filled: true, fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Start Date
                  InkWell(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context, initialDate: DateTime.now(),
                        firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (pickedDate != null && context.mounted) {
                        final pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                        if (pickedTime != null) {
                          setStateModal(() { selectedDate = pickedDate; startTime = pickedTime; });
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month, color: Colors.grey.shade600),
                          const SizedBox(width: 12),
                          Expanded(child: Text('Starts: ${getFormattedStart()}')),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // End Time
                  InkWell(
                    onTap: () async {
                      if (selectedDate == null) return;
                      final pickedTime = await showTimePicker(context: context, initialTime: startTime ?? TimeOfDay.now());
                      if (pickedTime != null) setStateModal(() { endTime = pickedTime; });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        children: [
                          Icon(Icons.timer_off, color: Colors.grey.shade600),
                          const SizedBox(width: 12),
                          Expanded(child: Text('Ends at: ${getFormattedEnd()}')),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),
                  SizedBox(
                    width: double.infinity, height: 60,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty || selectedDate == null || startTime == null || endTime == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all fields!')));
                          return;
                        }

                        DateTime startDateTime = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day, startTime!.hour, startTime!.minute);
                        DateTime endDateTime = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day, endTime!.hour, endTime!.minute);

                        try {
                          final prefs = await SharedPreferences.getInstance();
                          final token = prefs.getString('jwt_token');
                          final apiUrl = 'http://127.0.0.1:8000/api/events/create/';

                          final response = await http.post(
                            Uri.parse(apiUrl),
                            headers: {
                              'Content-Type': 'application/json',
                              if (token != null) 'Authorization': 'Bearer $token',
                            },
                            body: jsonEncode({
                              "name": nameController.text.trim(),
                              "details": detailsController.text.trim(),
                              "latitude": 44.4268,
                              "longitude": 26.1025,
                              "start_date": startDateTime.toIso8601String(),
                              "end_time": endDateTime.toIso8601String(),
                            }),
                          );

                          if (context.mounted) {
                            Navigator.pop(context); // Close modal
                            if (response.statusCode == 200 || response.statusCode == 201) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event published!')));
                              // 🔄 REFRESH AFTER CREATION
                              _fetchRealEvents();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${response.statusCode}')));
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection error.')));
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('Publish Event', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        );
      },
    );
  }
}