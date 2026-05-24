import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:xml/xml.dart';

import '../services/api_service.dart';

const Map<String, Color> kSalaColors = {
  '6ano': Color(0xFFEF4444),
  '7ano': Color(0xFFF59E0B),
  '8ano': Color(0xFF22C55E),
  '9ano': Color(0xFF06B6D4),
  '1medio': Color(0xFF3B82F6),
  '2medio': Color(0xFF8B5CF6),
  '3medio': Color(0xFFEC4899),
};

const Map<String, String> _salaColorHex = {
  '6ano': '#EF4444',
  '7ano': '#F59E0B',
  '8ano': '#22C55E',
  '9ano': '#06B6D4',
  '1medio': '#3B82F6',
  '2medio': '#8B5CF6',
  '3medio': '#EC4899',
};

const _neutralFill = '#4B5563';
const _mapAsset = 'assets/maps/continents.svg';

const Map<String, String> _regionNames = {
  'south_america': 'América do Sul',
  'north_america': 'América do Norte',
  'europe': 'Europa',
  'africa': 'África',
  'asia': 'Ásia',
  'oceania': 'Oceania',
};

const Map<String, Rect> _regionHitBoxes = {
  'north_america': Rect.fromLTWH(0.07, 0.02, 0.39, 0.45),
  'south_america': Rect.fromLTWH(0.23, 0.39, 0.17, 0.46),
  'europe': Rect.fromLTWH(0.41, 0.01, 0.19, 0.27),
  'africa': Rect.fromLTWH(0.42, 0.25, 0.20, 0.48),
  'asia': Rect.fromLTWH(0.53, 0.02, 0.37, 0.57),
  'oceania': Rect.fromLTWH(0.74, 0.48, 0.16, 0.31),
};

class WorldMapWidget extends StatefulWidget {
  const WorldMapWidget({super.key});

  @override
  State<WorldMapWidget> createState() => _WorldMapWidgetState();
}

class _WorldMapWidgetState extends State<WorldMapWidget> {
  Timer? _pollTimer;
  Future<_PaintedMap>? _mapFuture;

  @override
  void initState() {
    super.initState();
    _reload();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _reload());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      _mapFuture = _loadPaintedMap();
    });
  }

  Future<_PaintedMap> _loadPaintedMap() async {
    final results = await Future.wait<dynamic>([
      rootBundle.loadString(_mapAsset),
      ApiService.getMapRegions(),
    ]);
    final rawSvg = results[0] as String;
    final snapshot = results[1] as MapRegionsSnapshot;
    return _PaintedMap(
      svg: _paintSvg(rawSvg, snapshot),
      snapshot: snapshot,
    );
  }

  String _paintSvg(String rawSvg, MapRegionsSnapshot snapshot) {
    final document = XmlDocument.parse(rawSvg);

    for (final group in document.findAllElements('g')) {
      final id = group.getAttribute('id');
      if (id == null || !_regionNames.containsKey(id)) continue;

      final region = snapshot.regions[id];
      final fill = snapshot.totalGoals == 0
          ? _neutralFill
          : _salaColorHex[region?.sala] ?? _neutralFill;

      group.setAttribute('fill', fill);
      group.setAttribute('stroke', '#001040');
      group.setAttribute('stroke-width', '90');
    }

    return document.toXmlString();
  }

  void _showRegionSheet(MapRegionModel region, MapRegionsSnapshot snapshot) {
    final salaColor = kSalaColors[region.sala] ?? const Color(0xFF6B7280);
    final topRooms = _topRooms(snapshot);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF001A4E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: salaColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _regionNames[region.id] ?? region.id,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                snapshot.totalGoals == 0
                    ? 'Ninguém conquistou ainda'
                    : 'Dominada por ${region.salaName} (${region.percent}% dos gols globais)',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Ranking',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFFFDF00),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              ...topRooms.map((room) => _RankingRow(room: room)),
            ],
          ),
        ),
      ),
    );
  }

  List<_RoomRank> _topRooms(MapRegionsSnapshot snapshot) {
    final bySala = <String, _RoomRank>{};

    for (final region in snapshot.regions.values) {
      final sala = region.sala;
      if (sala == null) continue;

      final previous = bySala[sala];
      if (previous == null || region.goals > previous.goals) {
        bySala[sala] = _RoomRank(
          sala: sala,
          salaName: region.salaName,
          goals: region.goals,
        );
      }
    }

    final rooms = bySala.values.toList()
      ..sort((a, b) {
        final byGoals = b.goals.compareTo(a.goals);
        if (byGoals != 0) return byGoals;
        return a.sala.compareTo(b.sala);
      });

    return rooms.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_PaintedMap>(
      future: _mapFuture,
      builder: (context, snapshot) {
        final paintedMap = snapshot.data;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 28, 12, 12),
                      child: paintedMap == null
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFFFDF00),
                                strokeWidth: 2,
                              ),
                            )
                          : SvgPicture.string(
                              paintedMap.svg,
                              fit: BoxFit.contain,
                            ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 14,
                    right: 14,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Territórios da Copa',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (paintedMap?.snapshot.isMock ?? false)
                          const _StatusPill(label: 'prévia')
                        else if (paintedMap != null)
                          _StatusPill(
                            label: '${paintedMap.snapshot.totalGoals} gols',
                          ),
                      ],
                    ),
                  ),
                  if (paintedMap != null)
                    ..._regionHitBoxes.entries.map(
                      (entry) => _RegionTapTarget(
                        rect: entry.value,
                        onTap: () {
                          final region =
                              paintedMap.snapshot.regions[entry.key] ??
                                  MapRegionModel(
                                    id: entry.key,
                                    sala: null,
                                    salaName: 'Ninguém conquistou ainda',
                                    percent: 0,
                                    goals: 0,
                                  );
                          _showRegionSheet(region, paintedMap.snapshot);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PaintedMap {
  final String svg;
  final MapRegionsSnapshot snapshot;

  const _PaintedMap({
    required this.svg,
    required this.snapshot,
  });
}

class _RoomRank {
  final String sala;
  final String salaName;
  final int goals;

  const _RoomRank({
    required this.sala,
    required this.salaName,
    required this.goals,
  });
}

class _RegionTapTarget extends StatelessWidget {
  final Rect rect;
  final VoidCallback onTap;

  const _RegionTapTarget({
    required this.rect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Positioned(
                left: constraints.maxWidth * rect.left,
                top: constraints.maxHeight * rect.top,
                width: constraints.maxWidth * rect.width,
                height: constraints.maxHeight * rect.height,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: onTap,
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;

  const _StatusPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFDF00).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFFFDF00).withValues(alpha: 0.36),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: const Color(0xFFFFDF00),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  final _RoomRank room;

  const _RankingRow({required this.room});

  @override
  Widget build(BuildContext context) {
    final color = kSalaColors[room.sala] ?? const Color(0xFF6B7280);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              room.salaName,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${room.goals} gols',
            style: GoogleFonts.poppins(
              color: Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
