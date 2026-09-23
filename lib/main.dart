import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
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
  final List<Widget> _tabs = [LiveScoreTab(), NewsTab(), PremiumTab()];

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
          BottomNavigationBarItem(
            icon: Icon(Icons.workspace_premium),
            label: "Premium",
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// LIVE SCORE TAB — 2 SECTIONS (Active + Archived)
// ═══════════════════════════════════════════════════════════
class LiveScoreTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
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

        int now = DateTime.now().millisecondsSinceEpoch;
        var allMatches = snapshot.data!.docs;

        // Active: 6 din se kam
        var activeMatches = allMatches.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          int t = data['timestamp'] ?? now;
          return now - t < 518400000;
        }).toList();

        // Archived: 6 din se zyada
        var archivedMatches = allMatches.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          int t = data['timestamp'] ?? now;
          return now - t >= 518400000;
        }).toList();

        return ListView(
          padding: EdgeInsets.all(10),
          children: [
            // ─── ACTIVE MATCHES ───
            if (activeMatches.isNotEmpty) ...[
              _sectionHeader("LIVE / RECENT", AppColors.accent),
              ...activeMatches.map((doc) => _matchCard(context, doc)).toList(),
            ],

            // ─── ARCHIVED MATCHES ───
            if (archivedMatches.isNotEmpty) ...[
              _sectionHeader("ARCHIVED MATCHES", AppColors.textGrey),
              ...archivedMatches.map((doc) => _matchCard(context, doc)).toList(),
            ],
          ],
        );
      },
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(width: 3, height: 16, color: color),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _matchCard(BuildContext context, dynamic doc) {
    var m = doc.data() as Map<String, dynamic>;
    String status = (m['status'] ?? "LIVE").toString().toUpperCase();
    bool isResult = status.contains("RESULT") ||
        status.contains("FINISH") ||
        status.contains("ENDED");

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
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color:
                          isResult ? Colors.grey[600] : Colors.redAccent,
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
              SizedBox(height: 5),
              Text(
                m['result'] ?? "",
                style: TextStyle(color: AppColors.accent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── MATCH DETAIL SCREEN ───
class MatchDetailScreen extends StatelessWidget {
  final String matchId;
  MatchDetailScreen({required this.matchId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId)
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
          body: _buildScorecardTab(m),
        );
      },
    );
  }

  Widget _buildScorecardTab(Map<String, dynamic> m) {
    List team1Bat = m['team1Batting'] ?? [];
    List team1Bowl = m['team1Bowling'] ?? [];
    List team2Bat = m['team2Batting'] ?? [];
    List team2Bowl = m['team2Bowling'] ?? [];

    String team1 = m['team1'] ?? 'Team 1';
    String team2 = m['team2'] ?? 'Team 2';
    String score1 = m['score1'] ?? '';
    String score2 = m['score2'] ?? '';

    return ListView(
      padding: EdgeInsets.all(8),
      children: [
        _scorecardSection("$team1 — $score1", team1Bat, team2Bowl),
        _scorecardSection("$team2 — $score2", team2Bat, team1Bowl),
      ],
    );
  }

  Widget _scorecardSection(String title, List batting, List bowling) {
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
// NEWS TAB — 2 SECTIONS (Latest + Archived)
// ═══════════════════════════════════════════════════════════
class NewsTab extends StatefulWidget {
  @override
  _NewsTabState createState() => _NewsTabState();
}

class _NewsTabState extends State<NewsTab> {
  String _selectedLanguage = 'en';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.newsBg,
      body: Column(
        children: [
          // ─── LANGUAGE TOGGLE ───
          Container(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: Text("English"),
                  selected: _selectedLanguage == 'en',
                  onSelected: (val) =>
                      setState(() => _selectedLanguage = 'en'),
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
                  onSelected: (val) =>
                      setState(() => _selectedLanguage = 'ur'),
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
          // ─── NEWS LIST ───
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

                // Latest: 48 ghante se kam
                var latestNews = allNews.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  int t = data['timestamp'] ?? now;
                  return now - t < 172800000;
                }).toList();

                // Archived: 48 ghante se zyada
                var archivedNews = allNews.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  int t = data['timestamp'] ?? now;
                  return now - t >= 172800000;
                }).toList();

                return ListView(
                  padding: EdgeInsets.all(10),
                  children: [
                    // ─── LATEST NEWS ───
                    if (latestNews.isNotEmpty) ...[
                      _sectionHeader(
                        _selectedLanguage == 'ur'
                            ? "تازہ خبریں"
                            : "LATEST NEWS",
                        AppColors.accent,
                      ),
                      ...latestNews.map((doc) => _newsCard(context, doc)).toList(),
                    ],

                    // ─── ARCHIVED NEWS ───
                    if (archivedNews.isNotEmpty) ...[
                      _sectionHeader(
                        _selectedLanguage == 'ur'
                            ? "پرانی خبریں"
                            : "ARCHIVED NEWS",
                        Colors.grey[700]!,
                      ),
                      ...archivedNews.map((doc) => _newsCard(context, doc)).toList(),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(width: 3, height: 16, color: color),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 1,
              fontFamily: _selectedLanguage == 'ur'
                  ? 'NotoNastaliqUrdu'
                  : null,
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
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                    textDirection: isUrdu
                        ? TextDirection.rtl
                        : TextDirection.ltr,
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
                    textDirection: isUrdu
                        ? TextDirection.rtl
                        : TextDirection.ltr,
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
      if (news['imageUrl'] != null && (news['imageUrl'] as String).isNotEmpty) {
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

  void _shareNews() {
    String title = newsData['title'] ?? '';
    String desc = newsData['desc'] ?? '';
    String shareText = '$title\n\n$desc\n\nShared from Cric Mania app';

    Share.share(shareText, subject: title);
  }

  @override
  Widget build(BuildContext context) {
    bool isUrdu = newsData['language'] == 'ur';

    return Scaffold(
      backgroundColor: AppColors.newsBg,
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
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: Colors.white),
            onPressed: _shareNews,
            tooltip: 'Share',
          ),
        ],
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
                      color: AppColors.newsText,
                      fontSize: isUrdu ? 24 : 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: isUrdu ? 'NotoNastaliqUrdu' : null,
                    ),
                    textDirection:
                        isUrdu ? TextDirection.rtl : TextDirection.ltr,
                  ),
                  SizedBox(height: 12),
                  Divider(color: Colors.grey[400]),
                  SizedBox(height: 12),
                  Text(
                    newsData['desc'] ?? "",
                    style: TextStyle(
                      color: AppColors.newsText,
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
                        color: AppColors.newsText,
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

// ─── PREMIUM TAB ───
class PremiumTab extends StatefulWidget {
  @override
  _PremiumTabState createState() => _PremiumTabState();
}

class _PremiumTabState extends State<PremiumTab> {
  final String easyIban = "PK82TMFB0000000013806423";
  final String easyName = "Abdul Wadood";
  bool isPremiumActive = false;
  int? expiryDate;

  @override
  void initState() {
    super.initState();
    loadPremium();
  }

  loadPremium() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isPremiumActive = prefs.getBool('isPremium') ?? false;
      expiryDate = prefs.getInt('premium_expiry');
    });
  }

  void copyIban() {
    Clipboard.setData(ClipboardData(text: easyIban));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("IBAN Copied! $easyIban"),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "CRIC MANIA PREMIUM",
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "AD FREE",
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isPremiumActive && expiryDate != null)
                      Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Text(
                          "Premium Active Till: ${DateTime.fromMillisecondsSinceEpoch(expiryDate!).toString().substring(0, 10)}",
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Card(
                color: AppColors.cardBg,
                child: ListTile(
                  title: Text(
                    "Monthly - 30 RS",
                    style: TextStyle(color: AppColors.textLight),
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                    ),
                    onPressed: () => _payDialog("Monthly", 30),
                    child: Text("Buy", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
              Card(
                color: AppColors.cardBg,
                child: ListTile(
                  title: Text(
                    "Annual - 250 RS",
                    style: TextStyle(color: AppColors.textLight),
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                    ),
                    onPressed: () => _payDialog("Annual", 250),
                    child: Text("Buy", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.accent),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Send Payment To:",
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            easyIban,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.copy, color: AppColors.accent),
                          onPressed: copyIban,
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      easyName,
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      "Easypaisa Account",
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textGrey,
                      ),
                    ),
                    SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.copy, color: Colors.white, size: 18),
                        label: Text(
                          "Copy IBAN",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                        ),
                        onPressed: copyIban,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  _payDialog(String type, int amount) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text(
          "Pay $amount RS for $type",
          style: TextStyle(color: AppColors.textLight),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Send $amount RS to:",
              style: TextStyle(color: AppColors.textLight),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    easyIban,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.copy, color: AppColors.accent),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: easyIban));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("IBAN Copied!")),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              easyName,
              style: TextStyle(
                color: AppColors.textLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Easypaisa Account",
              style: TextStyle(fontSize: 12, color: AppColors.textGrey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: AppColors.textGrey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
            ),
            onPressed: () {
              Navigator.pop(context);
              _showTxnInput(type, amount);
            },
            child: Text(
              "I Have Paid",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  _showTxnInput(String type, int amount) {
    TextEditingController txnCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text(
          "Enter Transaction ID",
          style: TextStyle(color: AppColors.textLight),
        ),
        content: TextField(
          controller: txnCtrl,
          style: TextStyle(color: AppColors.textLight),
          decoration: InputDecoration(
            labelText: "TID",
            labelStyle: TextStyle(color: AppColors.textGrey),
            border: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.textGrey),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: AppColors.textGrey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
            ),
            onPressed: () async {
              if (txnCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("TID zaroori hai"),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                await FirebaseFirestore.instance
                    .collection('payment_requests')
                    .add({
                  'tid': txnCtrl.text.trim(),
                  'type': type,
                  'amount': amount,
                  'status': 'pending',
                  'timestamp': DateTime.now().millisecondsSinceEpoch,
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Request Sent! Admin verify karega."),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Error: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(
              "Submit",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}