import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/squad_model.dart';
import '../../services/squad_service.dart';

class MySquadScreen extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;

  const MySquadScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });

  @override
  State<MySquadScreen> createState() => _MySquadScreenState();
}

class _MySquadScreenState extends State<MySquadScreen>
    with SingleTickerProviderStateMixin {
  final _squadService = SquadService();
  final _userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  TabController? _tabController;
  List<TeamSquad> _teams = [];
  SquadModel? _squadInfo;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSquad();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadSquad() async {
    try {
      // Load squad parent info
      final squad = await _squadService.getSquad(
        widget.tournamentId,
        _userId,
      );

      // Load all team squads
      final teams = await _squadService
          .streamTeamSquads(widget.tournamentId, _userId)
          .first;

      if (!mounted) return;

      // Sort teams by name
      teams.sort((a, b) => a.teamName.compareTo(b.teamName));

      setState(() {
        _squadInfo = squad;
        _teams = teams;
        _loading = false;
        if (teams.isNotEmpty) {
          _tabController?.dispose();
          _tabController = TabController(
            length: teams.length,
            vsync: this,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load squad: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1B2F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A73E8),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "My Squad",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              widget.tournamentName,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00C9A7)),
            )
          : _error != null
              ? _errorView()
              : _teams.isEmpty
                  ? _emptyView()
                  : _squadView(),
    );
  }

  Widget _squadView() {
    return Column(
      children: [
        // ─── STATUS HEADER ───
        _statusHeader(),

        // ─── TEAM TABS ───
        if (_tabController != null)
          Container(
            color: const Color(0xFF2D2D44),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: const Color(0xFF00C9A7),
              unselectedLabelColor: const Color(0xFF9E9E9E),
              indicatorColor: const Color(0xFF00C9A7),
              indicatorWeight: 3,
              tabs: _teams
                  .map((team) => Tab(
                        text: _shortName(team.teamName),
                      ))
                  .toList(),
            ),
          ),

        // ─── TEAM CONTENT ───
        Expanded(
          child: _tabController == null
              ? const SizedBox()
              : TabBarView(
                  controller: _tabController,
                  children:
                      _teams.map((team) => _teamContent(team)).toList(),
                ),
        ),
      ],
    );
  }

  Widget _statusHeader() {
    final isLocked = _squadInfo?.locked ?? false;
    final status = _squadInfo?.status ?? 'draft';
    final submittedAt = _squadInfo?.submittedAt;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      color: const Color(0xFF2D2D44),
      child: Row(
        children: [
          // Status icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isLocked
                  ? const Color(0xFF00C9A7).withValues(alpha: 0.15)
                  : Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isLocked ? Icons.lock : Icons.edit,
              color: isLocked ? const Color(0xFF00C9A7) : Colors.orange,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // Status text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLocked
                      ? "Squad Locked"
                      : status == 'submitted'
                          ? "Submitted"
                          : "Draft (Not Submitted)",
                  style: TextStyle(
                    color: isLocked
                        ? const Color(0xFF00C9A7)
                        : Colors.orange,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (submittedAt != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    "Submitted: ${_formatDate(submittedAt)}",
                    style: const TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Teams count
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1B2F),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "${_squadInfo?.completedTeams ?? _teams.length}/${_squadInfo?.totalTeams ?? _teams.length}",
              style: const TextStyle(
                color: Color(0xFF00C9A7),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _teamContent(TeamSquad team) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── TEAM NAME ───
          Row(
            children: [
              Text(
                team.teamFlag.isNotEmpty ? team.teamFlag : '🏏',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  team.teamName,
                  style: const TextStyle(
                    color: Color(0xFFEAEAEA),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Complete/Pending badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: team.isTeamComplete
                      ? const Color(0xFF00C9A7).withValues(alpha: 0.15)
                      : Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      team.isTeamComplete ? Icons.check_circle : Icons.pending,
                      color: team.isTeamComplete
                          ? const Color(0xFF00C9A7)
                          : Colors.orange,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      team.isTeamComplete ? "Complete" : "Pending",
                      style: TextStyle(
                        color: team.isTeamComplete
                            ? const Color(0xFF00C9A7)
                            : Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ─── PLAYER CARDS ───
          _playerCard(
            label: "BATTER MAIN",
            playerName: team.batterMain,
            icon: Icons.sports_cricket,
            color: Colors.blue,
          ),
          const SizedBox(height: 10),
          _playerCard(
            label: "BATTER BACKUP",
            playerName: team.batterBackup,
            icon: Icons.sports_cricket,
            color: Colors.blueGrey,
          ),
          const SizedBox(height: 10),
          _playerCard(
            label: "BOWLER MAIN",
            playerName: team.bowlerMain,
            icon: Icons.sports_baseball,
            color: Colors.orange,
          ),
          const SizedBox(height: 10),
          _playerCard(
            label: "BOWLER BACKUP",
            playerName: team.bowlerBackup,
            icon: Icons.sports_baseball,
            color: Colors.orangeAccent,
          ),
          const SizedBox(height: 10),
          _playerCard(
            label: "WILDCARD",
            playerName: team.wildcard,
            icon: Icons.star,
            color: Colors.amber,
            extra: team.wildcardRole.isNotEmpty
                ? "Role: ${team.wildcardRole.toUpperCase()}"
                : null,
          ),
        ],
      ),
    );
  }

  Widget _playerCard({
    required String label,
    required String playerName,
    required IconData icon,
    required Color color,
    String? extra,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3D3D5C), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  playerName.isEmpty ? "Not selected" : playerName,
                  style: TextStyle(
                    color: playerName.isEmpty
                        ? const Color(0xFF6B6B6B)
                        : const Color(0xFFEAEAEA),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (extra != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    extra,
                    style: const TextStyle(
                      color: Color(0xFF00C9A7),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_outlined,
                color: Colors.grey[600], size: 80),
            const SizedBox(height: 16),
            const Text(
              "No Squad Yet",
              style: TextStyle(
                color: Color(0xFFEAEAEA),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "You haven't submitted a squad for this tournament.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  String _shortName(String fullName) {
    if (fullName.isEmpty) return "Team";
    final words = fullName.split(' ');
    if (words.length >= 2) {
      final first = words[0];
      return first.length > 7 ? first.substring(0, 7) : first;
    }
    return fullName.length > 7 ? fullName.substring(0, 7) : fullName;
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return "${months[date.month - 1]} ${date.day}, ${date.year} $hour:$minute";
  }
}