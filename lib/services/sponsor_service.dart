import 'package:cloud_firestore/cloud_firestore.dart';

/// Sponsor Configuration Model (Base64 version)
class SponsorConfig {
  final String bannerBase64;
  final String slot1Base64;
  final String slot2Base64;
  final String slot3Base64;
  final String cornerLogoBase64;
  final String fpodSponsorLogoBase64;
  final String fpodSponsorName;
  final String fpodCardTitle;

  SponsorConfig({
    this.bannerBase64 = '',
    this.slot1Base64 = '',
    this.slot2Base64 = '',
    this.slot3Base64 = '',
    this.cornerLogoBase64 = '',
    this.fpodSponsorLogoBase64 = '',
    this.fpodSponsorName = '',
    this.fpodCardTitle = 'Player of the Day',
  });

  factory SponsorConfig.fromMap(Map<String, dynamic>? map) {
    if (map == null) return SponsorConfig();
    return SponsorConfig(
      bannerBase64: map['bannerBase64'] ?? '',
      slot1Base64: map['slot1Base64'] ?? '',
      slot2Base64: map['slot2Base64'] ?? '',
      slot3Base64: map['slot3Base64'] ?? '',
      cornerLogoBase64: map['cornerLogoBase64'] ?? '',
      fpodSponsorLogoBase64: map['fpodSponsorLogoBase64'] ?? '',
      fpodSponsorName: map['fpodSponsorName'] ?? '',
      fpodCardTitle: map['fpodCardTitle'] ?? 'Player of the Day',
    );
  }

  bool get hasBanner => bannerBase64.isNotEmpty;
  bool get hasSlot1 => slot1Base64.isNotEmpty;
  bool get hasSlot2 => slot2Base64.isNotEmpty;
  bool get hasSlot3 => slot3Base64.isNotEmpty;
  bool get hasCornerLogo => cornerLogoBase64.isNotEmpty;
  bool get hasAnySlot => hasSlot1 || hasSlot2 || hasSlot3;
}

/// Sponsor Service — sirf READ karne ke liye (user app)
/// Firestore path: tournaments/{tournamentId}/sponsors/config
class SponsorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _configDoc(String tournamentId) =>
      _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .collection('sponsors')
          .doc('config');

  /// Stream sponsor configuration
  Stream<SponsorConfig> streamConfig(String tournamentId) {
    return _configDoc(tournamentId).snapshots().map((doc) {
      return SponsorConfig.fromMap(doc.data());
    });
  }

  /// Get config once
  Future<SponsorConfig> getConfig(String tournamentId) async {
    final doc = await _configDoc(tournamentId).get();
    return SponsorConfig.fromMap(doc.data());
  }
}