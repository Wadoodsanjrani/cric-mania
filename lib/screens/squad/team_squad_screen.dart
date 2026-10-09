import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/squad_model.dart';
import '../../services/squad_service.dart';

class TeamSquadScreen extends StatefulWidget {
  final String tournamentId;
  final String teamId;
  final String teamName;
  final String teamFlag;

  const TeamSquadScreen({
    super.key,
    required this.tournamentId,
    required this.teamId,
    required this.teamName,
    required this.teamFlag,
  });

  @override
  State<TeamSquadScreen> createState() => _TeamSquadScreenState();
}

class _TeamSquadScreenState extends State<TeamSquadScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _squadService = SquadService();

  String get _userId => _auth.currentUser?.uid ?? '';
  String get _userName => _auth.currentUser?.displayName ?? 'Player';

  // Player selections
  String? _batterMain;
  String? _batterBackup;
  String? _bowlerMain;
  String? _bowlerBackup;
  String? _wildcard;
  String _wildcardRole = 'batter'; // 'batter' or 'bowler'

  bool _loading = true;
  bool _saving = false;
  List<Map<String, dynamic>> _players = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ─── Load players + existing squad ───
  Future<void> _loadData() async {
    try {
      // 1. Load players from teams/{teamId}/players
      final playersSnap = await _firestore
          .collection('tournaments')
          .doc(widget.tournamentId)
          .collection('teams')
          .doc(widget.teamId)
          .collection('players')
          .get();

      final players = playersSnap.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown',
          'role': data['role'] ?? '',
        };
      }).toList();

      // 2. Load existing squad (agar pehle save kiya ho)
      final existingSquad = await _squadService.getTeamSquad(
        widget.tournamentId,
        _userId,
        widget.teamId,
      );

      if (!mounted) return;

      setState(() {
        _players = players;

        if (existingSquad != null) {
          _batterMain = existingSquad.batterMain.isNotEmpty
              ? existingSquad.batterMain
              : null;
          _batterBackup = existingSquad.batterBackup.isNotEmpty
              ? existingSquad.batterBackup
              : null;
          _bowlerMain = existingSquad.bowlerMain.isNotEmpty
              ? existingSquad.bowlerMain
              : null;
          _bowlerBackup = existingSquad.bowlerBackup.isNotEmpty
              ? existingSquad.bowlerBackup
              : null;
          _wildcard = existingSquad.wildcard.isNotEmpty
              ? existingSquad.wildcard
              : null;
          if (existingSquad.wildcardRole.isNotEmpty) {
            _wildcardRole = existingSquad.wildcardRole;
          }
        }

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack('Error loading data: $e', isError: true);
    }
  }

  // ─── Validate ───
  String? _validate() {
    if (_batterMain == null) return 'Please select Batter Main';
    if (_batterBackup == null) return 'Please select Batter Backup';
    if (_bowlerMain == null) return 'Please select Bowler Main';
    if (_bowlerBackup == null) return 'Please select Bowler Backup';
    if (_wildcard == null) return 'Please select Wildcard';

    // Check duplicates
    final selected = [
      _batterMain,
      _batterBackup,
      _bowlerMain,
      _bowlerBackup,
      _wildcard,
    ];
    final uniqueSet = selected.toSet();
    if (uniqueSet.length != selected.length) {
      return 'Same player cannot be selected twice';
    }

    return null;
  }

  // ─── Save Team Squad ───
  Future<void> _save() async {
    final error = _validate();
    if (error != null) {
      _snack(error, isError: true);
      return;
    }

    setState(() => _saving = true);

    try {
      final teamSquad = TeamSquad(
        teamId: widget.teamId,
        teamName: widget.teamName,
        teamFlag: widget.teamFlag,
        batterMain: _batterMain!,
        batterBackup: _batterBackup!,
        bowlerMain: _bowlerMain!,
        bowlerBackup: _bowlerBackup!,
        wildcard: _wildcard!,
        wildcardRole: _wildcardRole,
      );

      // Get total teams count
      final teamsSnap = await _firestore
          .collection('tournaments')
          .doc(widget.tournamentId)
          .collection('teams')
          .get();

      await _squadService.saveTeamSquad(
        tournamentId: widget.tournamentId,
        userId: _userId,
        userName: _userName,
        teamSquad: teamSquad,
        totalTeams: teamsSnap.docs.length,
      );

      if (!mounted) return;

      _snack('Team saved!');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _snack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ─── Snack ───
  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : const Color(0xFF00C9A7),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1931),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1931),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Text(
              widget.teamFlag.isEmpty ? '🏏' : widget.teamFlag,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.teamName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00C9A7)),
            )
          : _players.isEmpty
              ? _noPlayersView()
              : _buildForm(),
    );
  }

  // ─── No Players View ───
  Widget _noPlayersView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, color: Colors.grey[600], size: 80),
            const SizedBox(height: 16),
            const Text(
              'No Players Available',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Players for this team have not been added yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Form ───
  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── HEADER ───
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select 5 Players',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose players from ${widget.teamName}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ─── BATTER MAIN ───
          _dropdown(
            label: 'BATTER MAIN',
            icon: Icons.sports_cricket,
            color: Colors.blue,
            value: _batterMain,
            onChanged: (val) => setState(() => _batterMain = val),
            filterRole: 'Batter',
          ),
          const SizedBox(height: 14),

          // ─── BATTER BACKUP ───
          _dropdown(
            label: 'BATTER BACKUP',
            icon: Icons.sports_cricket,
            color: Colors.blueGrey,
            value: _batterBackup,
            onChanged: (val) => setState(() => _batterBackup = val),
            filterRole: 'Batter',
          ),
          const SizedBox(height: 14),

          // ─── BOWLER MAIN ───
          _dropdown(
            label: 'BOWLER MAIN',
            icon: Icons.sports_baseball,
            color: Colors.orange,
            value: _bowlerMain,
            onChanged: (val) => setState(() => _bowlerMain = val),
            filterRole: 'Bowler',
          ),
          const SizedBox(height: 14),

          // ─── BOWLER BACKUP ───
          _dropdown(
            label: 'BOWLER BACKUP',
            icon: Icons.sports_baseball,
            color: Colors.orangeAccent,
            value: _bowlerBackup,
            onChanged: (val) => setState(() => _bowlerBackup = val),
            filterRole: 'Bowler',
          ),
          const SizedBox(height: 14),

          // ─── WILDCARD ───
          _dropdown(
            label: 'WILDCARD',
            icon: Icons.star,
            color: Colors.amber,
            value: _wildcard,
            onChanged: (val) => setState(() => _wildcard = val),
            filterRole: null, // all players
          ),
          const SizedBox(height: 10),

          // ─── WILDCARD ROLE ───
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D44),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'WILDCARD ROLE',
                  style: TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _roleButton(
                        label: 'Batter',
                        selected: _wildcardRole == 'batter',
                        onTap: () =>
                            setState(() => _wildcardRole = 'batter'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _roleButton(
                        label: 'Bowler',
                        selected: _wildcardRole == 'bowler',
                        onTap: () =>
                            setState(() => _wildcardRole = 'bowler'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── SAVE BUTTON ───
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Text(
                      'SAVE TEAM',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── Dropdown Widget ───
  Widget _dropdown({
    required String label,
    required IconData icon,
    required Color color,
    required String? value,
    required Function(String?) onChanged,
    String? filterRole,
  }) {
    // Filter players based on role
    final filteredPlayers = filterRole == null
        ? _players
        : _players.where((p) {
            final role = (p['role'] ?? '').toString().toLowerCase();
            return role.contains(filterRole.toLowerCase());
          }).toList();

    // If no filtered players, show all (fallback)
    final availablePlayers =
        filteredPlayers.isEmpty ? _players : filteredPlayers;

    // Selected value might not be in filtered list — handle that
    final validValue =
        availablePlayers.any((p) => p['name'] == value) ? value : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: validValue != null
              ? color.withValues(alpha: 0.5)
              : Colors.white24,
          width: validValue != null ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (validValue != null)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF00C9A7),
                  size: 16,
                ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: validValue,
              hint: Text(
                'Select player',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
              isExpanded: true,
              dropdownColor: const Color(0xFF1B1B2F),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              items: availablePlayers.map((p) {
                final name = p['name'] as String;
                final role = p['role'] as String;
                return DropdownMenuItem<String>(
                  value: name,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (role.isNotEmpty)
                        Text(
                          role,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Role Button ───
  Widget _roleButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF00C9A7).withValues(alpha: 0.15)
              : const Color(0xFF1B1B2F),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF00C9A7) : Colors.white24,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (selected) ...[
              const Icon(Icons.check_circle,
                  color: Color(0xFF00C9A7), size: 16),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? const Color(0xFF00C9A7) : Colors.white70,
                fontSize: 14,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}