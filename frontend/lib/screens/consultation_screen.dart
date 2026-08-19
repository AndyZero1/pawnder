import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../constants/colors.dart';

class ConsultationScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ConsultationScreen({super.key, required this.userData});

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  WebSocketChannel? _channel;
  
  String? _activeConsultationId;
  String? _activeClientName;

  String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
  }

  String get wsUrl {
    if (kIsWeb) return 'ws://localhost:8000';
    if (Platform.isAndroid) return 'ws://10.0.2.2:8000';
    return 'ws://localhost:8000';
  }

  String get userId {
    final user = widget.userData['user'] ?? widget.userData;
    return user['id'] ?? '';
  }

  String get userRole {
    final user = widget.userData['user'] ?? widget.userData;
    return user['rol'] ?? 'OWNER';
  }

  @override
  void initState() {
    super.initState();
    _initWebSocket();
  }

  void _initWebSocket() {
    if (userId.isEmpty) return;
    try {
      final uri = Uri.parse('$wsUrl/api/consultations/ws/$userId');
      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        (data) {
          final decoded = jsonDecode(data);
          if (decoded['event'] == 'NEW_CONSULTATION_MESSAGE') {
            setState(() {
              _activeConsultationId = decoded['consultation_id'];
              _activeClientName = decoded['sender_username'] ?? 'Client';
              
              _messages.add({
                'sender': decoded['sender_username'] ?? 'Client',
                'content': decoded['content'],
                'isMe': false,
                'isAI': false,
              });
            });
          }
        },
        onError: (error) => debugPrint('WebSocket error: $error'),
      );
    } catch (e) {
      debugPrint('Couldn\'t connect to WebSocket: $e');
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (userRole == 'VETERINARY' && _activeConsultationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text('No active consultation selected to reply to.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _messages.add({
        'sender': 'Me',
        'content': text,
        'isMe': true,
        'isAI': false,
      });
    });
    _messageController.clear();

    try {
      if (userRole == 'VETERINARY') {
        final url = Uri.parse('$baseUrl/api/consultations/reply');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'vet_id': userId,
            'consultation_id': _activeConsultationId,
            'message': text,
          }),
        );
        final data = jsonDecode(response.body);
        if (response.statusCode != 200 && response.statusCode != 201) {
          throw Exception(data['detail'] ?? 'Failed to send reply.');
        }
      } else {
        final url = Uri.parse('$baseUrl/api/consultations/send');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'owner_id': userId,
            'message': text,
          }),
        );

        final data = jsonDecode(response.body);

        if (response.statusCode == 200 || response.statusCode == 201) {
          if (data['consultation_id'] != null) {
            _activeConsultationId = data['consultation_id'];
          }
          if (data['status'] == 'FALLBACK_TRIGGERED') {
            setState(() {
              _messages.add({
                'sender': 'Pawnder AI Assistant 🐾',
                'content': data['ai_response'] ?? 'No vet available.',
                'isMe': false,
                'isAI': true,
              });
            });
          }
        } else {
          throw Exception(data['detail'] ?? 'Error sending message.');
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Error: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool canType = userRole != 'VETERINARY' || _activeConsultationId != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          userRole == 'VETERINARY'
              ? (_activeClientName != null ? 'Chat: $_activeClientName' : 'Live Consultations')
              : 'Vet Consultation',
          style: GoogleFonts.pacifico(
            fontSize: 26,
            color: AppColors.brown,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.brown),
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  userRole == 'VETERINARY'
                                      ? Icons.medical_services_outlined
                                      : Icons.chat_bubble_outline_rounded,
                                  size: 70,
                                  color: AppColors.brown.withOpacity(0.5),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  userRole == 'VETERINARY'
                                      ? 'You are Online\nWaiting for incoming patient requests...'
                                      : 'Describe your pet\'s symptoms to start a consultation.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.brown,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            final isMe = msg['isMe'] == true;
                            final isAI = msg['isAI'] == true;

                            return Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                padding: const EdgeInsets.all(16),
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                                ),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? AppColors.blue
                                      : isAI
                                          ? AppColors.yellow
                                          : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(20),
                                    topRight: const Radius.circular(20),
                                    bottomLeft: Radius.circular(isMe ? 20 : 0),
                                    bottomRight: Radius.circular(isMe ? 0 : 20),
                                  ),
                                  border: Border.all(
                                    color: AppColors.brown.withOpacity(0.15),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!isMe)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 6),
                                        child: Text(
                                          msg['sender'],
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: isAI ? const Color(0xFFC0392B) : AppColors.brown,
                                          ),
                                        ),
                                      ),
                                    Text(
                                      msg['content'],
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: AppColors.brown,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                if (canType)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.inputField,
                        borderRadius: BorderRadius.circular(35),
                        border: Border.all(
                          color: AppColors.brown.withOpacity(0.2),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.edit_note, color: AppColors.brown, size: 28),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              minLines: 1,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: userRole == 'VETERINARY'
                                    ? "Reply with veterinary advice..."
                                    : "Describe the symptoms...",
                                hintStyle: const TextStyle(
                                  color: AppColors.brown,
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              style: const TextStyle(
                                color: AppColors.brown,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _isLoading
                              ? const SizedBox(
                                  width: 42,
                                  height: 42,
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: AppColors.brown,
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: AppColors.blue,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.12),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(
                                      Icons.send_rounded,
                                      color: AppColors.brown,
                                      size: 22,
                                    ),
                                    onPressed: _sendMessage,
                                  ),
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
    );
  }
}
