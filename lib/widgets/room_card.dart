import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/game_screen.dart';

class RoomCard extends StatelessWidget {
  final String salaKey;
  final String salaName;
  final int index;
  final int shotsLeft;

  const RoomCard({
    super.key,
    required this.salaKey,
    required this.salaName,
    required this.index,
    required this.shotsLeft,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = shotsLeft <= 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : () => _go(context),
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: disabled
                  ? [Colors.white10, Colors.white.withOpacity(0.02)]
                  : [const Color(0xFF009C3B), const Color(0xFF006B29)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: disabled
                  ? Colors.white24
                  : const Color(0xFFFFDF00),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              salaName,
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: disabled ? Colors.white38 : Colors.white,
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (index * 80).ms, duration: 400.ms)
        .slideY(begin: 0.25, curve: Curves.easeOut);
  }

  void _go(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(sala: salaKey, salaName: salaName),
      ),
    );
  }
}
