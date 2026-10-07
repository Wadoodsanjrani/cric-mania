import 'package:flutter/material.dart';

class TeamSquadScreen extends StatelessWidget {
  final String tournamentId;
  final String teamId;
  final String teamName;
  final String teamFlag;

  const TeamSquadScreen({
    super.key,
    required this.tournamentId,
    required this.teamId,
    required this.teamName,
    required this.teamFlag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1931),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1931),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          teamName,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: const Center(
        child: Text(
          'Team Squad — Coming Soon',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}