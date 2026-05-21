import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/comment_model.dart';

class CommentCard extends StatefulWidget {
  final CommentModel comment;
  final bool liked;
  final ValueChanged<bool> onLikeChanged;

  const CommentCard({
    super.key,
    required this.comment,
    required this.liked,
    required this.onLikeChanged,
  });

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> {
  late bool _liked;
  late int  _likes;

  @override
  void initState() {
    super.initState();
    _liked = widget.liked;
    _likes = widget.comment.likes;
  }

  void _toggle() {
    final next = !_liked;
    setState(() {
      _liked = next;
      _likes = next ? _likes + 1 : (_likes - 1).clamp(0, 999999);
    });
    widget.onLikeChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final isPele = widget.comment.isPele;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        // Pelé: card dourado especial
        gradient: isPele
            ? const LinearGradient(
                colors: [Color(0xFF2A1F00), Color(0xFF3D2E00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isPele ? null : Colors.white.withOpacity(0.07),
        border: Border.all(
          color: isPele
              ? const Color(0xFFFFDF00).withOpacity(0.6)
              : Colors.white12,
          width: isPele ? 1.5 : 1,
        ),
        boxShadow: isPele
            ? [
                BoxShadow(
                  color: const Color(0xFFFFDF00).withOpacity(0.12),
                  blurRadius: 16,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Badge Pelé ─────────────────────────────────────────────────
            if (isPele)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFFFDF00), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Comentário Lendário',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFFFDF00),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),

            // ── Header (avatar + nome + tempo) ────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                _PlayerAvatar(
                  photoUrl: widget.comment.playerPhoto,
                  name: widget.comment.playerName,
                  isPele: isPele,
                ),
                const SizedBox(width: 10),

                // Nome + sala + tempo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.comment.playerName,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: isPele
                                    ? const Color(0xFFFFDF00)
                                    : Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF009C3B).withOpacity(0.3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.comment.salaName,
                              style: const TextStyle(
                                  color: Color(0xFF00FF6A),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        widget.comment.timeAgo,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Texto ──────────────────────────────────────────────────────
            Text(
              widget.comment.body,
              style: TextStyle(
                color: isPele
                    ? const Color(0xFFFFF5D6)
                    : Colors.white.withOpacity(0.85),
                fontSize: 13.5,
                height: 1.45,
              ),
            ),

            const SizedBox(height: 10),

            // ── Like ───────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: _toggle,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Row(
                      key: ValueKey(_liked),
                      children: [
                        Icon(
                          _liked ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: _liked
                              ? Colors.redAccent
                              : Colors.white38,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$_likes',
                          style: TextStyle(
                            color: _liked ? Colors.redAccent : Colors.white38,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Avatar do jogador ─────────────────────────────────────────────────────────

class _PlayerAvatar extends StatelessWidget {
  final String photoUrl;
  final String name;
  final bool isPele;

  const _PlayerAvatar({
    required this.photoUrl,
    required this.name,
    required this.isPele,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name.split(' ').take(2).map((w) => w[0]).join();
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isPele
              ? const Color(0xFFFFDF00)
              : const Color(0xFF009C3B).withOpacity(0.5),
          width: isPele ? 2 : 1.5,
        ),
      ),
      child: ClipOval(
        child: Image.network(
          photoUrl,
          width: 42,
          height: 42,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => CircleAvatar(
            radius: 21,
            backgroundColor: isPele
                ? const Color(0xFFFFDF00)
                : const Color(0xFF009C3B),
            child: Text(
              initials,
              style: TextStyle(
                color: isPele ? Colors.black : Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
