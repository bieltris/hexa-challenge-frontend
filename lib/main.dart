import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';

void main() {
  // Remove hash (#) das URLs no web. iOS Safari revoga permissão de microfone
  // a cada hash change (WebKit bug 215884), então usamos path-based routing.
  usePathUrlStrategy();
  runApp(const HexaChallenge());
}

class HexaChallenge extends StatelessWidget {
  const HexaChallenge({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.dark(useMaterial3: true);
    return MaterialApp(
      title: 'Hexa Challenge',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        colorScheme: base.colorScheme.copyWith(
          primary: const Color(0xFF009C3B),
          secondary: const Color(0xFFFFDF00),
          surface: const Color(0xFF002776),
        ),
        scaffoldBackgroundColor: const Color(0xFF001A5E),
        textTheme: GoogleFonts.poppinsTextTheme(base.textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF002776),
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF009C3B),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF009C3B),
          foregroundColor: Colors.white,
        ),
      ),
      home: const _AppRoot(),
    );
  }
}

class _AppRoot extends StatelessWidget {
  const _AppRoot();

  Future<bool> _hasLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString('hexa_name') ?? '').isNotEmpty &&
        (prefs.getString('hexa_sala') ?? '').isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasLogin(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFF001040),
            body: Center(child: Text('⚽', style: TextStyle(fontSize: 48))),
          );
        }
        return snap.data! ? const HomeScreen() : const OnboardingScreen();
      },
    );
  }
}
