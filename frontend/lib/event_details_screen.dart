import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class EventDetailsScreen extends StatefulWidget {
  final String eventId;  
  final String eventName;
  final String location;
  final String myName; 
  final String myPetInfo; 

  const EventDetailsScreen({
    super.key,
    required this.eventId,
    required this.eventName,
    required this.location,
    required this.myName,
    required this.myPetInfo,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  final Color primaryColor = const Color(0xFF1F6E6C);
  final TextEditingController _chatController = TextEditingController();

  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _members = [
      {"name": "${widget.myName} (You)", "pet": widget.myPetInfo},
    ];
    _fetchEventData();
  }

  // function to get chat and participants from server
  Future<void> _fetchEventData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      // API routes (Adjust them if your teammate named them differently)
      final membersUrl = 'http://10.0.2.2:8000/api/map/event/${widget.eventId}/members/';
      final chatUrl = 'http://10.0.2.2:8000/api/map/event/${widget.eventId}/chat/';

      // get participants
      final membersResponse = await http.get(Uri.parse(membersUrl), headers: headers);
      if (membersResponse.statusCode == 200) {
        List<dynamic> serverMembers = jsonDecode(membersResponse.body);
        setState(() {
          _members = serverMembers.map((m) => {
            "name": m['user_name'] ?? 'Unknown',
            "pet": m['pet_details'] ?? 'No pet',
          }).toList();
          
          // make sure you are on the list
          bool iAmInList = _members.any((m) => m['name'].toString().contains(widget.myName));
          if (!iAmInList) {
             _members.insert(0, {"name": "${widget.myName} (You)", "pet": widget.myPetInfo});
          }
        });
      }

      //  get messages
      final chatResponse = await http.get(Uri.parse(chatUrl), headers: headers);
      if (chatResponse.statusCode == 200) {
        List<dynamic> serverChat = jsonDecode(chatResponse.body);
        setState(() {
          _messages = serverChat.map((msg) => {
            "name": msg['user_name'] ?? 'Unknown',
            "text": msg['message'] ?? '',
            "isMe": msg['user_name'] == widget.myName, // check if the message is yours
            "time": msg['timestamp'] ?? 'Now',
          }).toList();
        });
      }
    } catch (e) {
      print("Eroare la aducerea datelor: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // function that sends the message to server
  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({
        "name": widget.myName,
        "text": text,
        "isMe": true,
        "time": "Sending...",
      });
      _chatController.clear();
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      
      final String chatUrl = 'http://10.0.2.2:8000/api/map/event/${widget.eventId}/chat/';

      final response = await http.post(
        Uri.parse(chatUrl),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({"message": text}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _fetchEventData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error sending message.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No internet connection.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, 
      child: Scaffold(
        backgroundColor: const Color(0xFFF8D7DF),
        appBar: AppBar(
          backgroundColor: primaryColor,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.eventName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(widget.location, style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.chat_bubble_outline), text: 'Group Chat'),
              Tab(icon: Icon(Icons.people_alt_outlined), text: 'Participants'),
            ],
          ),
        ),
        body: _isLoading 
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : TabBarView(
              children: [
                _buildChatTab(),
                _buildMembersTab(),
              ],
            ),
      ),
    );
  }

  Widget _buildChatTab() {
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty 
          ? const Center(child: Text('Be the first to leave a message!', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              final isMe = msg['isMe'] == true;

              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? primaryColor : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(15),
                      topRight: const Radius.circular(15),
                      bottomLeft: isMe ? const Radius.circular(15) : const Radius.circular(0),
                      bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(15),
                    ),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isMe) ...[
                        Text(msg['name'], style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber.shade700)),
                        const SizedBox(height: 3),
                      ],
                      Text(
                        msg['text'],
                        style: TextStyle(fontSize: 15, color: isMe ? Colors.white : Colors.black87),
                      ),
                      const SizedBox(height: 5),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(msg['time'], style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.grey)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))]),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    decoration: InputDecoration(
                      hintText: 'Write a message to the group...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: primaryColor,
                  radius: 22,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildMembersTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: _members.length,
      itemBuilder: (context, index) {
        final member = _members[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: primaryColor.withValues(alpha: 0.2),
              child: Icon(Icons.person, color: primaryColor),
            ),
            title: Text(member['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Coming with: ${member['pet']}'),
            trailing: IconButton(
              icon: const Icon(Icons.pets, color: Colors.grey),
              onPressed: () {},
            ),
          ),
        );
      },
    );
  }
}
