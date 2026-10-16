import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// User App — Player Profile Screen
class PlayerProfileScreen extends StatefulWidget {
  final String playerId;
  final String selectedFormat; // "Overall" or specific

  const PlayerProfileScreen({
    super.key,
    required this.playerId,
    required this.selectedFormat,
  });

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> {
  final _firestore = FirebaseFirestore.instance;

  static const Color bg = Color(0xFF1B1B2F);
  static const Color cardBg = Color(0xFF2D2D44);
  static const Color accent = Color(0xFF00C9A7);
  static const Color textLight = Color(0xFFEAEAEA);
  static const Color textGrey = Color(0xFF9E9E9E);
  static const Color divider = Color(0xFF3D3D5C);

  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final doc = await _firestore
          .collection('player_hub')
          .doc(widget.playerId)
          .get();
      if (doc.exists) {
        setState(() {
          _data = doc.data();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A73E8),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: accent),
        ),
      );
    }

    if (_data == null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A73E8),
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text('Player Profile',
              style: TextStyle(color: Colors.white)),
        ),
        body: const Center(
          child: Text('Player not found',
              style: TextStyle(color: textGrey)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A73E8),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          (_data!['name'] ?? 'Player').toString(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _basicInfoCard(),
          const SizedBox(height: 16),

          if (widget.selectedFormat == 'Overall')
            ..._buildOverallTables()
          else
            ..._buildSpecificFormatTables(widget.selectedFormat),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ─── Basic info card ───
  Widget _basicInfoCard() {
    final photoBase64 = (_data!['photoBase64'] ?? '').toString();
    final name = (_data!['name'] ?? '').toString();
    final fullName = (_data!['fullName'] ?? '').toString();
    final role = (_data!['role'] ?? '').toString();
    final bornYear = (_data!['bornYear'] ?? '').toString();
    final bornCity = (_data!['bornCity'] ?? '').toString();
    final debutYear = (_data!['debutYear'] ?? '').toString();
    final battingStyle = (_data!['battingStyle'] ?? '').toString();
    final bowlingStyle = (_data!['bowlingStyle'] ?? '').toString();
    final description = (_data!['description'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: accent, width: 2),
                ),
                child: ClipOval(
                  child: photoBase64.isNotEmpty
                      ? Image.memory(
                          _safeBase64Decode(photoBase64),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person,
                            size: 40,
                            color: textGrey,
                          ),
                        )
                      : const Icon(Icons.person, size: 40, color: textGrey),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: textLight,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (fullName.isNotEmpty && fullName != name)
                      Text(
                        fullName,
                        style: const TextStyle(
                          color: textGrey,
                          fontSize: 13,
                        ),
                      ),
                    if (role.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          role,
                          style: const TextStyle(
                            color: accent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (bornYear.isNotEmpty || bornCity.isNotEmpty)
            _infoRow(
              'Born',
              [bornYear, bornCity].where((e) => e.isNotEmpty).join(', '),
            ),
          if (debutYear.isNotEmpty)
            _infoRow('Debut', debutYear),
          if (battingStyle.isNotEmpty)
            _infoRow('Batting', battingStyle),
          if (bowlingStyle.isNotEmpty)
            _infoRow('Bowling', bowlingStyle),

          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: divider),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                color: textLight,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                color: textGrey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: textLight, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Overall tables ───
  List<Widget> _buildOverallTables() {
    final stats = _data!['stats'] as Map<String, dynamic>? ?? {};
    if (stats.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text('No stats available',
                style: TextStyle(color: textGrey)),
          ),
        ),
      ];
    }

    final formats = stats.keys.toList();

    return [
      _sectionTitle('🏏 BATTING'),
      const SizedBox(height: 8),
      _battingTable(formats, stats),
      const SizedBox(height: 20),
      _sectionTitle('🎯 BOWLING'),
      const SizedBox(height: 8),
      _bowlingTable(formats, stats),
    ];
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: accent,
        fontSize: 15,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  // ─── Batting table (Overall) ───
  Widget _battingTable(List<String> formats, Map<String, dynamic> stats) {
    const fields = [
      'Matches', 'Innings', 'NO', 'Runs', 'HS', 'BF', 'Avg', 'SR',
      '100s', '50s', '6s', '4s',
    ];

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: divider),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor:
              WidgetStateProperty.all(bg.withValues(alpha: 0.5)),
          headingTextStyle: const TextStyle(
            color: accent,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
          dataTextStyle: const TextStyle(
            color: textLight,
            fontSize: 12,
          ),
          columnSpacing: 14,
          horizontalMargin: 10,
          columns: [
            const DataColumn(label: Text('Format')),
            ...fields.map((f) => DataColumn(label: Text(f))),
          ],
          rows: formats.map((format) {
            final fData = stats[format] as Map<String, dynamic>? ?? {};
            final batting =
                fData['batting'] as Map<String, dynamic>? ?? {};
            return DataRow(
              cells: [
                DataCell(Text(
                  format,
                  style: const TextStyle(
                    color: accent,
                    fontWeight: FontWeight.bold,
                  ),
                )),
                ...fields.map((f) => DataCell(
                      Text((batting[f] ?? '-').toString()),
                    )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─── Bowling table (Overall) ───
  Widget _bowlingTable(List<String> formats, Map<String, dynamic> stats) {
    const fields = [
      'Matches', 'Innings', 'Wickets', 'Econ', 'SR', 'BBI', 'BBM', 'Avg',
    ];

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: divider),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor:
              WidgetStateProperty.all(bg.withValues(alpha: 0.5)),
          headingTextStyle: const TextStyle(
            color: accent,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
          dataTextStyle: const TextStyle(
            color: textLight,
            fontSize: 12,
          ),
          columnSpacing: 14,
          horizontalMargin: 10,
          columns: [
            const DataColumn(label: Text('Format')),
            ...fields.map((f) => DataColumn(label: Text(f))),
          ],
          rows: formats.map((format) {
            final fData = stats[format] as Map<String, dynamic>? ?? {};
            final bowling =
                fData['bowling'] as Map<String, dynamic>? ?? {};
            return DataRow(
              cells: [
                DataCell(Text(
                  format,
                  style: const TextStyle(
                    color: accent,
                    fontWeight: FontWeight.bold,
                  ),
                )),
                ...fields.map((f) => DataCell(
                      Text((bowling[f] ?? '-').toString()),
                    )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─── Specific format (single line) ───
  List<Widget> _buildSpecificFormatTables(String format) {
    final stats = _data!['stats'] as Map<String, dynamic>? ?? {};
    final fData = stats[format] as Map<String, dynamic>? ?? {};

    if (fData.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text('No stats for this format',
                style: TextStyle(color: textGrey)),
          ),
        ),
      ];
    }

    final batting = fData['batting'] as Map<String, dynamic>? ?? {};
    final bowling = fData['bowling'] as Map<String, dynamic>? ?? {};

    return [
      _sectionTitle('🏏 BATTING'),
      const SizedBox(height: 8),
      _oneLineBatting(batting),
      const SizedBox(height: 20),
      _sectionTitle('🎯 BOWLING'),
      const SizedBox(height: 8),
      _oneLineBowling(bowling),
    ];
  }

  Widget _oneLineBatting(Map<String, dynamic> batting) {
    const fields = [
      'Matches', 'Innings', 'NO', 'Runs', 'HS', 'BF', 'Avg', 'SR',
      '100s', '50s', '6s', '4s',
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: divider),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: fields.map((f) {
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    f,
                    style: const TextStyle(
                      color: accent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    (batting[f] ?? '-').toString(),
                    style: const TextStyle(
                      color: textLight,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _oneLineBowling(Map<String, dynamic> bowling) {
    const fields = [
      'Matches', 'Innings', 'Wickets', 'Econ', 'SR', 'BBI', 'BBM', 'Avg',
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: divider),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: fields.map((f) {
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    f,
                    style: const TextStyle(
                      color: accent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    (bowling[f] ?? '-').toString(),
                    style: const TextStyle(
                      color: textLight,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Uint8List _safeBase64Decode(String b64) {
    try {
      String cleaned = b64;
      if (cleaned.contains(',')) cleaned = cleaned.split(',').last;
      return base64Decode(cleaned);
    } catch (_) {
      return Uint8List(0);
    }
  }
}