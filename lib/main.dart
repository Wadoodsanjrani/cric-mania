import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'firebase_options.dart';

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
      theme: ThemeData(primaryColor: Color(0xFF00BFFF)),
      home: MainTabs(),
    );
  }
}

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
        backgroundColor: Color(0xFF00BFFF),
        title: Text("CRIC MANIA",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _tabs[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        selectedItemColor: Color(0xFF00BFFF),
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.sports_cricket), label: "Live Score"),
          BottomNavigationBarItem(icon: Icon(Icons.newspaper), label: "News"),
          BottomNavigationBarItem(
              icon: Icon(Icons.workspace_premium), label: "Premium"),
        ],
      ),
    );
  }
}

class LiveScoreTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('matches')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty)
            return ListView(children: [
              SizedBox(height: 100),
              Center(child: Text("No Matches Yet"))
            ]);

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
                      builder: (_) => MatchDetailScreen(matchId: doc.id)),
                ),
                child: Card(
                  margin: EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((m['tournament'] ?? "").toString().isNotEmpty)
                          Text(m['tournament'],
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500)),
                        SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text("${m['team1']} vs ${m['team2']}",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 16),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                  color: isResult ? Colors.grey[600] : Colors.red,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Text(status,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                        SizedBox(height: 8),
                        Text("${m['team1']}: ${m['score1']}",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("${m['team2']}: ${m['score2']}",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 5),
                        Text(m['result'] ?? "",
                            style: TextStyle(color: Colors.blue))
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════
//   MATCH DETAIL SCREEN — Only Scorecard
// ═══════════════════════════════════════════

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
            appBar: AppBar(title: Text("Cric Mania")),
            body: Center(child: CircularProgressIndicator()),
          );

        var m = (snap.data!.data() as Map<String, dynamic>?) ?? {};

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Color(0xFF0A1931),
            title: Text("Scorecard",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            iconTheme: IconThemeData(color: Colors.white),
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
      margin: EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(title,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF0A1931))),
        children: [
          _battingHeader(),
          if (batting.isEmpty)
            Padding(
                padding: EdgeInsets.all(12),
                child: Text("No batting data",
                    style: TextStyle(color: Colors.grey))),
          ...batting.map((b) => _batterRow(b)).toList(),
          _bowlerHeader(),
          if (bowling.isEmpty)
            Padding(
                padding: EdgeInsets.all(12),
                child: Text("No bowling data",
                    style: TextStyle(color: Colors.grey))),
          ...bowling.map((b) => _bowlerRow(b)).toList(),
        ],
      ),
    );
  }

  Widget _battingHeader() => Container(
        color: Colors.grey.shade100,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
                flex: 4,
                child: Text("Batter",
                    style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 11))),
            Expanded(
                flex: 4,
                child: Text("How Out",
                    style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 11))),
            Expanded(
                child: Text("R",
                    style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 11))),
            Expanded(
                child: Text("B",
                    style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 11))),
            Expanded(
                child: Text("4s",
                    style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 11))),
            Expanded(
                child: Text("6s",
                    style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 11))),
            Expanded(
                child: Text("SR",
                    style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 11))),
          ],
        ),
      );

  Widget _batterRow(dynamic b) {
    Map data = b is Map ? b : {};
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
              flex: 4,
              child: Text("${data['name'] ?? ''}",
                  style: TextStyle(
                      color: Color(0xFF0077B6), fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis)),
          Expanded(
              flex: 4,
              child: Text("${data['howOut'] ?? ''}",
                  style: TextStyle(color: Colors.grey[700], fontSize: 11),
                  overflow: TextOverflow.ellipsis)),
          Expanded(child: Text("${data['r'] ?? 0}")),
          Expanded(child: Text("${data['b'] ?? 0}")),
          Expanded(child: Text("${data['4s'] ?? 0}")),
          Expanded(child: Text("${data['6s'] ?? 0}")),
          Expanded(child: Text("${data['sr'] ?? 0}")),
        ],
      ),
    );
  }

  Widget _bowlerHeader() => Container(
        color: Colors.grey.shade100,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: EdgeInsets.only(top: 10),
        child: Row(
          children: [
            Expanded(
                flex: 3,
                child: Text("Bowler",
                    style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 11))),
            Expanded(
                child: Text("O",
                    style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 11))),
            Expanded(
                child: Text("M",
                    style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 11))),
            Expanded(
                child: Text("R",
                    style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 11))),
            Expanded(
                child: Text("W",
                    style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 11))),
          ],
        ),
      );

  Widget _bowlerRow(dynamic b) {
    Map data = b is Map ? b : {};
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text("${data['name'] ?? ''}",
                  style: TextStyle(color: Color(0xFF0077B6)),
                  overflow: TextOverflow.ellipsis)),
          Expanded(child: Text("${data['o'] ?? 0}")),
          Expanded(child: Text("${data['m'] ?? 0}")),
          Expanded(child: Text("${data['r'] ?? 0}")),
          Expanded(child: Text("${data['w'] ?? 0}")),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
//   NEWS TAB
// ═══════════════════════════════════════════

class NewsTab extends StatelessWidget {
  Widget _buildNewsImage(Map<String, dynamic> news) {
    try {
      if (news['imageBase64'] != null &&
          (news['imageBase64'] as String).isNotEmpty) {
        return Image.memory(base64Decode(news['imageBase64']),
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => Container(
                height: 150,
                color: Colors.grey[300],
                child: Icon(Icons.broken_image)));
      }
      if (news['imageUrl'] != null && (news['imageUrl'] as String).isNotEmpty) {
        return Image.network(news['imageUrl'],
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => Container(
                height: 150,
                color: Colors.grey[300],
                child: Icon(Icons.broken_image)));
      }
    } catch (e) {}
    return SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
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
            return ListView(children: [
              SizedBox(height: 100),
              Center(child: Text("No News Yet"))
            ]);

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
                          builder: (_) => NewsDetailScreen(newsData: news)));
                },
                child: Card(
                    margin: EdgeInsets.only(bottom: 10),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildNewsImage(news),
                          Padding(
                              padding: EdgeInsets.all(10),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(news['title'] ?? "",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16)),
                                    SizedBox(height: 5),
                                    Text(news['desc'] ?? "",
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                    SizedBox(height: 5),
                                    Text("Tap to read more...",
                                        style: TextStyle(
                                            color: Color(0xFF00BFFF),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold))
                                  ]))
                        ])),
              );
            },
          );
        },
      ),
    );
  }
}

class NewsDetailScreen extends StatelessWidget {
  final Map<String, dynamic> newsData;
  NewsDetailScreen({required this.newsData});

  Widget _buildDetailImage() {
    try {
      if (newsData['imageBase64'] != null &&
          (newsData['imageBase64'] as String).isNotEmpty) {
        return Image.memory(base64Decode(newsData['imageBase64']),
            width: double.infinity, fit: BoxFit.cover);
      }
      if (newsData['imageUrl'] != null &&
          (newsData['imageUrl'] as String).isNotEmpty) {
        return Image.network(newsData['imageUrl'],
            width: double.infinity, fit: BoxFit.cover);
      }
    } catch (e) {}
    return SizedBox();
  }

  void _shareNews() {
    String title = newsData['title'] ?? '';
    String desc = newsData['desc'] ?? '';
    String shareText = '$title\n\n$desc\n\nShared from Cric Mania app';

    Share.share(
      shareText,
      subject: title,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Color(0xFF00BFFF),
          title: Text("News Detail",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          iconTheme: IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: Icon(Icons.share, color: Colors.white),
              onPressed: _shareNews,
              tooltip: 'Share',
            ),
          ]),
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
                  Text(newsData['title'] ?? "",
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  Divider(),
                  SizedBox(height: 12),
                  Text(newsData['desc'] ?? "",
                      style: TextStyle(fontSize: 16, height: 1.6)),
                  SizedBox(height: 20),
                  if ((newsData['fullDesc'] ?? "").toString().isNotEmpty)
                    Text(newsData['fullDesc'],
                        style: TextStyle(fontSize: 16, height: 1.6)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
//   PREMIUM TAB
// ═══════════════════════════════════════════

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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("IBAN Copied! $easyIban"), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      body: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                width: double.infinity,
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                    color: Color(0xFF0A1931),
                    borderRadius: BorderRadius.circular(10)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("CRIC MANIA PREMIUM",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text("AD FREE",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      if (isPremiumActive && expiryDate != null)
                        Padding(
                            padding: EdgeInsets.only(top: 10),
                            child: Text(
                                "Premium Active Till: ${DateTime.fromMillisecondsSinceEpoch(expiryDate!).toString().substring(0, 10)}",
                                style: TextStyle(
                                    color: Colors.greenAccent,
                                    fontWeight: FontWeight.bold)))
                    ])),
            SizedBox(height: 20),
            Card(
                child: ListTile(
                    title: Text("Monthly - 30 RS"),
                    trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF00BFFF)),
                        onPressed: () => _payDialog("Monthly", 30),
                        child:
                            Text("Buy", style: TextStyle(color: Colors.white))))),
            Card(
                child: ListTile(
                    title: Text("Annual - 250 RS"),
                    trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF00BFFF)),
                        onPressed: () => _payDialog("Annual", 250),
                        child:
                            Text("Buy", style: TextStyle(color: Colors.white))))),
            SizedBox(height: 20),
            Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                    border: Border.all(color: Color(0xFF00BFFF)),
                    borderRadius: BorderRadius.circular(8)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Send Payment To:",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                            child: SelectableText(easyIban,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF00BFFF)))),
                        IconButton(
                            icon: Icon(Icons.copy, color: Color(0xFF00BFFF)),
                            onPressed: copyIban)
                      ]),
                      SizedBox(height: 4),
                      Text(easyName,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      Text("Easypaisa Account",
                          style:
                              TextStyle(fontSize: 13, color: Colors.grey[700])),
                      SizedBox(height: 10),
                      SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                              icon: Icon(Icons.copy,
                                  color: Colors.white, size: 18),
                              label: Text("Copy IBAN",
                                  style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF00BFFF)),
                              onPressed: copyIban))
                    ]))
          ])));

  _payDialog(String type, int amount) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
                title: Text("Pay $amount RS for $type"),
                content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Send $amount RS to:"),
                      SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                            child: SelectableText(easyIban,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00BFFF)))),
                        IconButton(
                            icon: Icon(Icons.copy),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: easyIban));
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("IBAN Copied!")));
                            })
                      ]),
                      SizedBox(height: 4),
                      Text(easyName, style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("Easypaisa Account",
                          style: TextStyle(fontSize: 12, color: Colors.grey))
                    ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Cancel")),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF00BFFF)),
                      onPressed: () {
                        Navigator.pop(context);
                        _showTxnInput(type, amount);
                      },
                      child: Text("I Have Paid",
                          style: TextStyle(color: Colors.white)))
                ]));
  }

  _showTxnInput(String type, int amount) {
    TextEditingController txnCtrl = TextEditingController();
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
                title: Text("Enter Transaction ID"),
                content: TextField(
                    controller: txnCtrl,
                    decoration: InputDecoration(
                        labelText: "TID", border: OutlineInputBorder())),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Cancel")),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF00BFFF)),
                      onPressed: () async {
                        if (txnCtrl.text.isEmpty) return;
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        await prefs.setString('pending_txn', txnCtrl.text);
                        await prefs.setString('pending_type', type);
                        await prefs.setInt('pending_amount', amount);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Request Sent!")));
                      },
                      child: Text("Submit",
                          style: TextStyle(color: Colors.white)))
                ]));
  }
}