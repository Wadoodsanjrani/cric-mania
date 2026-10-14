import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'rules_screen.dart';
import '../tournament_list_screen.dart';
import '../squad/my_squad_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../fpod/fpod_screen.dart';
import '../winner/winner_screen.dart';
import '../prize/prize_screen.dart';

class AppColors {
  static const Color primary = Color(0xFF1A73E8);
  static const Color darkBg = Color(0xFF1B1B2F);
  static const Color cardBg = Color(0xFF2D2D44);
  static const Color accent = Color(0xFF00C9A7);
  static const Color textLight = Color(0xFFEAEAEA);
  static const Color textGrey = Color(0xFF9E9E9E);
  static const Color divider = Color(0xFF3D3D5C);
}

class ProLeagueHome extends StatefulWidget {
  const ProLeagueHome({super.key});

  @override
  State<ProLeagueHome> createState() => _ProLeagueHomeState();
}

class _ProLeagueHomeState extends State<ProLeagueHome>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  List<QueryDocumentSnapshot> _tournaments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTournaments();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadTournaments() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('tournaments')
          .where('status', isEqualTo: 'active')
          .get();

      final docs = snap.docs;

      if (!mounted) return;
      setState(() {
        _tournaments = docs;
        _loading = false;
        if (docs.isNotEmpty) {
          _tabController?.dispose();
          _tabController = TabController(
            length: docs.length,
            vsync: this,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            )
          : _tournaments.isEmpty
              ? _noTournamentsView()
              : _tournamentsView(),
    );
  }

  Widget _noTournamentsView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events,
                size: 80, color: Colors.grey[600]),
            const SizedBox(height: 16),
            const Text(
              "No active tournament",
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Tournaments will appear here once admin creates them.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tournamentsView() {
    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
              vertical: 20, horizontal: 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, Color(0xFF0D47A1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.emoji_events,
                      color: Colors.amber, size: 28),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Cric Mania Pro League",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Text(
                "Free skill-based cricket contest. Win physical gifts!",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // Tabs
        if (_tabController != null)
          Container(
            color: AppColors.cardBg,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.accent,
              unselectedLabelColor: AppColors.textGrey,
              indicatorColor: AppColors.accent,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              tabs: _tournaments.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['name'] ?? 'Tournament').toString();
                return Tab(text: name);
              }).toList(),
            ),
          ),

        // Tab content
        if (_tabController != null)
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tournaments.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['name'] ?? 'Tournament').toString();
                return _tournamentContent(doc.id, name);
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _tournamentContent(String tournamentId, String tournamentName) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _tile(
            icon: Icons.emoji_events,
            title: "Tournaments",
            subtitle: "View all tournaments",
            color: Colors.amber,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TournamentListScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _tile(
            icon: Icons.groups,
            title: "My Squad",
            subtitle: "View your squad for $tournamentName",
            color: AppColors.accent,
            onTap: () => _openScreen(
              MySquadScreen(
                tournamentId: tournamentId,
                tournamentName: tournamentName,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _tile(
            icon: Icons.leaderboard,
            title: "Leaderboard",
            subtitle: "Check rank and points",
            color: Colors.orange,
            onTap: () => _openScreen(
              LeaderboardScreen(
                tournamentId: tournamentId,
                tournamentName: tournamentName,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _tile(
            icon: Icons.star,
            title: "PLP of the Match",
            subtitle: "See latest top performer",
            color: Colors.amber,
            onTap: () => _openScreen(
              FpodScreen(
                tournamentId: tournamentId,
                tournamentName: tournamentName,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _tile(
            icon: Icons.card_giftcard,
            title: "Rewards",
            subtitle: "See tournament prizes",
            color: const Color(0xFFD4AF37),
            onTap: () => _openScreen(
              PrizeScreen(
                tournamentId: tournamentId,
                tournamentName: tournamentName,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _tile(
            icon: Icons.emoji_events,
            title: "Winners",
            subtitle: "See tournament champions",
            color: const Color(0xFFD4AF37),
            onTap: () => _openScreen(
              WinnerScreen(
                tournamentId: tournamentId,
                tournamentName: tournamentName,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _tile(
            icon: Icons.menu_book,
            title: "Rules",
            subtitle: "Official rules and disclaimer",
            color: Colors.lightBlue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RulesScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // How It Works card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: AppColors.accent, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "How It Works",
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _bullet("Join an active tournament"),
                _bullet("Create your squad (5 players per team)"),
                _bullet("Earn points based on player performance"),
                _bullet("Climb the leaderboard and win gifts"),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified,
                          color: AppColors.accent, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "100% Free • No Entry Fee • Skill-Based",
                          style: TextStyle(
                            color: AppColors.accent,
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
          ),

          const SizedBox(height: 16),

          // Disclaimer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFD4AF37), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "100% skill-based. We do NOT accept any fees or payments.",
                    style: TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: AppColors.textGrey, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}