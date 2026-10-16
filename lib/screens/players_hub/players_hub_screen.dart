import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'player_profile_screen.dart';

/// User App — Players Hub Screen
class PlayersHubScreen extends StatefulWidget {
  const PlayersHubScreen({super.key});

  @override
  State<PlayersHubScreen> createState() => _PlayersHubScreenState();
}

class _PlayersHubScreenState extends State<PlayersHubScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _nameCtrl = TextEditingController();

  static const Color bg = Color(0xFF1B1B2F);
  static const Color cardBg = Color(0xFF2D2D44);
  static const Color accent = Color(0xFF00C9A7);
  static const Color textLight = Color(0xFFEAEAEA);
  static const Color textGrey = Color(0xFF9E9E9E);
  static const Color divider = Color(0xFF3D3D5C);

  List<Map<String, dynamic>> _suggestions = [];
  Map<String, dynamic>? _selectedPlayer;
  List<String> _playerFormats = [];
  String _selectedFormat = 'Overall';
  bool _searching = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  // ─── Search players by name prefix ───
  Future<void> _searchPlayers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _selectedPlayer = null;
        _playerFormats = [];
        _selectedFormat = 'Overall';
      });
      return;
    }

    setState(() => _searching = true);

    try {
      final snap = await _firestore
          .collection('player_hub')
          .orderBy('name')
          .get();

      final q = query.trim().toLowerCase();
      final matches = snap.docs.where((doc) {
        final d = doc.data();
        final name = (d['name'] ?? '').toString().toLowerCase();
        final fullName = (d['fullName'] ?? '').toString().toLowerCase();
        return name.contains(q) || fullName.contains(q);
      }).map((doc) {
        return {
          'id': doc.id,
          'data': doc.data(),
        };
      }).toList();

      setState(() {
        _suggestions = matches;
        _searching = false;
      });
    } catch (e) {
      setState(() => _searching = false);
      _snack('Error: $e');
    }
  }

  // ─── Select a player ───
  void _selectPlayer(Map<String, dynamic> player) {
    final data = player['data'] as Map<String, dynamic>;
    final stats = data['stats'] as Map<String, dynamic>? ?? {};

    final formats = stats.keys.toList();

    setState(() {
      _selectedPlayer = player;
      _playerFormats = formats;
      _selectedFormat = 'Overall';
      _suggestions = [];
      _nameCtrl.text = (data['name'] ?? '').toString();
    });
  }

  // ─── Open profile ───
  void _openProfile() {
    if (_selectedPlayer == null) {
      _snack('Please select a player first');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerProfileScreen(
          playerId: _selectedPlayer!['id'] as String,
          selectedFormat: _selectedFormat,
        ),
      ),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A73E8),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Players Hub',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Player Name Input ───
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: textLight),
              onChanged: (v) {
                _searchPlayers(v);
              },
              decoration: InputDecoration(
                hintText: 'Search player by name',
                hintStyle: const TextStyle(color: textGrey),
                prefixIcon: const Icon(Icons.search, color: textGrey),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: accent,
                          ),
                        ),
                      )
                    : _nameCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: textGrey),
                            onPressed: () {
                              _nameCtrl.clear();
                              setState(() {
                                _suggestions = [];
                                _selectedPlayer = null;
                                _playerFormats = [];
                                _selectedFormat = 'Overall';
                              });
                            },
                          )
                        : null,
                filled: true,
                fillColor: cardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: accent, width: 1.5),
                ),
              ),
            ),

            // ─── Suggestions ───
            if (_suggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: divider),
                ),
                constraints: const BoxConstraints(maxHeight: 260),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _suggestions.length,
                  itemBuilder: (context, i) {
                    final p = _suggestions[i];
                    final d = p['data'] as Map<String, dynamic>;
                    final photoBase64 = (d['photoBase64'] ?? '').toString();
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: cardBg,
                        backgroundImage: photoBase64.isNotEmpty
                            ? MemoryImage(_safeBase64Decode(photoBase64))
                            : null,
                        child: photoBase64.isEmpty
                            ? const Icon(Icons.person, color: textGrey)
                            : null,
                      ),
                      title: Text(
                        (d['name'] ?? '').toString(),
                        style: const TextStyle(
                          color: textLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: (d['role'] ?? '').toString().isNotEmpty
                          ? Text(
                              d['role'].toString(),
                              style: const TextStyle(color: textGrey),
                            )
                          : null,
                      onTap: () => _selectPlayer(p),
                    );
                  },
                ),
              ),

            const SizedBox(height: 16),

            // ─── Format Dropdown ───
            if (_selectedPlayer != null) ...[
              const Text(
                'Format',
                style: TextStyle(
                  color: textGrey,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: divider),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedFormat,
                    isExpanded: true,
                    dropdownColor: cardBg,
                    style: const TextStyle(color: textLight),
                    iconEnabledColor: textLight,
                    items: [
                      const DropdownMenuItem(
                        value: 'Overall',
                        child: Text('Overall'),
                      ),
                      ..._playerFormats.map(
                        (f) => DropdownMenuItem(
                          value: f,
                          child: Text(f),
                        ),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => _selectedFormat = v!),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ─── Go Button ───
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.arrow_forward,
                      color: Color(0xFF1B1B2F)),
                  label: const Text(
                    'VIEW PROFILE',
                    style: TextStyle(
                      color: Color(0xFF1B1B2F),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  onPressed: _openProfile,
                ),
              ),
            ] else
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_search,
                          size: 80, color: textGrey),
                      SizedBox(height: 12),
                      Text(
                        'Search a player to view profile',
                        style: TextStyle(color: textGrey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
          ],
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