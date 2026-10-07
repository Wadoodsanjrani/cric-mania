import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/squad_model.dart';
import '../../services/squad_service.dart';
import 'team_squad_screen.dart';

/// Squad Teams Screen — Screen 1 (Teams list)
class SquadTeamsScreen extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;

  const SquadTeamsScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });

  @override
  State<SquadTeamsScreen> createState() => _SquadTeamsScreenState();
}

class _SquadTeamsScreenState extends State<SquadTeamsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _squadService = SquadService();
  bool _submitting = false;

  String get _userId => _auth.currentUser?.uid ?? '';
  String get _userName => _auth.currentUser?.displayName ?? 'Player';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1931),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1931),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Select Squad',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('tournaments')
            .doc(widget.tournamentId)
            .collection('teams')
            .snapshots(),
        builder: (context, teamsSnap) {
          if (teamsSnap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          final teams = teamsSnap.data?.docs ?? [];

          if (teams.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No teams added yet',
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
              ),
            );
          }

          return StreamBuilder<List<TeamSquad>>(
            stream: _squadService.streamTeamSquads(
              widget.tournamentId,
              _userId,
            ),
            builder: (context, squadsSnap) {
              final userSquads = squadsSnap.data ?? [];

              final squadMap = <String, TeamSquad>{};
              for (final sq in userSquads) {
                squadMap[sq.teamId] = sq;
              }

              int completed = 0;
              for (final t in teams) {
                final sq = squadMap[t.id];
                if (sq != null && sq.isTeamComplete) completed++;
              }

              final allComplete = completed >= teams.length;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _header(teams.length, completed),
                  const SizedBox(height: 16),
                  ...teams.map((doc) {
                    final data = doc.data();
                    final sq = squadMap[doc.id];
                    return _teamCard(
                      teamId: doc.id,
                      teamName: data['name'] ?? 'Team',
                      teamFlag: data['flag'] ?? '🏏',
                      isComplete: sq != null && sq.isTeamComplete,
                    );
                  }),
                  const SizedBox(height: 24),
                  _submitButton(allComplete),
                  const SizedBox(height: 24),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _header(int total, int completed) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A73E8),
            const Color(0xFF0D47A1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.tournamentName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Complete all teams to submit',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: total > 0 ? completed / total : 0,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(
                    Color(0xFF00C9A7),
                  ),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$completed/$total',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _teamCard({
    required String teamId,
    required String teamName,
    required String teamFlag,
    required bool isComplete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isComplete
              ? const Color(0xFF00C9A7).withValues(alpha: 0.5)
              : Colors.white24,
          width: isComplete ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              teamFlag.isEmpty ? '🏏' : teamFlag,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        title: Text(
          teamName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(
                isComplete ? Icons.check_circle : Icons.pending_outlined,
                color: isComplete
                    ? const Color(0xFF00C9A7)
                    : Colors.orange,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                isComplete ? 'Complete' : 'Pending',
                style: TextStyle(
                  color: isComplete
                      ? const Color(0xFF00C9A7)
                      : Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white54,
          size: 16,
        ),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TeamSquadScreen(
                tournamentId: widget.tournamentId,
                teamId: teamId,
                teamName: teamName,
                teamFlag: teamFlag,
              ),
            ),
          );
          if (mounted) setState(() {});
        },
      ),
    );
  }

  Widget _submitButton(bool enabled) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled
              ? const Color(0xFFD4AF37)
              : Colors.grey.shade700,
          foregroundColor: enabled ? Colors.black : Colors.white54,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: enabled && !_submitting ? _confirmSubmit : null,
        child: _submitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : Text(
                enabled ? 'SUBMIT SQUAD' : 'Complete all teams first',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
      ),
    );
  }

  Future<void> _confirmSubmit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        title: const Text(
          'Submit Squad?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Once submitted, you CANNOT edit your squad.\n\n'
          'Are you sure?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _submitting = true);

    try {
      final teamsSnap = await _firestore
          .collection('tournaments')
          .doc(widget.tournamentId)
          .collection('teams')
          .get();

      await _squadService.submitSquad(
        tournamentId: widget.tournamentId,
        userId: _userId,
        userName: _userName,
        totalTeams: teamsSnap.docs.length,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Squad submitted successfully! 🔒'),
          backgroundColor: Color(0xFF00C9A7),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}