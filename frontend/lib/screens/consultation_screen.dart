import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../modern_nav_bar.dart';
import '../map_screen.dart';

class ConsultationScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ConsultationScreen({
    super.key,
    this.userData = const {},
  });

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  static const Color _teal = Color(0xFF1F6E6C);
  static const Color _bgPink = Color(0xFFF8D7DF);

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
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

  String get username {
    final user = widget.userData['user'] ?? widget.userData;
    return user['username'] ?? 'User';
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
                'sender': decoded['sender_username'] ?? 'User',
                'content': decoded['content'],
                'isMe': false,
                'isAI': false,
                'time': _getCurrentTimeString(),
              });
            });
            _scrollToBottom();
          }
        },
        onError: (error) => debugPrint('WebSocket error: $error'),
      );
    } catch (e) {
      debugPrint('Couldn\'t connect to WebSocket: $e');
    }
  }

  String _getCurrentTimeString() {
    final now = TimeOfDay.now();
    final minuteStr = now.minute < 10 ? '0${now.minute}' : '${now.minute}';
    return '${now.hour}:$minuteStr';
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
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
        'time': _getCurrentTimeString(),
      });
    });
    _messageController.clear();
    _scrollToBottom();

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
                'time': _getCurrentTimeString(),
              });
            });
            _scrollToBottom();
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
    _chatScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool canType = userRole != 'VETERINARY' || _activeConsultationId != null;

    return Scaffold(
      backgroundColor: _bgPink,
      body: SafeArea(
        child: Column(
          children: [
            ModernNavBar(
              currentPage: 'Consultations',
              userData: widget.userData,
              onMapTap: () => Navigator.push(
                context,
                smoothRoute(
                  MapScreen(myPets: const [], userName: username),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 18,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildChatHeader(),
                          const Divider(height: 1),
                          Expanded(
                            child: _messages.isEmpty
                                ? _buildEmptyState()
                                : ListView.builder(
                                    controller: _chatScrollController,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    itemCount: _messages.length,
                                    itemBuilder: (context, index) {
                                      final msg = _messages[index];
                                      final isMe = msg['isMe'] == true;
                                      return _buildMessageBubble(msg, isMe);
                                    },
                                  ),
                          ),
                          if (canType) ...[
                            const Divider(height: 1),
                            _buildChatInput(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatHeader() {
    final isVet = userRole == 'VETERINARY';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: _teal.withOpacity(0.12),
                child: Icon(
                  isVet ? Icons.person_outline_rounded : Icons.medical_services_rounded,
                  color: _teal,
                  size: 24,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isVet
                      ? (_activeClientName != null ? 'Patient: $_activeClientName' : 'Waiting for Patients')
                      : 'Veterinary Consultation',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  isVet ? 'Live Consultation Channel' : 'Pawnder Verified Network',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isVet = userRole == 'VETERINARY';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _teal.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isVet ? Icons.medical_services_outlined : Icons.chat_bubble_outline_rounded,
                size: 46,
                color: _teal,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isVet ? 'No Incoming Consultations' : 'Start a Consultation',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isVet
                  ? 'You are active online. New patient messages will appear here live.'
                  : 'Ask a question, describe your pet\'s symptoms, or get automated preliminary advice.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe) {
    final isAI = msg['isAI'] == true;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: isAI ? const Color(0xFFC0392B).withOpacity(0.15) : _teal.withOpacity(0.15),
              child: Icon(
                isAI ? Icons.smart_toy_outlined : Icons.medical_services,
                size: 14,
                color: isAI ? const Color(0xFFC0392B) : _teal,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe
                    ? _teal
                    : isAI
                        ? const Color(0xFFFFF3CD)
                        : Colors.grey.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        msg['sender'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isAI ? const Color(0xFFC0392B) : _teal,
                        ),
                      ),
                    ),
                  Text(
                    msg['content'] ?? '',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: isMe ? Colors.white : Colors.black87,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    msg['time'] ?? '',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: isMe ? Colors.white70 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildChatInput() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 3,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: userRole == 'VETERINARY'
                      ? 'Type your medical advice...'
                      : 'Type your message to the veterinarian...',
                  hintStyle: GoogleFonts.outfit(fontSize: 13, color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _isLoading
              ? const SizedBox(
                  width: 38,
                  height: 38,
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(strokeWidth: 2, color: _teal),
                  ),
                )
              : CircleAvatar(
                  backgroundColor: _teal,
                  radius: 20,
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    onPressed: _sendMessage,
                  ),
                ),
        ],
      ),
    );
  }
}
