import 'package:cloud_firestore/cloud_firestore.dart';

/// Team Squad — Per team selection
class TeamSquad {
  final String teamId;
  final String teamName;
  final String teamFlag;
  final String batterMain;
  final String batterBackup;
  final String bowlerMain;
  final String bowlerBackup;
  final String wildcard;
  final String wildcardRole; // 'batter' or 'bowler'
  final bool isComplete;

  TeamSquad({
    required this.teamId,
    required this.teamName,
    required this.teamFlag,
    this.batterMain = '',
    this.batterBackup = '',
    this.bowlerMain = '',
    this.bowlerBackup = '',
    this.wildcard = '',
    this.wildcardRole = '',
    this.isComplete = false,
  });

  bool get isTeamComplete {
    return batterMain.isNotEmpty &&
        batterBackup.isNotEmpty &&
        bowlerMain.isNotEmpty &&
        bowlerBackup.isNotEmpty &&
        wildcard.isNotEmpty &&
        wildcardRole.isNotEmpty;
  }

  factory TeamSquad.fromMap(Map<String, dynamic> map) {
    final squad = TeamSquad(
      teamId: map['teamId'] ?? '',
      teamName: map['teamName'] ?? '',
      teamFlag: map['teamFlag'] ?? '🏏',
      batterMain: map['batterMain'] ?? '',
      batterBackup: map['batterBackup'] ?? '',
      bowlerMain: map['bowlerMain'] ?? '',
      bowlerBackup: map['bowlerBackup'] ?? '',
      wildcard: map['wildcard'] ?? '',
      wildcardRole: map['wildcardRole'] ?? '',
    );
    return squad;
  }

  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'teamName': teamName,
      'teamFlag': teamFlag,
      'batterMain': batterMain,
      'batterBackup': batterBackup,
      'bowlerMain': bowlerMain,
      'bowlerBackup': bowlerBackup,
      'wildcard': wildcard,
      'wildcardRole': wildcardRole,
      'isComplete': isTeamComplete,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  TeamSquad copyWith({
    String? batterMain,
    String? batterBackup,
    String? bowlerMain,
    String? bowlerBackup,
    String? wildcard,
    String? wildcardRole,
  }) {
    return TeamSquad(
      teamId: teamId,
      teamName: teamName,
      teamFlag: teamFlag,
      batterMain: batterMain ?? this.batterMain,
      batterBackup: batterBackup ?? this.batterBackup,
      bowlerMain: bowlerMain ?? this.bowlerMain,
      bowlerBackup: bowlerBackup ?? this.bowlerBackup,
      wildcard: wildcard ?? this.wildcard,
      wildcardRole: wildcardRole ?? this.wildcardRole,
    );
  }
}

/// Squad Model — Full squad with all teams
class SquadModel {
  final String userId;
  final String userName;
  final String status; // 'draft' | 'submitted'
  final bool locked;
  final int completedTeams;
  final int totalTeams;
  final DateTime? lastSavedAt;
  final DateTime? submittedAt;

  SquadModel({
    required this.userId,
    required this.userName,
    this.status = 'draft',
    this.locked = false,
    this.completedTeams = 0,
    this.totalTeams = 0,
    this.lastSavedAt,
    this.submittedAt,
  });

  factory SquadModel.fromMap(String userId, Map<String, dynamic> map) {
    return SquadModel(
      userId: userId,
      userName: map['userName'] ?? '',
      status: map['status'] ?? 'draft',
      locked: map['locked'] ?? false,
      completedTeams: map['completedTeams'] ?? 0,
      totalTeams: map['totalTeams'] ?? 0,
      lastSavedAt: (map['lastSavedAt'] as Timestamp?)?.toDate(),
      submittedAt: (map['submittedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'status': status,
      'locked': locked,
      'completedTeams': completedTeams,
      'totalTeams': totalTeams,
      'lastSavedAt': Timestamp.fromDate(DateTime.now()),
      'submittedAt': submittedAt != null
          ? Timestamp.fromDate(submittedAt!)
          : null,
    };
  }

  bool get isAllTeamsComplete =>
      completedTeams >= totalTeams && totalTeams > 0;
}