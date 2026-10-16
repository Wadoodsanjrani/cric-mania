import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// User App — ICC Rankings Screen (read-only)
/// Firestore path: icc_rankings/{gender}/{format}/{category}/list/{docId}
class IccRankingsScreen extends StatefulWidget {
  const IccRankingsScreen({super.key});

  @override
  State<IccRankingsScreen> createState() => _IccRankingsScreenState();
}

class _IccRankingsScreenState extends State<IccRankingsScreen> {
  final _firestore = FirebaseFirestore.instance;

  String _gender = 'men';
  String _format = 'test';
  int _tab = 0; // 0 = teams, 1 = players

  static const Color bg = Color(0xFF1B1B2F);
  static const Color cardBg = Color(0xFF2D2D44);
  static const Color accent = Color(0xFF00C9A7);
  static const Color textLight = Color(0xFFEAEAEA);
  static const Color textGrey = Color(0xFF9E9E9E);
  static const Color divider = Color(0xFF3D3D5C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A73E8),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'ICC Rankings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // ─── Dropdowns ───
          Container(
            padding: const EdgeInsets.all(12),
            color: cardBg,
            child: Row(
              children: [
                Expanded(
                  child: _dropdown(
                    value: _gender,
                    items: const ['men', 'women'],
                    display: (v) => v == 'men' ? '👨 Men' : '👩 Women',
                    onChanged: (v) => setState(() => _gender = v!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _dropdown(
                    value: _format,
                    items: const ['test', 'odi', 't20'],
                    display: (v) => v.toUpperCase(),
                    onChanged: (v) => setState(() => _format = v!),
                  ),
                ),
              ],
            ),
          ),

          // ─── Tabs ───
          Container(
            color: cardBg,
            child: Row(
              children: [
                Expanded(child: _tabBtn('Team Rankings', 0)),
                Expanded(child: _tabBtn('Player Rankings', 1)),
              ],
            ),
          ),

          // ─── Body ───
          Expanded(
            child: _tab == 0 ? _teamsSection() : _playersSection(),
          ),
        ],
      ),
    );
  }

  // ─────────── TEAMS ───────────
  Widget _teamsSection() {
    final ref = _firestore
        .collection('icc_rankings')
        .doc(_gender)
        .collection(_format)
        .doc('teams')
        .collection('list');

    return StreamBuilder<QuerySnapshot>(
      stream: ref.orderBy('position').snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Error: ${snap.error}',
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (!snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: accent),
          );
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return _empty('No teams yet');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            return _teamRow(d);
          },
        );
      },
    );
  }

  Widget _teamRow(Map<String, dynamic> data) {
    final pos = data['position'] ?? 0;
    final isTop3 = pos >= 1 && pos <= 3;

    Color posColor = textLight;
    if (pos == 1) posColor = const Color(0xFFFFD700);
    if (pos == 2) posColor = const Color(0xFFC0C0C0);
    if (pos == 3) posColor = const Color(0xFFCD7F32);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isTop3
              ? posColor.withValues(alpha: 0.5)
              : divider,
          width: isTop3 ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: posColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '#$pos',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: posColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['team'] ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textLight,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    _statChip('M', '${data['matches'] ?? 0}'),
                    const SizedBox(width: 6),
                    _statChip('P', '${data['points'] ?? 0}'),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${data['rating'] ?? 0}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isTop3 ? posColor : accent,
                ),
              ),
              const Text(
                'rating',
                style: TextStyle(fontSize: 10, color: textGrey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 10,
          color: textGrey,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ─────────── PLAYERS ───────────
  Widget _playersSection() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _playerCategory('batters', '🏏 BATTERS'),
        const SizedBox(height: 18),
        _playerCategory('bowlers', '🎯 BOWLERS'),
        const SizedBox(height: 18),
        _playerCategory('allrounders', '⚡ ALL ROUNDERS'),
      ],
    );
  }

  Widget _playerCategory(String category, String title) {
    final ref = _firestore
        .collection('icc_rankings')
        .doc(_gender)
        .collection(_format)
        .doc(category)
        .collection('list');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: accent,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: ref.orderBy('rank').snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Error: ${snap.error}',
                  style: const TextStyle(
                      color: Colors.redAccent, fontSize: 11),
                ),
              );
            }
            if (!snap.hasData) {
              return const Padding(
                padding: EdgeInsets.all(12),
                child: Center(
                  child: CircularProgressIndicator(color: accent),
                ),
              );
            }
            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'No entries yet',
                  style: TextStyle(color: textGrey, fontSize: 12),
                ),
              );
            }
            return Column(
              children: docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                return _playerRow(d);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _playerRow(Map<String, dynamic> data) {
    final rank = data['rank'] ?? 0;
    final isTop3 = rank >= 1 && rank <= 3;

    Color rankColor = textLight;
    if (rank == 1) rankColor = const Color(0xFFFFD700);
    if (rank == 2) rankColor = const Color(0xFFC0C0C0);
    if (rank == 3) rankColor = const Color(0xFFCD7F32);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isTop3
              ? rankColor.withValues(alpha: 0.4)
              : divider,
          width: isTop3 ? 1.2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isTop3
                  ? Icon(Icons.emoji_events, color: rankColor, size: 16)
                  : Text(
                      '$rank',
                      style: const TextStyle(
                        color: textGrey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isTop3 ? FontWeight.bold : FontWeight.w600,
                    color: textLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  data['country'] ?? '',
                  style: const TextStyle(
                    fontSize: 11,
                    color: textGrey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${data['rating'] ?? 0}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isTop3 ? rankColor : accent,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────── HELPERS ───────────
  Widget _dropdown({
    required String value,
    required List<String> items,
    required String Function(String) display,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: cardBg,
          style: const TextStyle(color: textLight),
          iconEnabledColor: textLight,
          items: items
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(display(e)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _tabBtn(String label, int idx) {
    final active = _tab == idx;
    return GestureDetector(
      onTap: () => setState(() => _tab = idx),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? accent : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: active ? accent : textGrey,
          ),
        ),
      ),
    );
  }

  Widget _empty(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.leaderboard_outlined, size: 64, color: Colors.grey[700]),
          const SizedBox(height: 12),
          Text(
            msg,
            style: const TextStyle(color: textGrey, fontSize: 14),
          ),
        ],
      ),
    );
  }
}