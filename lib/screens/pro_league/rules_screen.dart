import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppColors {
  static const Color primary = Color(0xFF1A73E8);
  static const Color darkBg = Color(0xFF1B1B2F);
  static const Color cardBg = Color(0xFF2D2D44);
  static const Color accent = Color(0xFF00C9A7);
  static const Color textLight = Color(0xFFEAEAEA);
  static const Color textGrey = Color(0xFF9E9E9E);
  static const Color divider = Color(0xFF3D3D5C);
}

class RulesScreen extends StatefulWidget {
  @override
  _RulesScreenState createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen> {
  bool _loading = true;
  String _title = '';
  List<Map<String, String>> _sections = [];

  // ─── FALLBACK RULES (agar Firestore mein nahi mile) ───
  final String _fallbackTitle = "Terms & Conditions - Cric Mania";
  final List<Map<String, String>> _fallbackSections = [
    {
      "heading": "Effective Date",
      "content": "October 7, 2026\n\nContact: cricket.mania78362@gmail.com",
    },
    {
      "heading": "1. About The App",
      "content":
          "Cric Mania provides:\n"
          "a) Cricket Score Updates\n"
          "b) Cricket News\n"
          "c) Cric Mania Pro League",
    },
    {
      "heading": "2. Pakistan Gambling Laws - We Are 100% Compliant",
      "content":
          "We respect all laws of Pakistan. Our app is NOT gambling.\n\n"
          "Law 1: The Prevention of Gambling Act, 1977\n"
          "This law stops gambling where people stake money on luck. Cric Mania does NOT take any money, does NOT allow betting, and winning is NOT based on luck. So this law does not apply to us.\n\n"
          "Law 2: Pakistan Penal Code 294-A (Lottery Law)\n"
          "This law stops lotteries based on lucky draw. Our Pro League is NOT a lottery. Winners are decided by skill points and knowledge, not by lucky draw. So this law does not apply to us.\n\n"
          "Law 3: Constitution of Pakistan Article 37(g)\n"
          "This article says the State will discourage gambling. We support this. That is why we have no gambling in our app.\n\n"
          "Law 4: Provincial Gambling Laws\n"
          "All provinces (Sindh, Punjab, Balochistan, KPK) have similar laws to stop gambling. Since we have no gambling, all these laws do not apply to us.",
    },
    {
      "heading": "3. Why Our Pro League Is Legal?",
      "content":
          "Under Pakistan and Indian Supreme Court rule: Game of Skill is NOT Gambling.\n\n"
          "Game of Chance = Win by luck (Ludo, Roulette, Lucky Draw) - This is gambling.\n\n"
          "Game of Skill = Win by knowledge (Chess, Cricket Knowledge Games, Our Pro League) - This is NOT gambling.\n\n"
          "In Cric Mania Pro League, you win by using your cricket knowledge like player form, pitch report, and team analysis. It is a Game of Skill. So it is legal.",
    },
    {
      "heading": "4. Google Play Policy",
      "content":
          "We follow Google Play Rules:\n\n"
          "• No real money gambling\n"
          "• No entry fee\n"
          "• Free to play - No purchase needed to win",
    },
    {
      "heading": "5. Prize Policy",
      "content":
          "We give Physical Gifts from Cric Mania as appreciation for your good cricket knowledge.\n\n"
          "• No Cash Prize.\n"
          "• No Easypaisa, JazzCash, Bank Transfer, or Crypto.\n"
          "• Gifts cannot be exchanged for cash.\n"
          "• Winners will be announced in the app and gifts will be delivered in 15-25 days.",
    },
    {
      "heading": "6. Rules",
      "content":
          "• Age must be 18 or above.\n"
          "• One person can have only one account.\n"
          "• Cheating or using bots will result in a ban.\n"
          "• We are not affiliated with ICC, PCB, IPL, or PSL.",
    },
    {
      "heading": "7. Law",
      "content": "These terms follow the laws of Pakistan.",
    },
    {
      "heading": "Agreement",
      "content":
          "By using this app, you agree that Cric Mania is a Free, Skill-Based, No-Cash, Non-Gambling App made according to Pakistan Gambling Laws.",
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  Future<void> _loadRules() async {
    try {
      // Firestore se settings/rules document load karo
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('rules')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['sections'] != null && data['sections'] is List) {
          final List<dynamic> firestoreSections = data['sections'];
          setState(() {
            _title = data['title'] ?? _fallbackTitle;
            _sections = firestoreSections
                .map((s) => {
                      "heading": (s['heading'] ?? '').toString(),
                      "content": (s['content'] ?? '').toString(),
                    })
                .toList();
            _loading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("Rules load error: $e");
    }

    // Fallback: hardcoded rules
    setState(() {
      _title = _fallbackTitle;
      _sections = _fallbackSections;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          "Rules & Terms",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── HEADER ───
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, Color(0xFF0D47A1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.gavel,
                                color: Colors.amber, size: 28),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _title,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Please read carefully before participating in Pro League.",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // ─── SECTIONS ───
                  ..._sections.asMap().entries.map((entry) {
                    int index = entry.key;
                    Map<String, String> section = entry.value;
                    return _sectionCard(
                      index: index + 1,
                      heading: section['heading'] ?? '',
                      content: section['content'] ?? '',
                    );
                  }).toList(),

                  SizedBox(height: 20),

                  // ─── FOOTER ───
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.accent,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.verified_user,
                            color: AppColors.accent, size: 22),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Cric Mania is a free, skill-based, no-cash, non-gambling app.",
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
                  SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _sectionCard({
    required int index,
    required String heading,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}