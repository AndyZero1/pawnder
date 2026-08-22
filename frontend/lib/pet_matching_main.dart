import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';
import '../map_screen.dart';
import '../modern_nav_bar.dart';

class PetMatchingScreen extends StatefulWidget {
  const PetMatchingScreen({super.key});

  @override
  State<PetMatchingScreen> createState() => _PetMatchingScreenState();
}

class _PetMatchingScreenState extends State<PetMatchingScreen> {
  String get baseUrl => ApiConstants.baseUrl;

  List<Map<String, dynamic>> pets = [];

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
  }

  Future<String?> _getOrFetchToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/api/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': 'adrian@pawnder.com',
            'password': 'password123',
          }),
        ).timeout(const Duration(seconds: 4));
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          token = data['token'];
          if (token != null) {
            await prefs.setString('auth_token', token);
          }
        }
      } catch (e) {
        debugPrint('Auto-login network error: $e');
      }
    }
    return token;
  }

  Future<void> _loadPets() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final token = await _getOrFetchToken();

      if (token == null) {
        if (!mounted) return;
        setState(() {
          errorMessage = 'Authentication required.\nCould not connect to $baseUrl';
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/pets/matching/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 6));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        setState(() {
          pets = data.map((pet) => Map<String, dynamic>.from(pet)).toList();
          currentIndex = 0;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load pets. Status: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Connection error ($baseUrl): $e';
        isLoading = false;
      });
    }
  }

  Future<void> _resetSwipes() async {
    setState(() => isLoading = true);
    try {
      final token = await _getOrFetchToken();
      if (token != null) {
        await http.post(
          Uri.parse('$baseUrl/api/pets/reset-swipes/'),
          headers: {'Authorization': 'Bearer $token'},
        );
      }
      await _loadPets();
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error resetting swipes: $e')),
      );
    }
  }

  Future<void> _sendSwipe(
    Map<String, dynamic> pet,
    bool liked,
  ) async {
    try {
      final token = await _getOrFetchToken();
      if (token == null) return;

      final petId = pet['id'];

      final response = await http.post(
        Uri.parse('$baseUrl/api/pets/$petId/swipe/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'is_like': liked,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['is_match'] == true) {
          _showMatchDialog(pet);
        }
      } else {
        debugPrint('Swipe failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Swipe connection error: $e');
    }
  }

  void _showMatchDialog(Map<String, dynamic> pet) {
    showDialog(
      context: context,
      builder: (context) {
        final owner = Map<String, dynamic>.from(pet['owner'] ?? {});
        final petImg = pet['petImage']?.toString() ?? '';

        return AlertDialog(
          backgroundColor: const Color(0xFFF8D7DF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Center(
            child: Text(
              "It's a Match! 🐾",
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
                'You and ${pet['name']} liked each other!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Owner: ${owner['name'] ?? 'Friend'}',
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
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F6E6C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Keep Swiping', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
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
      cardOffset = Offset(
        direction * screenWidth * 1.4,
        -40,
      );
    });

    _sendSwipe(pet, liked);

    Future.delayed(
      const Duration(milliseconds: 300),
      () {
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
      },
    );
  }

  void _returnCard() {
    setState(() {
      isAnimating = true;
      cardOffset = Offset.zero;
    });

    Future.delayed(
      const Duration(milliseconds: 220),
      () {
        if (!mounted) return;

        setState(() {
          isAnimating = false;
        });
      },
    );
  }

  void _flipCard() {
    if (isAnimating || pets.isEmpty) return;

    setState(() {
      isFlipped = !isFlipped;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8D7DF),
      body: SafeArea(
        child: Column(
          children: [
            ModernNavBar(
              currentPage: 'Tinder',
              onMapTap: () => Navigator.push(
                context,
                smoothRoute(
                  const MapScreen(
                    myPets: [],
                    userName: 'Adrian',
                  ),
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
        child: CircularProgressIndicator(
          color: Color(0xFF1F6E6C),
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
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
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
                'No more pets to discover right now 🐾',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You have reviewed all available profiles.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
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

    final nextIndex =
        pets.length > 1 ? (currentIndex + 1) % pets.length : 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableH = constraints.maxHeight;
        final bool needScroll = availableH < 460;

        final double cardHeight =
            (availableH - 160).clamp(220.0, 500.0);

        final double cardWidth = math.min(
          cardHeight * 0.72,
          math.min(
            constraints.maxWidth * 0.88,
            390.0,
          ),
        );

        Widget content = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Let’s find a new playmate 🐾',
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
                  onPressed: () {
                    _swipeCard(false);
                  },
                ),
                const SizedBox(width: 40),
                _buildActionButton(
                  icon: Icons.favorite,
                  label: 'Like',
                  color: const Color(0xFF1F6E6C),
                  isLarge: true,
                  onPressed: () {
                    _swipeCard(true);
                  },
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
        child: _buildFlipCard(
          pet,
          width,
          height,
        ),
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
              ? _buildPetFront(
                  pet,
                  width,
                  height,
                )
              : Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..rotateY(math.pi),
                  child: _buildOwnerBack(
                    pet,
                    width,
                    height,
                  ),
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
                    child: const Icon(
                      Icons.pets,
                      size: 80,
                      color: Colors.grey,
                    ),
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
                          '${pet['name'] ?? 'Pet'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${pet['age'] ?? 2} yrs',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pet['breed'] ?? 'Unknown'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
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
                        '${pet['location'] ?? 'Bucharest'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${pet['description'] ?? ''}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap card to see owner info 👆',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
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
    final owner =
        Map<String, dynamic>.from(pet['owner'] ?? {});

    final double avatarRadius =
        (height * 0.11).clamp(32.0, 56.0);

    final double gap =
        (height * 0.02).clamp(4.0, 14.0);

    final ownerImage =
        owner['ownerImage']?.toString() ?? '';

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
          vertical:
              (height * 0.025).clamp(8.0, 18.0),
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 4),
            CircleAvatar(
              radius: avatarRadius + 3,
              backgroundColor:
                  const Color(0xFF1F6E6C),
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: Colors.grey[200],
                backgroundImage: ownerImage.isNotEmpty
                    ? NetworkImage(ownerImage)
                    : null,
              ),
            ),
            SizedBox(height: gap * 0.5),
            Text(
              '${owner['name'] ?? 'Pet Owner'}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize:
                    (height * 0.046).clamp(18.0, 24.0),
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              '${owner['age'] ?? 25} yrs',
              style: TextStyle(
                fontSize:
                    (height * 0.032).clamp(13.0, 16.0),
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
                borderRadius:
                    BorderRadius.circular(12),
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
                    'Owner of ${pet['name']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: gap * 0.5),
            Text(
              '${owner['bio'] ?? 'Animal lover.'}',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize:
                    (height * 0.028).clamp(12.0, 14.0),
                height: 1.3,
              ),
            ),
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
          child: Image.network(
            '${pet['petImage']}',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(
                  Icons.pets,
                  size: 70,
                  color: Colors.grey,
                ),
              );
            },
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