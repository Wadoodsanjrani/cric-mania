import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/squad_model.dart';

/// Squad Service — Firestore operations
/// Path: tournaments/{tournamentId}/squads/{userId}
class SquadService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── Squad document reference ───
  DocumentReference<Map<String, dynamic>> _squadDoc(
    String tournamentId,
    String userId,
  ) =>
      _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .collection('squads')
          .doc(userId);

  // ─── Team squad document reference ───
  DocumentReference<Map<String, dynamic>> _teamSquadDoc(
    String tournamentId,
    String userId,
    String teamId,
  ) =>
      _squadDoc(tournamentId, userId).collection('teams').doc(teamId);

  // ─── Stream squad ───
  Stream<SquadModel?> streamSquad(String tournamentId, String userId) {
    return _squadDoc(tournamentId, userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return SquadModel.fromMap(userId, doc.data()!);
    });
  }

  // ─── Get squad ───
  Future<SquadModel?> getSquad(String tournamentId, String userId) async {
    final doc = await _squadDoc(tournamentId, userId).get();
    if (!doc.exists) return null;
    return SquadModel.fromMap(userId, doc.data()!);
  }

  // ─── Stream all team squads ───
  Stream<List<TeamSquad>> streamTeamSquads(
    String tournamentId,
    String userId,
  ) {
    return _squadDoc(tournamentId, userId)
        .collection('teams')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TeamSquad.fromMap(doc.data()))
            .toList());
  }

  // ─── Get single team squad ───
  Future<TeamSquad?> getTeamSquad(
    String tournamentId,
    String userId,
    String teamId,
  ) async {
    final doc = await _teamSquadDoc(tournamentId, userId, teamId).get();
    if (!doc.exists) return null;
    return TeamSquad.fromMap(doc.data()!);
  }

  // ─── Save team squad (draft) ───
  Future<void> saveTeamSquad({
    required String tournamentId,
    required String userId,
    required String userName,
    required TeamSquad teamSquad,
    required int totalTeams,
  }) async {
    // Save team squad
    await _teamSquadDoc(tournamentId, userId, teamSquad.teamId)
        .set(teamSquad.toMap(), SetOptions(merge: true));

    // Recalculate completed teams
    final teamsSnap = await _squadDoc(tournamentId, userId)
        .collection('teams')
        .get();

    int completed = 0;
    for (final doc in teamsSnap.docs) {
      final team = TeamSquad.fromMap(doc.data());
      if (team.isTeamComplete) completed++;
    }

    // Update squad parent document
    await _squadDoc(tournamentId, userId).set(
      {
        'userId': userId,
        'userName': userName,
        'status': 'draft',
        'locked': false,
        'completedTeams': completed,
        'totalTeams': totalTeams,
        'lastSavedAt': Timestamp.fromDate(DateTime.now()),
      },
      SetOptions(merge: true),
    );
  }

  // ─── Submit squad (final lock) ───
  Future<void> submitSquad({
    required String tournamentId,
    required String userId,
    required String userName,
    required int totalTeams,
  }) async {
    // Verify all teams complete
    final teamsSnap = await _squadDoc(tournamentId, userId)
        .collection('teams')
        .get();

    int completed = 0;
    for (final doc in teamsSnap.docs) {
      final team = TeamSquad.fromMap(doc.data());
      if (team.isTeamComplete) completed++;
    }

    if (completed < totalTeams) {
      throw Exception(
        'Complete all teams first ($completed/$totalTeams done)',
      );
    }

    // Submit — LOCK
    await _squadDoc(tournamentId, userId).set(
      {
        'userId': userId,
        'userName': userName,
        'status': 'submitted',
        'locked': true,
        'completedTeams': completed,
        'totalTeams': totalTeams,
        'submittedAt': Timestamp.fromDate(DateTime.now()),
        'lastSavedAt': Timestamp.fromDate(DateTime.now()),
      },
      SetOptions(merge: true),
    );
  }
}