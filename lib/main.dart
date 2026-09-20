import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'firebase_options.dart';

// ─── APP COLORS (Original Theme) ───
class AppColors {
  static const Color primary = Color(0xFF1A73E8);
  static const Color darkBg = Color(0xFF1B1B2F);
  static const Color cardBg = Color(0xFF2D2D44);
  static const Color accent = Color(0xFF00C9A7);
  static const Color textLight = Color(0xFFEAEAEA);
  static const Color textGrey = Color(0xFF9E9E9E);
  static const Color divider = Color(0xFF3D3D5C);
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

// ─── LIVE SCORE TAB ───
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
        var filtered = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          int t = data['timestamp'] ?? now;
          return now - t < 518400000;
        }).toList();

        return ListView.builder(
          padding: EdgeInsets.all(10),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            var doc = filtered[index];
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
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isResult
                                  ? Colors.grey[600]
                                  : Colors.redAccent,
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
          },
        );
      },
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

  // ─── BATTING HEADER (Columns fixed) ───
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

  // ─── BATTER ROW (2-line layout, aligned with header) ───
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
          // ─── LINE 1: Name + Status ───
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
          // ─── LINE 2: Stats aligned with header ───
          Row(
            children: [
              // Name column ka khali space (flex 5)
              Expanded(flex: 5, child: SizedBox()),
              // R (flex 2)
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
              // B (flex 2)
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
              // 4s (flex 2)
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
              // 6s (flex 2)
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
              // SR (flex 3)
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

  // ─── BOWLER HEADER ───
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

// ─── NEWS TAB ───
class NewsTab extends StatelessWidget {
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
            color: AppColors.cardBg,
            child: Icon(Icons.broken_image, color: AppColors.textGrey),
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
            color: AppColors.cardBg,
            child: Icon(Icons.broken_image, color: AppColors.textGrey),
          ),
        );
      }
    } catch (e) {}
    return SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('news')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(child: Text("Error: ${snapshot.error}"));
        if (!snapshot.hasData)
          return Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty)
          return Center(
            child: Text(
              "No News Yet",
              style: TextStyle(color: AppColors.textGrey),
            ),
          );

        int now = DateTime.now().millisecondsSinceEpoch;
        var filtered = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          int t = data['timestamp'] ?? now;
          return now - t < 172800000;
        }).toList();

        return ListView.builder(
          padding: EdgeInsets.all(10),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            var news = filtered[index].data() as Map<String, dynamic>;
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
                color: AppColors.cardBg,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            news['title'] ?? "",
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            news['desc'] ?? "",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppColors.textGrey),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "Tap to read more...",
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          "News Detail",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailImage(),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    newsData['title'] ?? "",
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Divider(color: AppColors.textGrey),
                  SizedBox(height: 12),
                  Text(
                    newsData['desc'] ?? "",
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                  SizedBox(height: 20),
                  if ((newsData['fullDesc'] ?? "").toString().isNotEmpty)
                    Text(
                      newsData['fullDesc'],
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 16,
                        height: 1.6,
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
              if (txnCtrl.text.isEmpty) return;
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setString('pending_txn', txnCtrl.text);
              await prefs.setString('pending_type', type);
              await prefs.setInt('pending_amount', amount);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Request Sent!")),
              );
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