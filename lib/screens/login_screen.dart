import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameCtrl = TextEditingController();
  String? _selectedSala;
  bool _loading = false;

  static const _rooms = [
    ('6ano', '6º Ano'), ('7ano', '7º Ano'), ('8ano', '8º Ano'),
    ('9ano', '9º Ano'), ('1medio', '1º Médio'), ('2medio', '2º Médio'),
    ('3medio', '3º Médio'),
  ];

  bool get _canConfirm =>
      _nameCtrl.text.trim().length >= 2 && _selectedSala != null && !_loading;

  Future<void> _confirm() async {
    if (!_canConfirm) return;
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hexa_name', _nameCtrl.text.trim());
    await prefs.setString('hexa_sala', _selectedSala!);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a, __) => const HomeScreen(),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF002776), Color(0xFF001040)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('⚽', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 10),
                  Text(
                    'HEXA CHALLENGE',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFFFDF00),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Quem é você?',
                    style: GoogleFonts.poppins(
                        color: Colors.white54, fontSize: 14),
                  ),

                  const SizedBox(height: 28),

                  // ── Aviso ──────────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.orange.withOpacity(0.45), width: 1),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lock_outline,
                            color: Colors.orange, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Atenção: após confirmar, nome e sala\nnão poderão ser alterados!',
                            style: GoogleFonts.poppins(
                              color: Colors.orange,
                              fontSize: 11.5,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Campo nome ─────────────────────────────────────────────
                  TextField(
                    controller: _nameCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Seu nome',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.person_outline,
                          color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.07),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.white.withOpacity(0.16)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.white.withOpacity(0.16)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Color(0xFF009C3B), width: 2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Dropdown sala ──────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.16)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSala,
                        isExpanded: true,
                        hint: Text(
                          'Selecione sua sala',
                          style: GoogleFonts.poppins(
                              color: Colors.white38, fontSize: 13),
                        ),
                        dropdownColor: const Color(0xFF002776),
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 14),
                        icon: const Icon(Icons.arrow_drop_down,
                            color: Colors.white38),
                        items: _rooms
                            .map((r) => DropdownMenuItem(
                                value: r.$1, child: Text(r.$2)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedSala = v),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Botão confirmar ────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _canConfirm ? _confirm : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF009C3B),
                        disabledBackgroundColor:
                            const Color(0xFF009C3B).withOpacity(0.35),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(
                              'Entrar no jogo!  ⚽',
                              style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
