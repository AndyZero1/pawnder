import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../modern_nav_bar.dart';
import '../map_screen.dart';

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
  final List<Map<String, dynamic>> pets = [
    {
      'name': 'Max',
      'breed': 'Golden Retriever',
      'age': 3,
      'location': 'Bucharest',
      'description': 'Max is very friendly and loves long walks.',
      'petImage':
          'https://images.unsplash.com/photo-1552053831-71594a27632d?auto=format&fit=crop&w=900&q=80',
      'owner': {
        'name': 'Adrian',
        'age': 25,
        'ownerImage':
            'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=400&q=80',
        'bio': 'Animal lover and tech enthusiast.',
      },
    },
    {
      'name': 'Luna',
      'breed': 'European Shorthair',
      'age': 2,
      'location': 'Bucharest',
      'description': 'Luna is calm, curious and loves human company.',
      'petImage':
          'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&w=900&q=80',
      'owner': {
        'name': 'Maria',
        'age': 23,
        'ownerImage':
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=400&q=80',
        'bio': 'I love cats and nature walks.',
      },
    },
    {
      'name': 'Rocky',
      'breed': 'Beagle',
      'age': 4,
      'location': 'Ilfov',
      'description': 'Rocky is energetic, social and always ready for an adventure.',
      'petImage':
          'https://images.unsplash.com/photo-1507146426996-ef05306b995a?auto=format&fit=crop&w=900&q=80',
      'owner': {
        'name': 'Alex',
        'age': 27,
        'ownerImage':
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80',
        'bio': 'Passionate about dogs, sports and outdoor activities.',
      },
    },
    {
      'name': 'Milo',
      'breed': 'British Shorthair',
      'age': 1,
      'location': 'Bucharest',
      'description': 'Milo is gentle and very attached to people.',
      'petImage':
          'https://images.unsplash.com/photo-1533738363-b7f9aef128ce?auto=format&fit=crop&w=900&q=80',
      'owner': {
        'name': 'Andreea',
        'age': 24,
        'ownerImage':
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
        'bio': 'Cat lover and amateur photographer.',
      },
    },
    {
      'name': 'Bella',
      'breed': 'Labrador',
      'age': 5,
      'location': 'Pipera',
      'description': 'Bella loves people and playing outdoors.',
      'petImage':
          'https://images.unsplash.com/photo-1518717758536-85ae29035b6d?auto=format&fit=crop&w=900&q=80',
      'owner': {
        'name': 'Diana',
        'age': 26,
        'ownerImage':
            'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?auto=format&fit=crop&w=400&q=80',
        'bio': 'Animal lover and travel enthusiast.',
      },
    },
  ];

  int currentIndex = 0;
  Offset cardOffset = Offset.zero;
  bool isAnimating = false;
  bool isFlipped = false;

  static const double swipeThreshold = 120;

  void _onPanUpdate(DragUpdateDetails details) {
    if (isAnimating || currentIndex >= pets.length) return;

    setState(() {
      cardOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (isAnimating || currentIndex >= pets.length) return;

    if (cardOffset.dx > swipeThreshold) {
      _swipeCard(true);
    } else if (cardOffset.dx < -swipeThreshold) {
      _swipeCard(false);
    } else {
      _returnCard();
    }
  }

  void _swipeCard(bool liked) {
    if (isAnimating || currentIndex >= pets.length) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final direction = liked ? 1.0 : -1.0;

    setState(() {
      isAnimating = true;
      cardOffset = Offset(direction * screenWidth * 1.4, -40);
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      setState(() {
        currentIndex = (currentIndex + 1) % pets.length;
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
    final nextIndex = (currentIndex + 1) % pets.length;
    final username = (widget.userData['user'] != null
            ? widget.userData['user']['username']
            : widget.userData['username']) ??
        'User';

    return Scaffold(
      backgroundColor: const Color(0xFFF8D7DF),
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
              child: LayoutBuilder(
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
                        'Let’s find a new playmate🐾',
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
              ),
            ),
          ],
        ),
      ),
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
                  transform: Matrix4.identity()..rotateY(math.pi),
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
            Image.network(
              pet['petImage'],
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
                          pet['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 31,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${pet['age']} yrs',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    pet['breed'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 17,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        pet['location'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    pet['description'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.3,
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
    final owner = pet['owner'];
    final double avatarRadius = (height * 0.11).clamp(32.0, 56.0);
    final double gap = (height * 0.02).clamp(4.0, 14.0);

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
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundImage: NetworkImage(
                  owner['ownerImage'],
                ),
                onBackgroundImageError: (_, _) {},
              ),
            ),
            SizedBox(height: gap * 0.5),
            Text(
              owner['name'],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: (height * 0.046).clamp(18.0, 24.0),
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              '${owner['age']} yrs',
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
              owner['bio'],
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: (height * 0.028).clamp(12.0, 14.0),
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
            pet['petImage'],
            fit: BoxFit.cover,
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