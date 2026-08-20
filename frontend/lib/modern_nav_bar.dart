import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/pet_matching_screen.dart';
import 'screens/home_screen.dart';
import 'screens/owner_profile_screen.dart'; // sau profile_screen.dart dacă așa e numit fișierul
import 'screens/consultation_screen.dart';

PageRouteBuilder smoothRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutCubic,
      );
      return FadeTransition(
        opacity: curve,
        child: child,
      );
    },
  );
}

class ModernNavBar extends StatelessWidget {
  final String currentPage;
  final VoidCallback onMapTap;
  final Map<String, dynamic> userData;

  const ModernNavBar({
    super.key,
    required this.currentPage,
    required this.onMapTap,
    this.userData = const {}, // Nu mai forțează eroare dacă e omis
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () {
                  if (currentPage != 'Main Page') {
                    Navigator.pushReplacement(
                      context,
                      smoothRoute(HomeScreen(userData: userData)),
                    );
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 34,
                        width: 34,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.pets,
                          color: Color(0xFF1F6E6C),
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Pawnder',
                      style: GoogleFonts.pacifico(
                        color: const Color(0xFF1F6E6C),
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _navItem(
                      context,
                      'Main Page',
                      isActive: currentPage == 'Main Page',
                      onTap: () {
                        if (currentPage != 'Main Page') {
                          Navigator.pushReplacement(
                            context,
                            smoothRoute(HomeScreen(userData: userData)),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    _navItem(
                      context,
                      'My Profile',
                      isActive: currentPage == 'My Profile',
                      onTap: () {
                        if (currentPage != 'My Profile') {
                          Navigator.pushReplacement(
                            context,
                            smoothRoute(OwnerProfileScreen(userData: userData)),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    _navItem(
                      context,
                      'Map',
                      isActive: currentPage == 'Map',
                      onTap: onMapTap,
                    ),
                    const SizedBox(width: 8),
                    _navItem(
                      context,
                      'Tinder',
                      isActive: currentPage == 'Tinder',
                      onTap: () {
                        if (currentPage != 'Tinder') {
                          Navigator.pushReplacement(
                            context,
                            smoothRoute(PetMatchingScreen(userData: userData)),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    _navItem(
                      context,
                      'Consultations',
                      isActive: currentPage == 'Consultations',
                      onTap: () {
                        if (currentPage != 'Consultations') {
                          Navigator.pushReplacement(
                            context,
                            smoothRoute(ConsultationScreen(userData: userData)),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    String title, {
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? const Color(0xFF1F6E6C)
                    : Colors.grey.shade600,
              ),
              child: Text(title),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: isActive ? 20 : 0,
              height: 2.5,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF1F6E6C) : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}