import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../constants/api_constants.dart';
import '../map_screen.dart';
import '../modern_nav_bar.dart';

class PetMatchingScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const PetMatchingScreen({
    super.key,
    this.userData = const {},
  });

  @override
  State<PetMatchingScreen> createState() => _PetMatchingScreenState();
}

class _PetMatchingScreenState extends State<PetMatchingScreen> {
  String get baseUrl => ApiConstants.baseUrl;

  String get wsUrl {
    if (kIsWeb) return 'ws://localhost:8000';
    if (Platform.isAndroid) return 'ws://10.0.2.2:8000';
    return 'ws://localhost:8000';
  }

  String get userId {
    final data = widget.userData;
    if (data['user'] != null && data['user'] is Map) {
      return data['user']['id']?.toString() ?? data['user']['user_id']?.toString() ?? '';
    }
    return data['id']?.toString() ?? data['user_id']?.toString() ?? '';
  }

  List<Map<String, dynamic>> pets = [];
  List<Map<String, dynamic>> matches = [];

  int currentIndex = 0;
  Offset cardOffset = Offset.zero;

  bool isAnimating = false;
  bool isFlipped = false;
  bool isLoading = true;

  String? errorMessage;

  static const double swipeThreshold = 120;

  @override
  void initState() {
    super.initState();
    _loadPets();
    _loadMatches();
  }

  Future<String?> _getToken() async {
    if (widget.userData['token'] != null && widget.userData['token'].toString().isNotEmpty) {
      return widget.userData['token'].toString();
    }

    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token') ?? prefs.getString('auth_token');
    return (token != null && token.isNotEmpty) ? token : null;
  }

  Future<void> _loadPets() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final token = await _getToken();

      if (token == null) {
        if (!mounted) return;
        setState(() {
          errorMessage = 'Authentication required.\nPlease sign in from the login screen.';
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/pets/matching/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        setState(() {
          pets = data.map((pet) => Map<String, dynamic>.from(pet)).toList();
          currentIndex = 0;
          isLoading = false;
        });
      } else if (response.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('jwt_token');
        await prefs.remove('auth_token');
        setState(() {
          errorMessage = 'Session expired. Please sign in again.';
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Server error (${response.statusCode}):\n${response.body}';
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Cannot connect to server ($baseUrl):\n$e';
        isLoading = false;
      });
    }
  }

  Future<void> _loadMatches() async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$baseUrl/api/pets/matches/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 8));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          matches = data.map((m) => Map<String, dynamic>.from(m)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading matches: $e');
    }
  }

  Future<void> _resetSwipes() async {
    setState(() => isLoading = true);
    try {
      final token = await _getToken();
      if (token != null) {
        await http.post(
          Uri.parse('$baseUrl/api/pets/reset-swipes/'),
          headers: {'Authorization': 'Bearer $token'},
        );
      }
      await _loadPets();
      await _loadMatches();
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error resetting swipes: $e')),
      );
    }
  }

  Future<void> _sendSwipe(Map<String, dynamic> pet, bool liked) async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final petId = pet['id'];

      final response = await http.post(
        Uri.parse('$baseUrl/api/pets/$petId/swipe/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'is_like': liked}),
      ).timeout(const Duration(seconds: 8));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isMatch = data['is_match'] == true;

        if (isMatch) {
          await _loadMatches();
          _showMatchDialog(pet);
        }
      }
    } catch (e) {
      debugPrint('Swipe error: $e');
    }
  }

  void _showMatchDialog(Map<String, dynamic> pet) {
    showDialog(
      context: context,
      builder: (context) {
        final owner = Map<String, dynamic>.from(pet['owner'] ?? {});
        final petImg = pet['petImage']?.toString() ?? '';
        final petName = pet['name']?.toString() ?? 'Pet';
        final ownerName = owner['name']?.toString() ?? 'Friend';

        return AlertDialog(
          backgroundColor: const Color(0xFFF8D7DF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Center(
            child: Text(
              "It's a Match!",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Color(0xFF1F6E6C),
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF1F6E6C), width: 3),
                  image: petImg.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(petImg),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: petImg.isEmpty
                    ? const Icon(Icons.pets, size: 50, color: Color(0xFF1F6E6C))
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                'You and $petName liked each other!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Owner: $ownerName',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1F6E6C),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Keep Swiping', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _openMatchesSheet();
              },
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('View Matches', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F6E6C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openMatchesSheet() {
    _loadMatches();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      enableDrag: false,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.70,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline, color: Color(0xFF1F6E6C), size: 24),
                        const SizedBox(width: 8),
                        const Text(
                          'Chats',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F6E6C),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: matches.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No chats yet',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Swipe like on other pets. When their owner likes your pet back, you will see your chats here.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: matches.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
                            itemBuilder: (context, index) {
                                final match = matches[index];
                                final otherUser = Map<String, dynamic>.from(match['other_user'] ?? {});
                                final theirPet = Map<String, dynamic>.from(match['their_pet'] ?? {});
                                final lastMsg = Map<String, dynamic>.from(match['last_message'] ?? {});

                                final username = otherUser['username']?.toString() ?? 'User';
                                final userPhoto = otherUser['photo_url']?.toString() ?? '';
                                final petName = theirPet['name']?.toString() ?? '';
                                final lastContent = lastMsg['content']?.toString();

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                                  leading: Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 26,
                                        backgroundColor: const Color(0xFF1F6E6C).withValues(alpha: 0.15),
                                        backgroundImage: userPhoto.isNotEmpty ? NetworkImage(userPhoto) : null,
                                        child: userPhoto.isEmpty
                                            ? const Icon(Icons.person, color: Color(0xFF1F6E6C))
                                            : null,
                                      ),
                                      if (theirPet['photo_url'] != null && theirPet['photo_url'].toString().isNotEmpty)
                                        Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white, width: 2),
                                              image: DecorationImage(
                                                image: NetworkImage(theirPet['photo_url']),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  title: Text(
                                    username,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (petName.isNotEmpty)
                                        Text(
                                          'Owner of $petName',
                                          style: const TextStyle(
                                            color: Color(0xFF1F6E6C),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      if (lastContent != null)
                                        Text(
                                          lastContent,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                        )
                                      else
                                        Text(
                                          'Matched! Tap to start chatting',
                                          style: TextStyle(color: Colors.grey[500], fontSize: 12, fontStyle: FontStyle.italic),
                                        ),
                                    ],
                                  ),
                                  trailing: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1F6E6C).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.chat_bubble_outline, size: 16, color: Color(0xFF1F6E6C)),
                                        SizedBox(width: 4),
                                        Text(
                                          'Chat',
                                          style: TextStyle(
                                            color: Color(0xFF1F6E6C),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _openChatDialog(match);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    }

  void _openChatDialog(Map<String, dynamic> match) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return MatchChatDialog(
          match: match,
          baseUrl: baseUrl,
          wsUrl: wsUrl,
          userId: userId,
          getToken: _getToken,
          onMessageSent: () => _loadMatches(),
        );
      },
    );
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (isAnimating || pets.isEmpty) return;
    setState(() {
      cardOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (isAnimating || pets.isEmpty) return;

    if (cardOffset.dx > swipeThreshold) {
      _swipeCard(true);
    } else if (cardOffset.dx < -swipeThreshold) {
      _swipeCard(false);
    } else {
      _returnCard();
    }
  }

  void _swipeCard(bool liked) {
    if (isAnimating || pets.isEmpty) return;

    final pet = pets[currentIndex];
    final screenWidth = MediaQuery.of(context).size.width;
    final direction = liked ? 1.0 : -1.0;

    setState(() {
      isAnimating = true;
      cardOffset = Offset(direction * screenWidth * 1.4, -40);
    });

    _sendSwipe(pet, liked);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      setState(() {
        pets.removeAt(currentIndex);
        if (pets.isNotEmpty) {
          currentIndex = 0;
        }
        cardOffset = Offset.zero;
        isFlipped = false;
        isAnimating = false;
      });
    });
  }

  void _returnCard() {
    setState(() {
      isAnimating = true;
      cardOffset = Offset.zero;
    });

    Future.delayed(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      setState(() {
        isAnimating = false;
      });
    });
  }

  void _flipCard() {
    if (isAnimating || pets.isEmpty) return;
    setState(() {
      isFlipped = !isFlipped;
    });
  }

  @override
  Widget build(BuildContext context) {
    final username = (widget.userData['user'] != null
            ? widget.userData['user']['username']
            : widget.userData['username']) ??
        'User';

    return Scaffold(
      backgroundColor: const Color(0xFFF8D7DF),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openMatchesSheet,
        backgroundColor: const Color(0xFF1F6E6C),
        foregroundColor: Colors.white,
        elevation: 6,
        icon: Badge(
          isLabelVisible: matches.isNotEmpty,
          label: Text('${matches.length}'),
          backgroundColor: Colors.redAccent,
          child: const Icon(Icons.chat_bubble_outline),
        ),
        label: const Text(
          'Chats',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            ModernNavBar(
              currentPage: 'Tinder',
              userData: widget.userData,
              onMapTap: () => Navigator.push(
                context,
                smoothRoute(
                  MapScreen(myPets: const [], userName: username),
                ),
              ),
            ),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF1F6E6C)),
            SizedBox(height: 16),
            Text(
              'Discovering pets...',
              style: TextStyle(
                color: Color(0xFF1F6E6C),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 60,
                color: Color(0xFF1F6E6C),
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadPets,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F6E6C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (pets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.pets,
                size: 70,
                color: Color(0xFF1F6E6C),
              ),
              const SizedBox(height: 16),
              const Text(
                'No more pets to discover right now',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You have reviewed all available profiles.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _resetSwipes,
                icon: const Icon(Icons.replay),
                label: const Text('Reset Swipes & Discover Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F6E6C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final nextIndex = pets.length > 1 ? (currentIndex + 1) % pets.length : 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableH = constraints.maxHeight;
        final bool needScroll = availableH < 460;

        final double cardHeight = (availableH - 160).clamp(220.0, 500.0);
        final double cardWidth = math.min(
          cardHeight * 0.72,
          math.min(constraints.maxWidth * 0.88, 390.0),
        );

        Widget content = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Let\'s find a new playmate',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  if (pets.length > 1)
                    _buildBackgroundCard(
                      pets[nextIndex],
                      cardWidth,
                      cardHeight,
                    ),
                  _buildActiveCard(
                    pets[currentIndex],
                    cardWidth,
                    cardHeight,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(
                  icon: Icons.close,
                  label: 'Nope',
                  color: Colors.redAccent,
                  onPressed: () => _swipeCard(false),
                ),
                const SizedBox(width: 40),
                _buildActionButton(
                  icon: Icons.favorite,
                  label: 'Like',
                  color: const Color(0xFF1F6E6C),
                  isLarge: true,
                  onPressed: () => _swipeCard(true),
                ),
              ],
            ),
          ],
        );

        return Center(
          child: needScroll
              ? SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: content,
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: content,
                ),
        );
      },
    );
  }

  Widget _buildActiveCard(
    Map<String, dynamic> pet,
    double width,
    double height,
  ) {
    final double rotation =
        (cardOffset.dx / 500).clamp(-0.35, 0.35).toDouble();

    return AnimatedContainer(
      duration: isAnimating
          ? const Duration(milliseconds: 300)
          : Duration.zero,
      curve: Curves.easeOut,
      transform: Matrix4.identity()
        ..translate(cardOffset.dx, cardOffset.dy)
        ..rotateZ(rotation),
      transformAlignment: Alignment.center,
      child: GestureDetector(
        onTap: _flipCard,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: _buildFlipCard(pet, width, height),
      ),
    );
  }

  Widget _buildFlipCard(
    Map<String, dynamic> pet,
    double width,
    double height,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: 0,
        end: isFlipped ? math.pi : 0,
      ),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      builder: (context, angle, child) {
        final isFront = angle <= math.pi / 2;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          child: isFront
              ? _buildPetFront(pet, width, height)
              : Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(math.pi),
                  child: _buildOwnerBack(pet, width, height),
                ),
        );
      },
    );
  }

  Widget _buildPetFront(
    Map<String, dynamic> pet,
    double width,
    double height,
  ) {
    final petImage = pet['petImage']?.toString() ?? '';
    final petName = pet['name']?.toString() ?? '';
    final petBreed = pet['breed']?.toString() ?? '';
    final petLocation = pet['location']?.toString() ?? '';
    final petDescription = pet['description']?.toString() ?? '';
    final petAge = pet['age'];

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (petImage.isNotEmpty)
              Image.network(
                petImage,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.pets, size: 80, color: Colors.grey),
                  );
                },
              )
            else
              Container(
                color: Colors.grey[200],
                child: const Icon(Icons.pets, size: 80, color: Colors.grey),
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.40, 0.70, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.25),
                      Colors.black.withValues(alpha: 0.88),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 22,
              right: 22,
              bottom: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          petName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (petAge != null)
                        Text(
                          '$petAge yrs',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  if (petBreed.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      petBreed,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (petLocation.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          petLocation,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (petDescription.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      petDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerBack(
    Map<String, dynamic> pet,
    double width,
    double height,
  ) {
    final owner = Map<String, dynamic>.from(pet['owner'] ?? {});
    final double avatarRadius = (height * 0.11).clamp(32.0, 56.0);
    final double gap = (height * 0.02).clamp(4.0, 14.0);
    final ownerImage = owner['ownerImage']?.toString() ?? '';
    final ownerName = owner['name']?.toString() ?? '';
    final ownerAge = owner['age'];
    final ownerBio = owner['bio']?.toString() ?? '';
    final petName = pet['name']?.toString() ?? '';

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: (height * 0.025).clamp(8.0, 18.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 4),
            CircleAvatar(
              radius: avatarRadius + 3,
              backgroundColor: const Color(0xFF1F6E6C),
              child: ownerImage.isNotEmpty
                  ? CircleAvatar(
                      radius: avatarRadius,
                      backgroundImage: NetworkImage(ownerImage),
                      onBackgroundImageError: (_, __) {},
                    )
                  : CircleAvatar(
                      radius: avatarRadius,
                      backgroundColor: Colors.grey[200],
                      child: const Icon(Icons.person, size: 40, color: Colors.grey),
                    ),
            ),
            SizedBox(height: gap * 0.5),
            Text(
              ownerName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: (height * 0.046).clamp(18.0, 24.0),
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (ownerAge != null)
              Text(
                '$ownerAge yrs',
                style: TextStyle(
                  fontSize: (height * 0.032).clamp(13.0, 16.0),
                  color: const Color(0xFF1F6E6C),
                  fontWeight: FontWeight.w600,
                ),
              ),
            SizedBox(height: gap * 0.5),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF8D7DF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.pets,
                    color: Color(0xFF1F6E6C),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Owner of $petName',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (ownerBio.isNotEmpty) ...[
              SizedBox(height: gap * 0.5),
              Text(
                ownerBio,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: (height * 0.028).clamp(12.0, 14.0),
                  height: 1.3,
                ),
              ),
            ],
            TextButton.icon(
              onPressed: _flipCard,
              icon: const Icon(
                Icons.arrow_back,
                color: Color(0xFF1F6E6C),
                size: 18,
              ),
              label: const Text(
                'Back to pet',
                style: TextStyle(
                  color: Color(0xFF1F6E6C),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundCard(
    Map<String, dynamic> pet,
    double width,
    double height,
  ) {
    final petImage = pet['petImage']?.toString() ?? '';

    return Transform.scale(
      scale: 0.94,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 15,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: petImage.isNotEmpty
              ? Image.network(
                  petImage,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.pets, size: 60, color: Colors.grey),
                  ),
                )
              : Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.pets, size: 60, color: Colors.grey),
                ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool isLarge = false,
  }) {
    final size = isLarge ? 68.0 : 56.0;

    return Column(
      children: [
        Material(
          color: Colors.white,
          elevation: 4,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(
                icon,
                color: color,
                size: isLarge ? 32 : 26,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class MatchChatDialog extends StatefulWidget {
  final Map<String, dynamic> match;
  final String baseUrl;
  final String wsUrl;
  final String userId;
  final Future<String?> Function() getToken;
  final VoidCallback onMessageSent;

  const MatchChatDialog({
    super.key,
    required this.match,
    required this.baseUrl,
    required this.wsUrl,
    required this.userId,
    required this.getToken,
    required this.onMessageSent,
  });

  @override
  State<MatchChatDialog> createState() => _MatchChatDialogState();
}

class _MatchChatDialogState extends State<MatchChatDialog> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  WebSocketChannel? _channel;

  String get matchId => widget.match['match_id']?.toString() ?? '';
  Map<String, dynamic> get otherUser => Map<String, dynamic>.from(widget.match['other_user'] ?? {});
  Map<String, dynamic> get theirPet => Map<String, dynamic>.from(widget.match['their_pet'] ?? {});

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _initWebSocket();
  }

  void _initWebSocket() {
    if (widget.userId.isEmpty) return;
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('${widget.wsUrl}/api/consultations/ws/${widget.userId}'),
      );
      _channel?.stream.listen((message) {
        try {
          final data = jsonDecode(message);
          if (data['event'] == 'NEW_MATCH_MESSAGE' && data['match_id'] == matchId) {
            final msgId = data['message_id'];
            final exists = _messages.any((m) => m['id'] == msgId);
            if (!exists) {
              setState(() {
                _messages.add({
                  'id': msgId,
                  'sender_id': data['sender_id'],
                  'sender_username': data['sender_username'],
                  'content': data['content'],
                  'sent_at': data['sent_at'],
                  'is_mine': data['sender_id'] == widget.userId,
                });
              });
              _scrollToBottom();
            }
          }
        } catch (e) {
          debugPrint('WebSocket message parse error: $e');
        }
      }, onError: (e) {
        debugPrint('WebSocket error: $e');
      });
    } catch (e) {
      debugPrint('WebSocket connection error: $e');
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages({bool silent = false}) async {
    if (matchId.isEmpty) return;
    try {
      final token = await widget.getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${widget.baseUrl}/api/pets/matches/$matchId/messages/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final newMsgs = data.map((m) => Map<String, dynamic>.from(m)).toList();

        final hasNew = newMsgs.length != _messages.length;
        setState(() {
          _messages = newMsgs;
          _isLoading = false;
        });

        if (hasNew) {
          _scrollToBottom();
        }
      }
    } catch (e) {
      if (!silent) debugPrint('Error fetching messages: $e');
      if (mounted && !silent) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _msgController.clear();

    try {
      final token = await widget.getToken();
      if (token == null) return;

      final response = await http.post(
        Uri.parse('${widget.baseUrl}/api/pets/matches/$matchId/messages/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'content': text}),
      );

      if (response.statusCode == 201) {
        widget.onMessageSent();
        await _fetchMessages(silent: true);
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = otherUser['username']?.toString() ?? 'Friend';
    final userPhoto = otherUser['photo_url']?.toString() ?? '';
    final petName = theirPet['name']?.toString() ?? '';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 480,
        height: 600,
        decoration: BoxDecoration(
          color: const Color(0xFFF8D7DF),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Column(
            children: [
              Container(
                color: const Color(0xFF1F6E6C),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      backgroundImage: userPhoto.isNotEmpty ? NetworkImage(userPhoto) : null,
                      child: userPhoto.isEmpty ? const Icon(Icons.person, color: Color(0xFF1F6E6C)) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (petName.isNotEmpty)
                            Text(
                              'Owner of $petName',
                              style: const TextStyle(
                                color: Color(0xFFF8D7DF),
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF1F6E6C)))
                    : _messages.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.waving_hand, size: 48, color: Color(0xFF1F6E6C)),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Say hello to $username!',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'You both liked each other\'s pets.',
                                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final msg = _messages[index];
                              final isMine = msg['is_mine'] == true;
                              final content = msg['content']?.toString() ?? '';
                              final timeStr = msg['sent_at'] != null && msg['sent_at'].toString().length >= 16
                                  ? msg['sent_at'].toString().substring(11, 16)
                                  : '';

                              return Align(
                                alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  constraints: const BoxConstraints(maxWidth: 280),
                                  decoration: BoxDecoration(
                                    color: isMine ? const Color(0xFF1F6E6C) : Colors.white,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft: Radius.circular(isMine ? 16 : 4),
                                      bottomRight: Radius.circular(isMine ? 4 : 16),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.06),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        content,
                                        style: TextStyle(
                                          color: isMine ? Colors.white : Colors.black87,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (timeStr.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          timeStr,
                                          style: TextStyle(
                                            color: isMine ? Colors.white70 : Colors.grey[500],
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgController,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                            filled: true,
                            fillColor: const Color(0xFFF8D7DF).withValues(alpha: 0.4),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: const Color(0xFF1F6E6C),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _sendMessage,
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(Icons.send, color: Colors.white, size: 20),
                          ),
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
    );
  }
}