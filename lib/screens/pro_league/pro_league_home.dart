import 'package:flutter/material.dart';
import 'rules_screen.dart';

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
  @override
  _ProLeagueHomeState createState() => _ProLeagueHomeState();
}

class _ProLeagueHomeState extends State<ProLeagueHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ─── HEADER ───
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, Color(0xFF0D47A1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.emoji_events,
                          color: Colors.amber, size: 32),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Cric Mania Pro League",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Free skill-based cricket contest. Win exciting physical gifts!",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // ─── TILES ───
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  _tile(
                    icon: Icons.emoji_events,
                    title: "Tournaments",
                    subtitle: "View active tournaments and join",
                    color: Colors.amber,
                    onTap: () {
                      _showComingSoon(context, "Tournaments");
                    },
                  ),
                  SizedBox(height: 12),
                  _tile(
                    icon: Icons.groups,
                    title: "My Squad",
                    subtitle: "View your submitted squad",
                    color: AppColors.accent,
                    onTap: () {
                      _showComingSoon(context, "My Squad");
                    },
                  ),
                  SizedBox(height: 12),
                  _tile(
                    icon: Icons.leaderboard,
                    title: "Leaderboard",
                    subtitle: "Check your rank and points",
                    color: Colors.orange,
                    onTap: () {
                      _showComingSoon(context, "Leaderboard");
                    },
                  ),
                  SizedBox(height: 12),
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
                  SizedBox(height: 24),

                  // ─── INFO CARD ───
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.divider,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
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
                        SizedBox(height: 12),
                        _bullet("Join an active tournament"),
                        _bullet("Create your squad (5 players per team)"),
                        _bullet("Earn points based on player performance"),
                        _bullet("Climb the leaderboard and win gifts"),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
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
                ],
              ),
            ),
          ],
        ),
      ),
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
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: AppColors.textGrey, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 6),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
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

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$feature — Coming Soon"),
        backgroundColor: AppColors.accent,
        duration: Duration(seconds: 2),
      ),
    );
  }
}