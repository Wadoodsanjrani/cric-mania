import 'dart:convert';
import 'package:flutter/material.dart';

class PlpCardWidget extends StatelessWidget {
  final String userName;
  final String userCity;
  final String photoBase64;
  final int points;
  final int rank;
  final String date;
  final String sponsorName;
  final String sponsorLogoBase64;

  const PlpCardWidget({
    super.key,
    required this.userName,
    required this.userCity,
    required this.photoBase64,
    required this.points,
    required this.rank,
    required this.date,
    this.sponsorName = '',
    this.sponsorLogoBase64 = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0D1B3E), // Deep blue
            Color(0xFF1A1F3A), // Dark
            Color(0xFF0A0E27), // Darkest
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFD4AF37),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── TOP BANNER ───
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD4AF37), Color(0xFFFFD700)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.emoji_events, color: Colors.black, size: 20),
                SizedBox(width: 6),
                Text(
                  "PLP OF THE DAY",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.emoji_events, color: Colors.black, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ─── USER PHOTO ───
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD4AF37), width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipOval(
              child: photoBase64.isNotEmpty
                  ? Image.memory(
                      base64Decode(photoBase64),
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => _defaultAvatar(),
                    )
                  : _defaultAvatar(),
            ),
          ),
          const SizedBox(height: 14),

          // ─── RANK BADGE ───
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD4AF37), Color(0xFFFFD700)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "#$rank",
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ─── NAME ───
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

          // ─── CITY ───
          if (userCity.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on,
                    color: Color(0xFFD4AF37), size: 14),
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
          const SizedBox(height: 18),

          // ─── POINTS BOX ───
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFD4AF37),
                  Color(0xFFFFD700),
                  Color(0xFFD4AF37),
                ],
              ),
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
          const SizedBox(height: 14),

          // ─── DATE ───
          Text(
            date,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),

          // ─── SPONSOR ───
          if (sponsorName.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (sponsorLogoBase64.isNotEmpty)
                    Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.memory(
                          base64Decode(sponsorLogoBase64),
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => const SizedBox(),
                        ),
                      ),
                    ),
                  Flexible(
                    child: Text(
                      "Powered by $sponsorName",
                      style: const TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
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

          // ─── FOOTER ───
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

  Widget _defaultAvatar() {
    return Container(
      color: const Color(0xFF2D2D44),
      child: const Icon(
        Icons.person,
        color: Color(0xFFD4AF37),
        size: 55,
      ),
    );
  }
}