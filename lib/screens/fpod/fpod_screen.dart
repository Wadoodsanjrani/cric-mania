import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import '../../widgets/plp_card_widget.dart';

class FpodScreen extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;

  const FpodScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });

  @override
  State<FpodScreen> createState() => _FpodScreenState();
}

class _FpodScreenState extends State<FpodScreen> {
  final _screenshotController = ScreenshotController();
  final _cardKey = GlobalKey();
  bool _downloading = false;

  String _todayKey() {
    final now = DateTime.now();
    final y = now.year.toString();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return "$y-$m-$d";
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
              "PLP of the Day",
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("Today's PLP"),
            const SizedBox(height: 12),
            _todayCard(),
            const SizedBox(height: 24),
            _sectionTitle("Previous PLPs"),
            const SizedBox(height: 10),
            _previousList(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TODAY'S CARD
  // ═══════════════════════════════════════════════════════════
  Widget _todayCard() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tournaments')
          .doc(widget.tournamentId)
          .collection('fpod')
          .doc(_todayKey())
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _loadingBox();
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _emptyCard();
        }

        final fpod = snapshot.data!.data() as Map<String, dynamic>;
        final userId = fpod['userId'] ?? '';
        final points = fpod['points'] ?? 0;
        final rank = fpod['rank'] ?? 1;
        final date = fpod['date'] ?? _todayKey();

        if (userId.isEmpty) {
          return _emptyCard();
        }

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get(),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return _loadingBox();
            }

            if (!userSnap.hasData || !userSnap.data!.exists) {
              return _emptyCard();
            }

            final user = userSnap.data!.data() as Map<String, dynamic>;
            final name = user['name'] ?? 'Player';
            final city = user['city'] ?? '';
            final photoBase64 = user['profilePhotoBase64'] ?? '';

            return _withSponsorAndButtons(
              name: name,
              city: city,
              photoBase64: photoBase64,
              points: points,
              rank: rank,
              date: date,
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WITH SPONSOR + DOWNLOAD + SHARE
  // ═══════════════════════════════════════════════════════════
  Widget _withSponsorAndButtons({
    required String name,
    required String city,
    required String photoBase64,
    required int points,
    required int rank,
    required String date,
  }) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tournaments')
          .doc(widget.tournamentId)
          .collection('sponsors')
          .doc('config')
          .snapshots(),
      builder: (context, snapshot) {
        String sponsorName = '';
        String sponsorLogoBase64 = '';

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          sponsorName = data['fpodSponsorName'] ?? '';
          sponsorLogoBase64 = data['fpodSponsorLogoBase64'] ?? '';
        }

        return Column(
          children: [
            Screenshot(
              controller: _screenshotController,
              child: RepaintBoundary(
                key: _cardKey,
                child: PlpCardWidget(
                  userName: name,
                  userCity: city,
                  photoBase64: photoBase64,
                  points: points,
                  rank: rank,
                  date: date,
                  sponsorName: sponsorName,
                  sponsorLogoBase64: sponsorLogoBase64,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    icon: Icons.download,
                    label: _downloading ? "Downloading..." : "Download PNG",
                    color: const Color(0xFF00C9A7),
                    onTap: _downloading
                        ? null
                        : () => _downloadCard(name, date),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _actionButton(
                    icon: Icons.share,
                    label: "Share",
                    color: const Color(0xFF1A73E8),
                    onTap: () => _shareCard(name, date),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // DOWNLOAD CARD AS PNG
  // ═══════════════════════════════════════════════════════════
  Future<void> _downloadCard(String name, String date) async {
    setState(() => _downloading = true);

    try {
      final image = await _screenshotController.capture(
        delay: const Duration(milliseconds: 100),
        pixelRatio: 3.0,
      );

      if (image == null) {
        throw Exception("Failed to capture card");
      }

      final cleanName =
          name.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_');
      final fileName = "PLP_${date}_$cleanName.png";

      if (Platform.isAndroid || Platform.isIOS) {
        final result = await ImageGallerySaverPlus.saveImage(
          image,
          quality: 100,
          name: fileName,
        );

        if (result != null) {
          _snack("Card saved to gallery!");
        } else {
          _snack("Failed to save", isError: true);
        }
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(image);
        _snack("Card saved temporarily");
      }
    } catch (e) {
      _snack("Error: $e", isError: true);
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // SHARE CARD
  // ═══════════════════════════════════════════════════════════
  Future<void> _shareCard(String name, String date) async {
    try {
      final image = await _screenshotController.capture(
        delay: const Duration(milliseconds: 100),
        pixelRatio: 3.0,
      );

      if (image == null) {
        throw Exception("Failed to capture");
      }

      final dir = await getTemporaryDirectory();
      final cleanName =
          name.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_');
      final fileName = "PLP_${date}_$cleanName.png";
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(image);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: "$name is the PLP of the Day! 🏆\n$date\n#CricMania #ProLeague",
      );
    } catch (e) {
      _snack("Error: $e", isError: true);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // PREVIOUS PLPs LIST
  // ═══════════════════════════════════════════════════════════
  Widget _previousList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tournaments')
          .doc(widget.tournamentId)
          .collection('fpod')
          .orderBy('date', descending: true)
          .limit(15)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: Color(0xFF00C9A7)),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _noPrevious();
        }

        final today = _todayKey();
        final previous =
            snapshot.data!.docs.where((doc) => doc.id != today).toList();

        if (previous.isEmpty) {
          return _noPrevious();
        }

        return Column(
          children: previous.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _previousRow(data);
          }).toList(),
        );
      },
    );
  }

  Widget _previousRow(Map<String, dynamic> data) {
    final userId = data['userId'] ?? '';
    final points = data['points'] ?? 0;
    final date = data['date'] ?? '';

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get(),
      builder: (context, snap) {
        String name = 'Player';
        String city = '';
        String photoBase64 = '';

        if (snap.hasData && snap.data!.exists) {
          final user = snap.data!.data() as Map<String, dynamic>;
          name = user['name'] ?? 'Player';
          city = user['city'] ?? '';
          photoBase64 = user['profilePhotoBase64'] ?? '';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D44),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF3D3D5C)),
          ),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFD4AF37),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: photoBase64.isNotEmpty
                      ? Image.memory(
                          base64Decode(photoBase64),
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => _smallAvatar(),
                        )
                      : _smallAvatar(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Color(0xFFEAEAEA),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (city.isNotEmpty) ...[
                          const Icon(Icons.location_on,
                              color: Color(0xFF9E9E9E), size: 11),
                          const SizedBox(width: 3),
                          Text(
                            city,
                            style: const TextStyle(
                              color: Color(0xFF9E9E9E),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          date,
                          style: const TextStyle(
                            color: Color(0xFF9E9E9E),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star,
                        color: Color(0xFFD4AF37), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      "$points",
                      style: const TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════
  Widget _smallAvatar() {
    return Container(
      color: const Color(0xFF1B1B2F),
      child: const Icon(Icons.person, color: Color(0xFFD4AF37), size: 22),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFF00C9A7),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFEAEAEA),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _loadingBox() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFF00C9A7)),
      ),
    );
  }

  Widget _emptyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3D3D5C)),
      ),
      child: Column(
        children: [
          Icon(Icons.hourglass_empty, color: Colors.grey[600], size: 50),
          const SizedBox(height: 12),
          const Text(
            "Not Announced Yet",
            style: TextStyle(
              color: Color(0xFFEAEAEA),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "PLP for today will be announced after matches.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _noPrevious() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3D3D5C)),
      ),
      child: Column(
        children: [
          Icon(Icons.history, color: Colors.grey[600], size: 40),
          const SizedBox(height: 10),
          Text(
            "No Previous PLPs",
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? Colors.red : const Color(0xFF00C9A7),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}