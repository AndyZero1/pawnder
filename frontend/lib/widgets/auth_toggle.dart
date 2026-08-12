import 'package:flutter/material.dart';
import '../constants/colors.dart';

class AuthToggle extends StatelessWidget {
  final bool isSignIn;
  final Function(bool) onChanged;

  const AuthToggle({
    super.key,
    required this.isSignIn,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.brown,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: _toggleItem(
              "Sign In",
              isSignIn,
            ),
          ),
          Expanded(
            child: _toggleItem(
              "Sign Up",
              !isSignIn,
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleItem(String label, bool active) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(label == "Sign In"),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.yellow : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: active ? AppColors.brown : AppColors.yellow,
          ),
        ),
      ),
    );
  }
}