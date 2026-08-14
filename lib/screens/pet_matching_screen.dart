import 'dart:math' as math;
import 'package:flutter/material.dart';

class PetMatchingScreen extends StatefulWidget {
  const PetMatchingScreen({super.key});

  @override
  State<PetMatchingScreen> createState() => _PetMatchingScreenState();
}

class _PetMatchingScreenState extends State<PetMatchingScreen> {
  final List<Map<String, dynamic>> pets = [
    {
      'name': 'Max',
      'breed': 'Golden Retriever',
      'age': 3,
      'location': 'București',
      'description':
          'Max este foarte prietenos și adoră plimbările lungi.',
      'petImage':
          'https://images.unsplash.com/photo-1552053831-71594a27632d?auto=format&fit=crop&w=900&q=80',
      'owner': {
        'name': 'Adrian-Ionuț',
        'age': 25,
        'ownerImage':
            'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=400&q=80',
        'bio': 'Iubitor de animale și pasionat de tehnologie.',
      },
    },
    {
      'name': 'Luna',
      'breed': 'Pisică Europeană',
      'age': 2,
      'location': 'București',
      'description':
          'Luna este calmă, curioasă și adoră să stea în compania oamenilor.',
      'petImage':
          'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&w=900&q=80',
      'owner': {
        'name': 'Maria',
        'age': 23,
        'ownerImage':
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=400&q=80',
        'bio': 'Iubesc pisicile și plimbările în natură.',
      },
    },
    {
      'name': 'Rocky',
      'breed': 'Beagle',
      'age': 4,
      'location': 'Ilfov',
      'description':
          'Rocky este energic, sociabil și mereu pregătit pentru o aventură.',
      'petImage':
          'https://images.unsplash.com/photo-1507146426996-ef05306b995a?auto=format&fit=crop&w=900&q=80',
      'owner': {
        'name': 'Alex',
        'age': 27,
        'ownerImage':
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80',
        'bio': 'Pasionat de câini, sport și activități outdoor.',
      },
    },
    {
      'name': 'Milo',
      'breed': 'British Shorthair',
      'age': 1,
      'location': 'București',
      'description':
          'Milo este blând și foarte atașat de oameni.',
      'petImage':
          'https://images.unsplash.com/photo-1533738363-b7f9aef128ce?auto=format&fit=crop&w=900&q=80',
      'owner': {
        'name': 'Andreea',
        'age': 24,
        'ownerImage':
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
        'bio': 'Cat lover și fotograf amator.',
      },
    },
    {
      'name': 'Bella',
      'breed': 'Labrador',
      'age': 5,
      'location': 'Pipera',
      'description':
          'Bella iubește oamenii și joaca în aer liber.',
      'petImage':
          'https://images.unsplash.com/photo-1518717758536-85ae29035b6d?auto=format&fit=crop&w=900&q=80',
      'owner': {
        'name': 'Diana',
        'age': 26,
        'ownerImage':
            'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?auto=format&fit=crop&w=400&q=80',
        'bio': 'Iubitoare de animale și călătorii.',
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
        currentIndex++;
        cardOffset = Offset.zero;
        isFlipped = false;
        isAnimating = false;
      });

      if (liked) {
        _showLikeMessage();
      }
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
    if (isAnimating || currentIndex >= pets.length) return;

    setState(() {
      isFlipped = !isFlipped;
    });
  }

  void _resetCards() {
    setState(() {
      currentIndex = 0;
      cardOffset = Offset.zero;
      isFlipped = false;
      isAnimating = false;
    });
  }

  void _showLikeMessage() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('❤️ Ai dat Like acestui profil!'),
        duration: Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasCards = currentIndex < pets.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8D7DF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE89AAA),
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
          side: BorderSide(
            color: Color(0xFFB85F73),
            width: 2,
          ),
        ),
        title: const Text(
          'Pet Matching',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;

            final double cardWidth =
                isWide ? 430.0 : constraints.maxWidth * 0.88;

            final double cardHeight = isWide
                ? 570.0
                : math.min(
                    constraints.maxHeight * 0.68,
                    570.0,
                  ).toDouble();

            return Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 520,
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Let’s find a new playmate🐾',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: cardWidth,
                          height: cardHeight,
                          child: hasCards
                              ? Stack(
                                  alignment: Alignment.center,
                                  clipBehavior: Clip.none,
                                  children: [
                                    if (currentIndex + 1 < pets.length)
                                      _buildBackgroundCard(
                                        pets[currentIndex + 1],
                                        cardWidth,
                                        cardHeight,
                                      ),
                                    _buildActiveCard(
                                      pets[currentIndex],
                                      cardWidth,
                                      cardHeight,
                                    ),
                                  ],
                                )
                              : _buildFinishedState(),
                        ),
                        const SizedBox(height: 25),
                        if (hasCards)
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildActionButton(
                                icon: Icons.close,
                                label: 'Nu',
                                color: Colors.redAccent,
                                onPressed: () {
                                  _swipeCard(false);
                                },
                              ),
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
                    ),
                  ),
                ),
              ),
            );
          },
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

    final double likeOpacity =
        (cardOffset.dx / 120).clamp(0.0, 1.0).toDouble();

    final double nopeOpacity =
        (-cardOffset.dx / 120).clamp(0.0, 1.0).toDouble();

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
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Stack(
          children: [
            _buildFlipCard(
              pet,
              width,
              height,
            ),
            Positioned(
              top: 25,
              left: 22,
              child: Opacity(
                opacity: likeOpacity,
                child: Transform.rotate(
                  angle: -0.12,
                  child: _buildSwipeLabel(
                    'LIKE',
                    const Color(0xFF1F6E6C),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 25,
              right: 22,
              child: Opacity(
                opacity: nopeOpacity,
                child: Transform.rotate(
                  angle: 0.12,
                  child: _buildSwipeLabel(
                    'NOPE',
                    Colors.redAccent,
                  ),
                ),
              ),
            ),
          ],
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
              top: 15,
              right: 15,
              child: Material(
                color: Colors.white.withValues(alpha: 0.9),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _flipCard,
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      Icons.flip,
                      color: Color(0xFF1F6E6C),
                    ),
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
                        '${pet['age']} ani',
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
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Material(
                color: const Color(0xFFF8D7DF),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _flipCard,
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      Icons.flip,
                      color: Color(0xFF1F6E6C),
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            CircleAvatar(
              radius: 68,
              backgroundColor: const Color(0xFF1F6E6C),
              child: CircleAvatar(
                radius: 63,
                backgroundImage: NetworkImage(
                  owner['ownerImage'],
                ),
                onBackgroundImageError: (_, _) {},
              ),
            ),
            const SizedBox(height: 20),
            Text(
              owner['name'],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${owner['age']} ani',
              style: const TextStyle(
                fontSize: 17,
                color: Color(0xFF1F6E6C),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF8D7DF),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.pets,
                    color: Color(0xFF1F6E6C),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Proprietarul lui ${pet['name']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              owner['bio'],
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _flipCard,
              icon: const Icon(
                Icons.arrow_back,
                color: Color(0xFF1F6E6C),
              ),
              label: const Text(
                'Înapoi la animal',
                style: TextStyle(
                  color: Color(0xFF1F6E6C),
                  fontWeight: FontWeight.bold,
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

  Widget _buildSwipeLabel(
    String text,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        border: Border.all(
          color: color,
          width: 3,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 23,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
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

  Widget _buildFinishedState() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.pets,
            size: 70,
            color: Color(0xFF1F6E6C),
          ),
          const SizedBox(height: 18),
          const Text(
            'Ai văzut toate animalele!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Poți începe din nou și să vezi toate profilurile.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _resetCards,
            icon: const Icon(Icons.refresh),
            label: const Text('Începe din nou'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1F6E6C),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}