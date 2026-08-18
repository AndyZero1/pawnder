import 'package:flutter/material.dart';
import 'screens/pet_matching_screen.dart';

class ModernNavBar extends StatelessWidget {
  final String currentPage; 
  final VoidCallback onMapTap;
  final VoidCallback onEditTap;

  const ModernNavBar({
    super.key, 
    required this.currentPage, 
    required this.onMapTap, 
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.pets, color: Color(0xFF1F6E6C), size: 28),
                SizedBox(width: 8),
                Text('Pawndar', style: TextStyle(color: Color(0xFF1F6E6C), fontSize: 24, fontWeight: FontWeight.w900)),
              ],
            ),
            Row(
              children: [
                
                _navItem('Main Page', isActive: currentPage == 'Main Page', onTap: () {
                 
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Urmează să construim Forumul! 🛠️')));
                }),
                const SizedBox(width: 15),
                
                _navItem('Profilul Meu', isActive: currentPage == 'Profilul Meu', onTap: () {
              
                  if (currentPage != 'Profilul Meu') {
                   
                  }
                }),
                const SizedBox(width: 15),
                
                _navItem('Harta', isActive: currentPage == 'Harta', onTap: onMapTap),
                const SizedBox(width: 15),
                
                _navItem('Tinder', isActive: currentPage == 'Tinder', onTap: () {
                  if (currentPage != 'Tinder') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PetMatchingScreen()),
                    );
                  }
                }),
                const SizedBox(width: 25),
                
                ElevatedButton.icon(
                  onPressed: onEditTap,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Editare Profil', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: const Color(0xFF1F6E6C), backgroundColor: Colors.white, elevation: 0,
                    side: const BorderSide(color: Color(0xFF1F6E6C), width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(String title, {required bool isActive, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            color: isActive ? const Color(0xFF1F6E6C) : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}