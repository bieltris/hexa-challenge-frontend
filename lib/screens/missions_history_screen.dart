import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/mission_model.dart';
import '../services/api_service.dart';

class MissionsHistoryScreen extends StatefulWidget {
  final String sala;
  final String salaName;

  const MissionsHistoryScreen({
    super.key,
    required this.sala,
    required this.salaName,
  });

  @override
  State<MissionsHistoryScreen> createState() => _MissionsHistoryScreenState();
}

class _MissionsHistoryScreenState extends State<MissionsHistoryScreen> {
  late Future<List<MissionModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.getMissionHistory(sala: widget.sala);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001040),
      appBar: AppBar(title: Text('Missões — ${widget.salaName}')),
      body: FutureBuilder<List<MissionModel>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFDF00)),
            );
          }
          final missions = snap.data ?? const <MissionModel>[];
          if (missions.isEmpty) {
            return Center(
              child: Text(
                'Nenhuma missão conquistada ainda.',
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: missions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final mission = missions[index];
              final date = mission.date == null
                  ? ''
                  : '${mission.date!.day.toString().padLeft(2, '0')}/${mission.date!.month.toString().padLeft(2, '0')}';
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.14)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF009C3B), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$date · ${mission.progress}/${mission.target} gols',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            mission.delivered
                                ? '${mission.reward} entregue'
                                : '${mission.reward} pendente',
                            style: GoogleFonts.poppins(
                              color: Colors.white54,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
