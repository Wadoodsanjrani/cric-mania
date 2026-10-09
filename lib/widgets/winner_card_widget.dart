import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class WinnerCardWidget extends StatelessWidget {
  final String userName;
  final String userCity;
  final String photoBase64;
  final int points;
  final int rank;
  final String tournamentName;
  final String sponsorName;
  final String sponsorLogoBase64;

  const WinnerCardWidget({
    super.key,
    required this.userName,
    required this.userCity,
    required this.photoBase64,
    required this.points,
    required this.rank,
    required this.tournamentName,
    this.sponsorName = '',
    this.sponsorLogoBase64 = '',
  });

  // ✅ SAFE base64 decode — prefix aur invalid dono handle
  Uint8List? _safeDecode(String b64) {
    if (b64.isEmpty) return null;
    try {
      String clean = b64;
      if (clean.contains(',')) clean = clean.split(',').last;
      clean = clean.replaceAll(RegExp(r'\s+'), '');
      return base64Decode(clean);
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> get _rankConfig {
    switch (rank) {
      case 1:
        return {
          'title': 'CHAMPION',
          'medal': '🥇',
          'rankText': '1st Place',
          'gradient': [Color(0xFFD4AF37), Color(0xFFFFD700), Color(0xFFD4AF37)],
          'accent': Color(0xFFFFD700),
          'icon': Icons.emoji_events,
        };
      case 2:
        return {
          'title': 'RUNNER-UP',
          'medal': '🥈',
          'rankText': '2nd Place',
          'gradient': [Color(0xFFC0C0C0), Color(0xFFE8E8E8), Color(0xFFC0C0C0)],
          'accent': Color(0xFFC0C0C0),
          'icon': Icons.workspace_premium,
        };
      case 3:
        return {
          'title': 'SECOND RUNNER-UP',
          'medal': '🥉',
          'rankText': '3rd Place',
          'gradient': [Color(0xFFCD7F32), Color(0xFFE5A876), Color(0xFFCD7F32)],
          'accent': Color(0xFFCD7F32),
          'icon': Icons.emoji_events_outlined,
        };
      default:
        return {
          'title': 'WINNER',
          'medal': '🏆',
          'rankText': 'Winner',
          'gradient': [Color(0xFF1A73E8), Color(0xFF00C9A7)],
          'accent': Color(0xFF00C9A7),
          'icon': Icons.emoji_events,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _rankConfig;
    final accent = config['accent'] as Color;
    final photoBytes = _safeDecode(photoBase64);
    final sponsorBytes = _safeDecode(sponsorLogoBase64);

    return Container(
      width: 340,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0D1B3E),
            Color(0xFF1A1F3A),
            Color(0xFF0A0E27),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent, width: 3),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.5),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: config['gradient'] as List<Color>),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  config['medal'],
                  style: const TextStyle(fontSize: 26),
                ),
                const SizedBox(height: 2),
                Text(
                  config['title'],
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accent, width: 3.5),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.6),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: photoBytes != null
                  ? Image.memory(
                      photoBytes,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => _defaultAvatar(accent),
                    )
                  : _defaultAvatar(accent),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            userName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),

          if (userCity.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, color: accent, size: 14),
                const SizedBox(width: 4),
                Text(
                  userCity,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: config['gradient'] as List<Color>),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  "TOTAL POINTS",
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.black, size: 22),
                    const SizedBox(width: 6),
                    Text(
                      "$points",
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Text(
            tournamentName,
            style: TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          if (sponsorName.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (sponsorBytes != null)
                    Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.memory(
                          sponsorBytes,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => const SizedBox(),
                        ),
                      ),
                    ),
                  Flexible(
                    child: Text(
                      "Sponsored by $sponsorName",
                      style: TextStyle(
                        color: accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          Text(
            "CRIC MANIA PRO LEAGUE",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 9,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultAvatar(Color accent) {
    return Container(
      color: const Color(0xFF2D2D44),
      child: Icon(Icons.person, color: accent, size: 55),
    );
  }
}