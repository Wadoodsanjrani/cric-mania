import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

// ─── APP COLORS ───
class AppColors {
  static const Color primary = Color(0xFF1A73E8);
  static const Color darkBg = Color(0xFF1B1B2F);
  static const Color cardBg = Color(0xFF2D2D44);
  static const Color accent = Color(0xFF00C9A7);
  static const Color textLight = Color(0xFFEAEAEA);
  static const Color textGrey = Color(0xFF9E9E9E);
  static const Color divider = Color(0xFF3D3D5C);
  static const Color newsBg = Color(0xFFFAF9F6);
  static const Color newsCard = Colors.white;
  static const Color newsText = Color(0xFF1B1B2F);
  static const Color newsTextGrey = Color(0xFF6B6B6B);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(CricManiaApp());
}

class CricManiaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cric Mania',
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.darkBg,
      ),
      home: MainTabs(),
    );
  }
}

// ─── MAIN TABS ───
class MainTabs extends StatefulWidget {
  @override
  _MainTabsState createState() => _MainTabsState();
}

class _MainTabsState extends State<MainTabs> {
  int _index = 0;
  final List<Widget> _tabs = [LiveScoreTab(), NewsTab()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          "CRIC MANIA",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _tabs[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textGrey,
        backgroundColor: AppColors.cardBg,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_cricket),
            label: "Live Score",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.newspaper), label: "News"),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// LIVE SCORE TAB — 3 TABS (LIVE + UPCOMING + RECENT)
// ═══════════════════════════════════════════════════════════
class LiveScoreTab extends StatefulWidget {
  @override
  _LiveScoreTabState createState() => _LiveScoreTabState();
}

class _LiveScoreTabState extends State<LiveScoreTab> {
  int _matchTab = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.cardBg,
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _matchTab = 0),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _matchTab == 0
                              ? AppColors.accent
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _matchTab == 0
                                ? Colors.redAccent
                                : AppColors.textGrey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          "LIVE",
                          style: TextStyle(
                            color: _matchTab == 0
                                ? AppColors.accent
                                : AppColors.textGrey,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _matchTab = 1),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _matchTab == 1
                              ? AppColors.accent
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 13,
                          color: _matchTab == 1
                              ? AppColors.accent
                              : AppColors.textGrey,
                        ),
                        SizedBox(width: 6),
                        Text(
                          "UPCOMING",
                          style: TextStyle(
                            color: _matchTab == 1
                                ? AppColors.accent
                                : AppColors.textGrey,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _matchTab = 2),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _matchTab == 2
                              ? AppColors.accent
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 14,
                          color: _matchTab == 2
                              ? AppColors.accent
                              : AppColors.textGrey,
                        ),
                        SizedBox(width: 6),
                        Text(
                          "RECENT",
                          style: TextStyle(
                            color: _matchTab == 2
                                ? AppColors.accent
                                : AppColors.textGrey,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('matches')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return Center(child: CircularProgressIndicator());
              if (snapshot.data!.docs.isEmpty)
                return Center(
                  child: Text(
                    "No Matches Yet",
                    style: TextStyle(color: AppColors.textGrey),
                  ),
                );

              var allMatches = snapshot.data!.docs;

              List<QueryDocumentSnapshot> displayMatches = [];
              if (_matchTab == 0) {
                displayMatches = allMatches.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String st = (data['status'] ?? 'LIVE').toString().toUpperCase();
                  return st == 'LIVE';
                }).toList();
              } else if (_matchTab == 1) {
                displayMatches = allMatches.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String st = (data['status'] ?? '').toString().toUpperCase();
                  return st == 'UPCOMING';
                }).toList();
              } else {
                displayMatches = allMatches.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String st = (data['status'] ?? '').toString().toUpperCase();
                  return st == 'RESULT' ||
                      st.contains('FINISH') ||
                      st.contains('ENDED');
                }).toList();
              }

              if (displayMatches.isEmpty) {
                String emptyMsg = "";
                if (_matchTab == 0) emptyMsg = "No Live Matches";
                if (_matchTab == 1) emptyMsg = "No Upcoming Matches";
                if (_matchTab == 2) emptyMsg = "No Recent Matches";

                return Center(
                  child: Text(
                    emptyMsg,
                    style: TextStyle(color: AppColors.textGrey),
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.all(10),
                itemCount: displayMatches.length,
                itemBuilder: (context, index) {
                  return _matchCard(context, displayMatches[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _matchCard(BuildContext context, dynamic doc) {
    var m = doc.data() as Map<String, dynamic>;
    String status = (m['status'] ?? "LIVE").toString().toUpperCase();
    bool isResult = status == 'RESULT' ||
        status.contains("FINISH") ||
        status.contains("ENDED");
    bool isUpcoming = status == 'UPCOMING';

    Color badgeColor = Colors.redAccent;
    if (isResult) badgeColor = Colors.grey[600]!;
    if (isUpcoming) badgeColor = Colors.orange;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MatchDetailScreen(matchId: doc.id),
        ),
      ),
      child: Card(
        color: AppColors.cardBg,
        margin: EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((m['tournament'] ?? "").toString().isNotEmpty)
                Text(
                  m['tournament'],
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "${m['team1']} vs ${m['team2']}",
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              if (!isUpcoming) ...[
                Text(
                  "${m['team1']}: ${m['score1']}",
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${m['team2']}: ${m['score2']}",
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ] else ...[
                Text(
                  "Match will start soon",
                  style: TextStyle(
                    color: AppColors.textGrey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              if ((m['result'] ?? "").toString().isNotEmpty) ...[
                SizedBox(height: 5),
                Text(
                  m['result'],
                  style: TextStyle(color: AppColors.accent),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// MATCH DETAIL SCREEN — 2 TABS (Scorecard + Playing XI)
// ═══════════════════════════════════════════════════════════
class MatchDetailScreen extends StatefulWidget {
  final String matchId;
  MatchDetailScreen({required this.matchId});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  int _detailTab = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.matchId)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData)
          return Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors.primary,
              title: Text("Scorecard"),
            ),
            body: Center(child: CircularProgressIndicator()),
          );

        var m = (snap.data!.data() as Map<String, dynamic>?) ?? {};

        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.darkBg,
            title: Text(
              "Scorecard",
              style: TextStyle(
                color: AppColors.textLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            iconTheme: IconThemeData(color: AppColors.textLight),
          ),
          body: Column(
            children: [
              Container(
                color: AppColors.cardBg,
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _detailTab = 0),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: _detailTab == 0
                                    ? AppColors.accent
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Text(
                            "Scorecard",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _detailTab == 0
                                  ? AppColors.accent
                                  : AppColors.textGrey,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _detailTab = 1),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: _detailTab == 1
                                    ? AppColors.accent
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Text(
                            "Playing XI",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _detailTab == 1
                                  ? AppColors.accent
                                  : AppColors.textGrey,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _detailTab == 0
                    ? _buildScorecardTab(m)
                    : _buildPlayingXITab(m),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScorecardTab(Map<String, dynamic> m) {
    String format = (m['format'] ?? 'ODI').toString().toUpperCase();
    bool isTest = format == 'TEST';

    String team1 = m['team1'] ?? 'Team 1';
    String team2 = m['team2'] ?? 'Team 2';

    return ListView(
      padding: EdgeInsets.all(8),
      children: [
        if ((m['toss'] ?? "").toString().isNotEmpty)
          Container(
            margin: EdgeInsets.only(bottom: 10),
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.accent, width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.accent, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    m['toss'],
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),

        if ((m['manOfTheMatch'] ?? "").toString().isNotEmpty)
          Container(
            margin: EdgeInsets.only(bottom: 10),
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber, width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Man of the Match",
                        style: TextStyle(
                          color: Colors.amber[200],
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        m['manOfTheMatch'],
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        if (isTest) ...[
          _buildTestInnings(m, 'innings1', '1st Innings'),
          _buildTestInnings(m, 'innings2', '2nd Innings'),
          _buildTestInnings(m, 'innings3', '3rd Innings'),
          _buildTestInnings(m, 'innings4', '4th Innings'),
        ] else ...[
          var team1Bat = m['team1Batting'] ?? [];
          var team1Bowl = m['team1Bowling'] ?? [];
          var team2Bat = m['team2Batting'] ?? [];
          var team2Bowl = m['team2Bowling'] ?? [];

          String score1 = m['score1'] ?? '';
          String score2 = m['score2'] ?? '';

          _scorecardSection("$team1 — $score1", team1Bat, team2Bowl),
          _scorecardSection("$team2 — $score2", team2Bat, team1Bowl),
        ],
      ],
    );
  }

  Widget _buildPlayingXITab(Map<String, dynamic> m) {
    String team1 = m['team1'] ?? 'Team 1';
    String team2 = m['team2'] ?? 'Team 2';

    var team1XI = m['team1PlayingXI'] ?? [];
    var team2XI = m['team2PlayingXI'] ?? [];
    var team1Bench = m['team1Bench'] ?? [];
    var team2Bench = m['team2Bench'] ?? [];
    var team1Staff = m['team1Staff'] ?? [];
    var team2Staff = m['team2Staff'] ?? [];

    bool hasAny = team1XI.isNotEmpty ||
        team2XI.isNotEmpty ||
        team1Bench.isNotEmpty ||
        team2Bench.isNotEmpty ||
        team1Staff.isNotEmpty ||
        team2Staff.isNotEmpty;

    if (!hasAny) {
      return Center(
        child: Text(
          "No Playing XI Available",
          style: TextStyle(color: AppColors.textGrey, fontSize: 15),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.all(10),
      children: [
        if (team1XI.isNotEmpty || team2XI.isNotEmpty) ...[
          _tabHeader("🏏 PLAYING XI"),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _teamList(team1, team1XI)),
              SizedBox(width: 8),
              Expanded(child: _teamList(team2, team2XI)),
            ],
          ),
        ],

        SizedBox(height: 16),

        if (team1Bench.isNotEmpty || team2Bench.isNotEmpty) ...[
          _tabHeader("🪑 BENCH"),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _teamList(team1, team1Bench)),
              SizedBox(width: 8),
              Expanded(child: _teamList(team2, team2Bench)),
            ],
          ),
        ],

        SizedBox(height: 16),

        if (team1Staff.isNotEmpty || team2Staff.isNotEmpty) ...[
          _tabHeader("👔 STAFF"),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _teamList(team1, team1Staff)),
              SizedBox(width: 8),
              Expanded(child: _teamList(team2, team2Staff)),
            ],
          ),
        ],

        SizedBox(height: 20),
      ],
    );
  }

  Widget _tabHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10, top: 6),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.accent,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _teamList(String teamName, var players) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            teamName,
            style: TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 6),
          if (players.isEmpty)
            Text(
              "No players",
              style: TextStyle(
                color: AppColors.textGrey,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ...players.asMap().entries.map((entry) {
            Map p = entry.value is Map ? entry.value : {};
            String name = p['name'] ?? '';
            String role = p['role'] ?? '';
            return Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${entry.key + 1}. $name",
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (role.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(left: 14),
                      child: Text(
                        role,
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTestInnings(
      Map<String, dynamic> m, String inningsKey, String label) {
    Map<String, dynamic>? innings = m[inningsKey] as Map<String, dynamic>?;

    if (innings == null || innings.isEmpty) {
      return Card(
        color: AppColors.cardBg,
        margin: EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            "$label — No data",
            style: TextStyle(
              color: AppColors.textGrey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    String battingTeam = innings['team'] ?? '';
    var batting = innings['batting'] ?? [];
    var bowling = innings['bowling'] ?? [];

    return _scorecardSection(
      "$battingTeam — $label",
      batting,
      bowling,
    );
  }

  Widget _scorecardSection(String title, var batting, var bowling) {
    return Card(
      color: AppColors.cardBg,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        initiallyExpanded: true,
        iconColor: AppColors.accent,
        collapsedIconColor: AppColors.textGrey,
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textLight,
          ),
        ),
        children: [
          _battingHeader(),
          if (batting.isEmpty)
            Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                "No batting data",
                style: TextStyle(color: AppColors.textGrey),
              ),
            ),
          ...batting.map((b) => _batterRow(b)).toList(),
          _bowlerHeader(),
          if (bowling.isEmpty)
            Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                "No bowling data",
                style: TextStyle(color: AppColors.textGrey),
              ),
            ),
          ...bowling.map((b) => _bowlerRow(b)).toList(),
        ],
      ),
    );
  }

  Widget _battingHeader() => Container(
        decoration: BoxDecoration(
          color: AppColors.darkBg.withOpacity(0.6),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Text(
                "BATSMAN",
                style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                "R",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                "B",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                "4s",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                "6s",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                "SR",
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _batterRow(dynamic b) {
    Map data = b is Map ? b : {};
    String name = data['name'] ?? '';
    String status = data['howOut'] ?? '';
    String r = data['r'] ?? '0';
    String b_ = data['b'] ?? '0';
    String fours = data['4s'] ?? '0';
    String sixes = data['6s'] ?? '0';
    String sr = data['sr'] ?? '0';

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (status.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Row(
            children: [
              Expanded(flex: 5, child: SizedBox()),
              Expanded(
                flex: 2,
                child: Text(
                  r,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  b_,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  fours,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  sixes,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  sr,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bowlerHeader() => Container(
        color: AppColors.darkBg.withOpacity(0.6),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: EdgeInsets.only(top: 10),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                "BOWLER",
                style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Expanded(
              child: Text(
                "O",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            Expanded(
              child: Text(
                "M",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            Expanded(
              child: Text(
                "R",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            Expanded(
              child: Text(
                "W",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _bowlerRow(dynamic b) {
    Map data = b is Map ? b : {};
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              "${data['name'] ?? ''}",
              style: TextStyle(color: AppColors.accent, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              "${data['o'] ?? 0}",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textLight, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              "${data['m'] ?? 0}",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textLight, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              "${data['r'] ?? 0}",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textLight, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              "${data['w'] ?? 0}",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textLight, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// NEWS TAB — 2 TABS (LATEST + OLDER NEWS)
// ═══════════════════════════════════════════════════════════
class NewsTab extends StatefulWidget {
  @override
  _NewsTabState createState() => _NewsTabState();
}

class _NewsTabState extends State<NewsTab> {
  String _selectedLanguage = 'en';
  int _newsTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.newsBg,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: Text("English"),
                  selected: _selectedLanguage == 'en',
                  onSelected: (val) {
                    setState(() => _selectedLanguage = 'en');
                  },
                  selectedColor: AppColors.accent,
                  backgroundColor: Colors.grey[200],
                  labelStyle: TextStyle(
                    color: _selectedLanguage == 'en'
                        ? Colors.white
                        : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 12),
                ChoiceChip(
                  label: Text(
                    "اردو",
                    style: TextStyle(
                      fontFamily: 'NotoNastaliqUrdu',
                      fontSize: 16,
                    ),
                  ),
                  selected: _selectedLanguage == 'ur',
                  onSelected: (val) {
                    setState(() => _selectedLanguage = 'ur');
                  },
                  selectedColor: AppColors.accent,
                  backgroundColor: Colors.grey[200],
                  labelStyle: TextStyle(
                    color: _selectedLanguage == 'ur'
                        ? Colors.white
                        : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Container(
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _newsTab = 0),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _newsTab == 0
                                ? AppColors.accent
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        _selectedLanguage == 'ur'
                            ? "تازہ خبریں"
                            : "LATEST",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _newsTab == 0
                              ? AppColors.accent
                              : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 1,
                          fontFamily: _selectedLanguage == 'ur'
                              ? 'NotoNastaliqUrdu'
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _newsTab = 1),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _newsTab == 1
                                ? AppColors.accent
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        _selectedLanguage == 'ur'
                            ? "پرانی خبریں"
                            : "OLDER NEWS",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _newsTab == 1
                              ? AppColors.accent
                              : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 1,
                          fontFamily: _selectedLanguage == 'ur'
                              ? 'NotoNastaliqUrdu'
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('news')
                  .where('language', isEqualTo: _selectedLanguage)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return Center(
                    child: Text(
                      "Error: ${snapshot.error}",
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  );
                if (!snapshot.hasData)
                  return Center(child: CircularProgressIndicator());
                if (snapshot.data!.docs.isEmpty)
                  return Center(
                    child: Text(
                      _selectedLanguage == 'ur'
                          ? "کوئی خبر نہیں"
                          : "No News Yet",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontFamily: _selectedLanguage == 'ur'
                            ? 'NotoNastaliqUrdu'
                            : null,
                        fontSize: _selectedLanguage == 'ur' ? 18 : 14,
                      ),
                    ),
                  );

                int now = DateTime.now().millisecondsSinceEpoch;
                var allNews = snapshot.data!.docs;

                var latestNews = allNews.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  int t = data['timestamp'] ?? now;
                  return now - t < 172800000;
                }).toList();

                var olderNews = allNews.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  int t = data['timestamp'] ?? now;
                  return now - t >= 172800000;
                }).toList();

                var displayNews = _newsTab == 0 ? latestNews : olderNews;

                if (displayNews.isEmpty) {
                  return Center(
                    child: Text(
                      _newsTab == 0
                          ? (_selectedLanguage == 'ur'
                              ? "کوئی تازہ خبر نہیں"
                              : "No Latest News")
                          : (_selectedLanguage == 'ur'
                              ? "کوئی پرانی خبر نہیں"
                              : "No Older News"),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontFamily: _selectedLanguage == 'ur'
                            ? 'NotoNastaliqUrdu'
                            : null,
                        fontSize: _selectedLanguage == 'ur' ? 18 : 14,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(10),
                  itemCount: displayNews.length,
                  itemBuilder: (context, index) {
                    return _newsCard(context, displayNews[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _newsCard(BuildContext context, dynamic doc) {
    var news = doc.data() as Map<String, dynamic>;
    bool isUrdu = news['language'] == 'ur';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NewsDetailScreen(newsData: news),
          ),
        );
      },
      child: Card(
        color: AppColors.newsCard,
        elevation: 2,
        margin: EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNewsImage(news),
            Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: isUrdu
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isUrdu ? Colors.orange : Colors.blue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isUrdu ? "اردو" : "ENGLISH",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: isUrdu ? 'NotoNastaliqUrdu' : null,
                      ),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    news['title'] ?? "",
                    style: TextStyle(
                      color: AppColors.newsText,
                      fontWeight: FontWeight.bold,
                      fontSize: isUrdu ? 18 : 16,
                      fontFamily: isUrdu ? 'NotoNastaliqUrdu' : null,
                    ),
                    textDirection:
                        isUrdu ? TextDirection.rtl : TextDirection.ltr,
                  ),
                  SizedBox(height: 5),
                  Text(
                    news['desc'] ?? "",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.newsTextGrey,
                      fontFamily: isUrdu ? 'NotoNastaliqUrdu' : null,
                      fontSize: isUrdu ? 16 : 14,
                    ),
                    textDirection:
                        isUrdu ? TextDirection.rtl : TextDirection.ltr,
                  ),
                  SizedBox(height: 5),
                  Text(
                    isUrdu ? "مزید پڑھیں..." : "Tap to read more...",
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: isUrdu ? 'NotoNastaliqUrdu' : null,
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

  Widget _buildNewsImage(Map<String, dynamic> news) {
    try {
      if (news['imageBase64'] != null &&
          (news['imageBase64'] as String).isNotEmpty) {
        return Image.memory(
          base64Decode(news['imageBase64']),
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) => Container(
            height: 150,
            color: Colors.grey[300],
            child: Icon(Icons.broken_image, color: Colors.grey[600]),
          ),
        );
      }
      if (news['imageUrl'] != null &&
          (news['imageUrl'] as String).isNotEmpty) {
        return Image.network(
          news['imageUrl'],
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) => Container(
            height: 150,
            color: Colors.grey[300],
            child: Icon(Icons.broken_image, color: Colors.grey[600]),
          ),
        );
      }
    } catch (e) {}
    return SizedBox();
  }
}

// ─── NEWS DETAIL SCREEN ───
class NewsDetailScreen extends StatelessWidget {
  final Map<String, dynamic> newsData;
  NewsDetailScreen({required this.newsData});

  Widget _buildDetailImage() {
    try {
      if (newsData['imageBase64'] != null &&
          (newsData['imageBase64'] as String).isNotEmpty) {
        return Image.memory(
          base64Decode(newsData['imageBase64']),
          width: double.infinity,
          fit: BoxFit.cover,
        );
      }
      if (newsData['imageUrl'] != null &&
          (newsData['imageUrl'] as String).isNotEmpty) {
        return Image.network(
          newsData['imageUrl'],
          width: double.infinity,
          fit: BoxFit.cover,
        );
      }
    } catch (e) {}
    return SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    bool isUrdu = newsData['language'] == 'ur';

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          isUrdu ? "خبر کی تفصیل" : "News Detail",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: isUrdu ? 'NotoNastaliqUrdu' : null,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: isUrdu
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            _buildDetailImage(),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: isUrdu
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isUrdu ? Colors.orange : Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isUrdu ? "اردو" : "ENGLISH",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: isUrdu ? 'NotoNastaliqUrdu' : null,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    newsData['title'] ?? "",
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: isUrdu ? 24 : 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: isUrdu ? 'NotoNastaliqUrdu' : null,
                    ),
                    textDirection:
                        isUrdu ? TextDirection.rtl : TextDirection.ltr,
                  ),
                  SizedBox(height: 12),
                  Divider(color: AppColors.divider),
                  SizedBox(height: 12),
                  Text(
                    newsData['desc'] ?? "",
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: isUrdu ? 18 : 16,
                      height: 1.8,
                      fontFamily: isUrdu ? 'NotoNastaliqUrdu' : null,
                    ),
                    textDirection:
                        isUrdu ? TextDirection.rtl : TextDirection.ltr,
                  ),
                  SizedBox(height: 20),
                  if ((newsData['fullDesc'] ?? "").toString().isNotEmpty)
                    Text(
                      newsData['fullDesc'],
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: isUrdu ? 18 : 16,
                        height: 1.8,
                        fontFamily: isUrdu ? 'NotoNastaliqUrdu' : null,
                      ),
                      textDirection:
                          isUrdu ? TextDirection.rtl : TextDirection.ltr,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}