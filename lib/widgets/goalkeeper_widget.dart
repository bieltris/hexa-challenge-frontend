import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GoalkeeperWidget extends StatelessWidget {
  /// -1.0 = extremo esquerdo · 0 = centro · 1.0 = extremo direito
  final double position;
  final bool isJumping;

  const GoalkeeperWidget({
    super.key,
    required this.position,
    required this.isJumping,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Text(
          'G O L E I R O',
          style: GoogleFonts.poppins(
            color: Colors.white38,
            fontSize: 9,
            letterSpacing: 3,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),

        // Goleiro animado
        SizedBox(
          width: double.infinity,
          height: 84,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Sombra no chão
              AnimatedAlign(
                duration: const Duration(milliseconds: 480),
                curve: Curves.easeOutBack,
                alignment: Alignment(position.clamp(-0.82, 0.82), 0.85),
                child: Container(
                  width: 60,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.black.withOpacity(0.25),
                  ),
                ),
              ),

              // Figura do goleiro
              AnimatedAlign(
                duration: const Duration(milliseconds: 480),
                curve: Curves.easeOutBack,
                alignment: Alignment(position.clamp(-0.82, 0.82), 0),
                child: AnimatedRotation(
                  duration: const Duration(milliseconds: 380),
                  turns: isJumping ? (position < 0 ? -0.06 : 0.06) : 0,
                  child: _GoalkeeperFigure(isJumping: isJumping),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GoalkeeperFigure extends StatelessWidget {
  final bool isJumping;
  const _GoalkeeperFigure({required this.isJumping});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isJumping ? 6 : 14,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A7B38), Color(0xFF0D5225)],
        ),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: const Color(0xFF00C853).withOpacity(0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF009C3B).withOpacity(isJumping ? 0.7 : 0.4),
            blurRadius: isJumping ? 20 : 12,
            spreadRadius: isJumping ? 3 : 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Braço esquerdo (visível ao pular)
          if (isJumping)
            _Arm(flip: true),

          const SizedBox(width: 4),

          // Corpo: luvas + jersey
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // Número na camiseta
                  Text(
                    '1',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFFFDF00),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  // Luva por cima
                  Text(
                    '🧤',
                    style: TextStyle(
                      fontSize: isJumping ? 44 : 38,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(width: 4),

          // Braço direito (visível ao pular)
          if (isJumping)
            _Arm(flip: false),
        ],
      ),
    );
  }
}

class _Arm extends StatelessWidget {
  final bool flip;
  const _Arm({required this.flip});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scaleX: flip ? -1 : 1,
      child: Container(
        width: 18,
        height: 6,
        decoration: BoxDecoration(
          color: const Color(0xFF1A7B38),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}
