import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../services/duel_socket_service.dart';
import 'duel_game_screen.dart';

class DuelLobbyScreen extends StatefulWidget {
  final String name;
  final String sala;
  final String salaName;
  const DuelLobbyScreen({super.key, required this.name, required this.sala, required this.salaName});

  @override State<DuelLobbyScreen> createState() => _DuelLobbyScreenState();
}

class _DuelLobbyScreenState extends State<DuelLobbyScreen> {
  final _svc = DuelSocketService.instance;
  final _searchCtrl = TextEditingController();
  final List<StreamSubscription> _subs = [];

  List<Map<String,dynamic>> _online = [];
  List<Map<String,dynamic>> _search = [];
  bool _queued = false;
  Map<String,dynamic>? _pendingInvite;
  bool _searchMode = false;

  // sid -> seconds remaining
  final Map<String, int> _cooldowns = {};
  Timer? _cooldownTicker;

  static const _roomNames = {
    '6ano':'6º Ano','7ano':'7º Ano','8ano':'8º Ano','9ano':'9º Ano',
    '1medio':'1º Médio','2medio':'2º Médio','3medio':'3º Médio',
  };

  @override
  void initState() {
    super.initState();
    _svc.connect(widget.name, widget.sala);
    _subs.add(_svc.onlineUsers.listen((u) => setState(() => _online = u)));
    _subs.add(_svc.searchResults.listen((r) => setState(() => _search = r)));
    _subs.add(_svc.queued.listen((q) => setState(() => _queued = q)));
    _subs.add(_svc.inviteReceived.listen(_onInvite));
    _subs.add(_svc.duelStart.listen(_onDuelStart));
    _subs.add(_svc.inviteDeclined.listen(_onDeclined));
  }

  @override void dispose() {
    _cooldownTicker?.cancel();
    for (var s in _subs) s.cancel();
    super.dispose();
  }

  void _onInvite(Map<String,dynamic> d) {
    if (!mounted) return;
    setState(() => _pendingInvite = d);
    showDialog(context: context, barrierDismissible: false, builder: (_) => InviteDialog(
      d: d, svc: _svc, roomNames: _roomNames,
      onDone: () => setState(() => _pendingInvite = null),
    ));
  }

  void _onDuelStart(Map<String,dynamic> d) {
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => DuelGameScreen(data: d, name: widget.name, sala: widget.sala, salaName: widget.salaName),
    ));
  }

  void _onDeclined(Map<String,dynamic> d) {
    final sid = d['declinedBy'] as String?;
    if (sid == null || !mounted) return;
    setState(() => _cooldowns[sid] = 20);
    _startCooldownTicker();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF4B0082),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(12),
      content: Text('Desafio recusado',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
      duration: const Duration(seconds: 3),
    ));
  }

  void _startCooldownTicker() {
    _cooldownTicker?.cancel();
    if (_cooldowns.isEmpty) return;
    _cooldownTicker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _cooldowns.updateAll((_, v) => v - 1);
        _cooldowns.removeWhere((_, v) => v <= 0);
      });
      if (_cooldowns.isEmpty) t.cancel();
    });
  }

  void _doSearch(String q) {
    _svc.searchUsers(q);
    setState(() => _searchMode = q.isNotEmpty);
  }

  void _invite(String sid) => _svc.inviteUser(sid);
  void _toggleQueue() {
    if (_queued) { _svc.leaveQueue(); } else { _svc.joinQueue(); }
  }

  Future<void> _doShare() async {
    const url = 'https://hexa-challenge.pages.dev';
    const text = 'Joga Hexa Challenge comigo! ⚽\nDuelo de pênalti entre escolas — Copa 2026\n$url';
    try {
      await Share.share(text, subject: 'Hexa Challenge — entra no jogo!');
    } catch (_) {
      await Clipboard.setData(const ClipboardData(text: text));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF009C3B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(12),
        content: Text('Link copiado! Cola pros amigos 🚀',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
        duration: const Duration(seconds: 3),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final idle = _online.where((u) =>
        u['socketId'] != _svc.mySocketId && u['status'] == 'idle').toList();

    return Scaffold(
      backgroundColor: const Color(0xFF000A1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF001A4E),
        title: Text('Duelo', style: GoogleFonts.poppins(fontWeight: FontWeight.w800)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              backgroundColor: const Color(0xFF009C3B),
              label: Text(widget.salaName, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Column(children: [
        // Auto-match button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: GestureDetector(
            onTap: _toggleQueue,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _queued ? const Color(0xFF7B5800) : const Color(0xFF002776),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _queued ? const Color(0xFFFFDF00) : const Color(0xFF4488FF).withOpacity(0.5), width: 1.5),
              ),
              child: Column(children: [
                Text(_queued ? 'Procurando adversario...' : 'Auto-Match',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                Text(_queued ? 'Toque para cancelar' : 'Encontre um oponente de outra sala',
                    style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11)),
              ]),
            ),
          ),
        ),

        // Share button (acima do divider)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: GestureDetector(
            onTap: _doShare,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFE94A), Color(0xFFFFC400)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFEC8B), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFDF00).withOpacity(0.3),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.share_rounded, color: Color(0xFF001040), size: 18),
                const SizedBox(width: 8),
                Text(
                  'Convidar amigos pro jogo',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF001040),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ]),
            ),
          ),
        ),

        // Divider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(children: [
            const Expanded(child: Divider(color: Colors.white12)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('ou desafie alguem', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11)),
            ),
            const Expanded(child: Divider(color: Colors.white12)),
          ]),
        ),

        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Buscar jogador pelo nome...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withOpacity(0.07),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onChanged: _doSearch,
          ),
        ),

        // User list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
            itemCount: (_searchMode ? _search : idle).length + 1,
            itemBuilder: (ctx, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _searchMode ? 'Resultados (${_search.length})' : 'Online agora (${idle.length})',
                    style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                );
              }
              final u = (_searchMode ? _search : idle)[i - 1];
              final sameSala = u['sala'] == widget.sala;
              final sid = u['socketId'] as String;
              final cd = _cooldowns[sid] ?? 0;
              final onCooldown = cd > 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                        color: const Color(0xFF009C3B).withOpacity(0.2),
                        border: Border.all(color: const Color(0xFF009C3B).withOpacity(0.4))),
                    child: Center(child: Text(
                      (u['name'] as String).isNotEmpty ? (u['name'] as String)[0].toUpperCase() : '?',
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                    )),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(u['name'] as String, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                    Row(children: [
                      Text(_roomNames[u['sala']] ?? u['sala'] as String, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                      if (sameSala) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)),
                          child: Text('mesma sala', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 9)),
                        ),
                      ],
                    ]),
                  ])),
                  ElevatedButton(
                    onPressed: onCooldown ? null : () => _invite(sid),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: onCooldown
                          ? Colors.white10
                          : (sameSala ? Colors.white12 : const Color(0xFF002776)),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.white10,
                      disabledForegroundColor: Colors.white38,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: Text(
                      onCooldown ? 'Aguarde ${cd}s' : 'Desafiar',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class InviteDialog extends StatelessWidget {
  final Map<String,dynamic> d;
  final DuelSocketService svc;
  final Map<String,String> roomNames;
  final VoidCallback onDone;
  const InviteDialog({required this.d, required this.svc, required this.roomNames, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final from = d['from'] as Map<String,dynamic>;
    final sala = from['sala'] as String;
    return AlertDialog(
      backgroundColor: const Color(0xFF001A4E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Desafio!', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w800)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('${from['name']}', style: GoogleFonts.poppins(color: const Color(0xFFFFDF00), fontSize: 20, fontWeight: FontWeight.w900)),
        Text('da ${roomNames[sala] ?? sala}', style: const TextStyle(color: Colors.white54)),
        const SizedBox(height: 8),
        const Text('quer duelar com voce!', style: TextStyle(color: Colors.white70)),
      ]),
      actions: [
        TextButton(
          onPressed: () {
            svc.respondInvite(d['duelId'] as String, from['socketId'] as String, false);
            onDone(); Navigator.pop(context);
          },
          child: const Text('Recusar', style: TextStyle(color: Colors.white38)),
        ),
        ElevatedButton(
          onPressed: () {
            svc.respondInvite(d['duelId'] as String, from['socketId'] as String, true);
            onDone(); Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF009C3B), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: Text('Aceitar!', style: GoogleFonts.poppins(fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}
