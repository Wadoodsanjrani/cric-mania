import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../widgets/winner_card_widget.dart';

class WinnerScreen extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;

  const WinnerScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });

  @override
  State<WinnerScreen> createState() => _WinnerScreenState();
}

class _WinnerScreenState extends State<WinnerScreen> {
  final Map<int, GlobalKey> _cardKeys = {};
  int? _downloadingRank;

  GlobalKey _getKey(int rank) {
    return _cardKeys.putIfAbsent(rank, () => GlobalKey());
  }

  // ✅ RepaintBoundary se image nikalo — zyada reliable
  Future<Uint8List?> _captureCard(int rank) async {
    try {
      // Wait for render
      await Future.delayed(const Duration(milliseconds: 300));

      final key = _getKey(rank);
      final boundary = key.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;

      if (boundary == null) {
        debugPrint('Boundary null for rank $rank');
        return null;
      }

      // Wait for next frame
      await Future.delayed(const Duration(milliseconds: 100));

      final image = await boundary.toImage(pixelRatio: 2.5);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        debugPrint('ByteData null for rank $rank');
        return null;
      }

      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Capture error for rank $rank: $e');
      return null;
    }
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
              "Winners",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              widget.tournamentName,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tournaments')
            .doc(widget.tournamentId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00C9A7)),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _notDeclared();
          }

          final tourney = snapshot.data!.data() as Map<String, dynamic>;
          final winnerUserId = tourney['winnerUserId'] ?? '';
          final runnerUpUserId = tourney['runnerUpUserId'] ?? '';
          final thirdPlaceUserId = tourney['thirdPlaceUserId'] ?? '';
          final status = tourney['status'] ?? 'active';

          if (winnerUserId.isEmpty || status != 'completed') {
            return _notDeclared();
          }

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _loadWinners(
              winnerUserId,
              runnerUpUserId,
              thirdPlaceUserId,
            ),
            builder: (context, winnersSnap) {
              if (winnersSnap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00C9A7)),
                );
              }

              final winners = winnersSnap.data ?? [];
              if (winners.isEmpty) {
                return _notDeclared();
              }

              return _winnersView(winners);
            },
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadWinners(
    String firstId,
    String secondId,
    String thirdId,
  ) async {
    final List<Map<String, dynamic>> winners = [];

    Future<void> addWinner(String userId, int rank) async {
      if (userId.isEmpty) return;
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        if (!userDoc.exists) return;
        final user = userDoc.data()!;

        final lbDoc = await FirebaseFirestore.instance
            .collection('tournaments')
            .doc(widget.tournamentId)
            .collection('leaderboard')
            .doc(userId)
            .get();

        final points =
            lbDoc.exists ? (lbDoc.data()!['totalPoints'] ?? 0) : 0;

        winners.add({
          'rank': rank,
          'name': user['name'] ?? 'Player',
          'city': user['city'] ?? '',
          'photoBase64': user['profilePhotoBase64'] ?? '',
          'points': points,
        });
      } catch (e) {
        // skip
      }
    }

    await addWinner(firstId, 1);
    await addWinner(secondId, 2);
    await addWinner(thirdId, 3);

    return winners;
  }

  Widget _winnersView(List<Map<String, dynamic>> winners) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tournaments')
          .doc(widget.tournamentId)
          .collection('sponsors')
          .doc('config')
          .snapshots(),
      builder: (context, sponsorSnap) {
        String sponsorName = '';
        String sponsorLogoBase64 = '';

        if (sponsorSnap.hasData && sponsorSnap.data!.exists) {
          final data = sponsorSnap.data!.data() as Map<String, dynamic>;
          sponsorName = data['fpodSponsorName'] ?? '';
          sponsorLogoBase64 = data['fpodSponsorLogoBase64'] ?? '';
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD4AF37), Color(0xFFFFD700)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.emoji_events,
                        color: Colors.black, size: 40),
                    const SizedBox(height: 6),
                    const Text(
                      "CONGRATULATIONS",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.tournamentName,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              ...winners.map((winner) {
                final rank = winner['rank'] as int;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: [
                      RepaintBoundary(
                        key: _getKey(rank),
                        child: WinnerCardWidget(
                          userName: winner['name'],
                          userCity: winner['city'],
                          photoBase64: winner['photoBase64'],
                          points: winner['points'],
                          rank: rank,
                          tournamentName: widget.tournamentName,
                          sponsorName: sponsorName,
                          sponsorLogoBase64: sponsorLogoBase64,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _actionButton(
                            icon: Icons.download,
                            label: _downloadingRank == rank
                                ? "Downloading..."
                                : "Download",
                            color: const Color(0xFF00C9A7),
                            onTap: _downloadingRank == rank
                                ? null
                                : () => _downloadCard(rank, winner),
                          ),
                          const SizedBox(width: 10),
                          _actionButton(
                            icon: Icons.share,
                            label: "Share",
                            color: const Color(0xFF1A73E8),
                            onTap: () => _shareWinner(rank, winner),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D44),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF3D3D5C)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.card_giftcard,
                        color: Color(0xFFD4AF37), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Prizes will be delivered within 15-25 days.",
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
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

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _downloadCard(int rank, Map<String, dynamic> winner) async {
    setState(() => _downloadingRank = rank);

    try {
      // Permissions
      if (Platform.isAndroid) {
        PermissionStatus status;
        if (await Permission.photos.isGranted ||
            await Permission.storage.isGranted) {
          status = PermissionStatus.granted;
        } else {
          final photos = await Permission.photos.request();
          if (photos.isGranted) {
            status = photos;
          } else {
            status = await Permission.storage.request();
          }
        }

        if (!status.isGranted) {
          _snack("Gallery permission required", isError: true);
          if (mounted) setState(() => _downloadingRank = null);
          return;
        }
      }

      // Capture image
      final bytes = await _captureCard(rank);

      if (bytes == null) {
        _snack("Failed to capture card", isError: true);
        if (mounted) setState(() => _downloadingRank = null);
        return;
      }

      final cleanName = (winner['name'] as String)
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .replaceAll(' ', '_');
      final fileName = "Winner_${rank}_$cleanName";

      if (Platform.isAndroid || Platform.isIOS) {
        final result = await ImageGallerySaverPlus.saveImage(
          bytes,
          quality: 100,
          name: fileName,
        );
        if (result != null) {
          _snack("Card saved to gallery!");
        } else {
          _snack("Failed to save", isError: true);
        }
      }
    } catch (e) {
      _snack("Error: $e", isError: true);
    } finally {
      if (mounted) setState(() => _downloadingRank = null);
    }
  }

  Future<void> _shareWinner(int rank, Map<String, dynamic> winner) async {
    try {
      final bytes = await _captureCard(rank);

      if (bytes == null) {
        _snack("Failed to capture", isError: true);
        return;
      }

      final dir = await getTemporaryDirectory();
      final cleanName = (winner['name'] as String)
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .replaceAll(' ', '_');
      final fileName = "Winner_${rank}_$cleanName.png";
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: "${winner['name']} is ${_rankText(rank)} "
            "in ${widget.tournamentName}! 🏆\n"
            "${winner['points']} points\n"
            "#CricMania #ProLeague",
      );
    } catch (e) {
      _snack("Error: $e", isError: true);
    }
  }

  String _rankText(int rank) {
    if (rank == 1) return "the CHAMPION";
    if (rank == 2) return "the RUNNER-UP";
    if (rank == 3) return "the SECOND RUNNER-UP";
    return "a winner";
  }

  Widget _notDeclared() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty, color: Colors.grey[600], size: 80),
            const SizedBox(height: 16),
            const Text(
              "Winners Not Declared Yet",
              style: TextStyle(
                color: Color(0xFFEAEAEA),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Winners will be announced after the tournament ends.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
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