import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

/// Prize / Rewards Screen — User App
/// Firestore path: tournaments/{tid}/prize_ad/config
class PrizeScreen extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;

  const PrizeScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });

  @override
  State<PrizeScreen> createState() => _PrizeScreenState();
}

class _PrizeScreenState extends State<PrizeScreen> {
  bool _downloading = false;

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

  Future<void> _downloadImage(String base64) async {
    setState(() => _downloading = true);
    try {
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
          _snack('Gallery permission required', isError: true);
          if (mounted) setState(() => _downloading = false);
          return;
        }
      }

      final bytes = _safeDecode(base64);
      if (bytes == null) {
        _snack('Image not available', isError: true);
        if (mounted) setState(() => _downloading = false);
        return;
      }

      final fileName = 'Prize_${DateTime.now().millisecondsSinceEpoch}';

      if (Platform.isAndroid || Platform.isIOS) {
        final result = await ImageGallerySaverPlus.saveImage(
          bytes,
          quality: 100,
          name: fileName,
        );
        if (result != null) {
          _snack('Image saved to gallery!');
        } else {
          _snack('Failed to save', isError: true);
        }
      }
    } catch (e) {
      _snack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _shareImage(String base64, String title) async {
    try {
      final bytes = _safeDecode(base64);
      if (bytes == null) {
        _snack('Image not available', isError: true);
        return;
      }

      final dir = await getTemporaryDirectory();
      final fileName = 'Prize_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '$title\n${widget.tournamentName}\n'
            '#CricMania #ProLeague',
      );
    } catch (e) {
      _snack('Error: $e', isError: true);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1B2F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A73E8),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tournament Prizes',
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
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tournaments')
            .doc(widget.tournamentId)
            .collection('prize_ad')
            .doc('config')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00C9A7)),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _emptyView();
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final isActive = data['isActive'] ?? false;

          if (isActive != true) {
            return _emptyView();
          }

          final title = data['title'] ?? 'Tournament Prizes';
          final description = data['description'] ?? '';
          final imageBase64 = data['imageBase64'] ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFEAEAEA),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 60,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C9A7),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                if (_safeDecode(imageBase64) != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(
                      _safeDecode(imageBase64)!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, _, _) => Container(
                        height: 200,
                        color: const Color(0xFF2D2D44),
                        child: const Center(
                          child: Icon(Icons.broken_image,
                              color: Colors.grey, size: 50),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),

                if (description.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D44),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF3D3D5C)),
                    ),
                    child: Text(
                      description,
                      style: const TextStyle(
                        color: Color(0xFFEAEAEA),
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                if (_safeDecode(imageBase64) != null)
                  Row(
                    children: [
                      Expanded(
                        child: _actionButton(
                          icon: Icons.download,
                          label: _downloading
                              ? 'Downloading...'
                              : 'Download Image',
                          color: const Color(0xFF00C9A7),
                          onTap: _downloading
                              ? null
                              : () => _downloadImage(imageBase64),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _actionButton(
                          icon: Icons.share,
                          label: 'Share',
                          color: const Color(0xFF1A73E8),
                          onTap: () => _shareImage(imageBase64, title),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 24),

                _disclaimerCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _emptyView() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_giftcard, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Prizes Not Announced Yet',
              style: TextStyle(
                color: Color(0xFFEAEAEA),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Prize details will appear here soon.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
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
          child: Padding(
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

  Widget _disclaimerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFD4AF37), size: 22),
              SizedBox(width: 8),
              Text(
                'Important Notice',
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Cric Mania Pro League is 100% skill-based.\n\n'
            'We do NOT accept any fees, cash, or payments in any form.\n\n'
            'If anyone asks you for money in the name of Cric Mania, '
            'refuse immediately and contact us at:',
            style: TextStyle(
              color: Color(0xFFEAEAEA),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF00C9A7).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.email,
                    color: Color(0xFF00C9A7), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'cricket.mania78362@gmail.com',
                    style: TextStyle(
                      color: Color(0xFF00C9A7),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}