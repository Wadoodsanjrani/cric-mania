import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardScreen extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;

  const LeaderboardScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final _searchController = TextEditingController();
  final _userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              "Leaderboard",
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tournaments')
            .doc(widget.tournamentId)
            .collection('leaderboard')
            .orderBy('totalPoints', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _errorView("Failed to load leaderboard");
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00C9A7)),
            );
          }

          final allEntries = snapshot.data!.docs;

          if (allEntries.isEmpty) {
            return _emptyView();
          }

          // Find current user's entry
          final hasMyEntry = allEntries.any((doc) => doc.id == _userId);
          DocumentSnapshot? myEntry;
          if (hasMyEntry) {
            myEntry = allEntries.firstWhere((doc) => doc.id == _userId);
          }

          // Filter entries
          var filtered = allEntries.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['userName'] ?? '').toString().toLowerCase();
            final city = (data['userCity'] ?? '').toString().toLowerCase();

            if (_searchQuery.isNotEmpty) {
              return name.contains(_searchQuery) ||
                  city.contains(_searchQuery);
            }
            return true;
          }).toList();

          return Column(
            children: [
              // ─── SEARCH BAR ───
              _searchBar(),

              // ─── MY RANK CARD ───
              if (hasMyEntry && myEntry != null && _searchQuery.isEmpty)
                _myRankCard(myEntry),

              // ─── LEADERBOARD LIST ───
              Expanded(
                child: filtered.isEmpty
                    ? _noResultsView()
                    : _leaderboardList(filtered, allEntries),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── SEARCH BAR ───
  Widget _searchBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFF2D2D44),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1B1B2F),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF3D3D5C)),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) {
            setState(() {
              _searchQuery = val.trim().toLowerCase();
            });
          },
          style: const TextStyle(color: Color(0xFFEAEAEA), fontSize: 14),
          decoration: InputDecoration(
            hintText: "Search player name or city...",
            hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
            prefixIcon: const Icon(
              Icons.search,
              color: Color(0xFF9E9E9E),
              size: 20,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: Color(0xFF9E9E9E),
                      size: 20,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 8,
            ),
          ),
        ),
      ),
    );
  }

  // ─── MY RANK CARD ───
  Widget _myRankCard(DocumentSnapshot myEntry) {
    final data = myEntry.data() as Map<String, dynamic>;
    final rank = data['rank'] ?? 0;
    final points = data['totalPoints'] ?? 0;
    final status = data['status'] ?? 'active';
    final isEliminated = status == 'eliminated';

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isEliminated
              ? [Colors.grey[700]!, Colors.grey[800]!]
              : [const Color(0xFF1A73E8), const Color(0xFF00C9A7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isEliminated ? Colors.grey : const Color(0xFF1A73E8))
                .withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isEliminated ? Icons.block : Icons.emoji_events,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEliminated ? "Eliminated" : "Your Rank",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "#$rank",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                "Points",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "$points",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── LEADERBOARD LIST ───
  Widget _leaderboardList(
    List<QueryDocumentSnapshot> filtered,
    List<QueryDocumentSnapshot> allEntries,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final entry = filtered[index];
        final realRank = allEntries.indexWhere((e) => e.id == entry.id) + 1;
        return _leaderboardRow(entry, realRank);
      },
    );
  }

  Widget _leaderboardRow(DocumentSnapshot entry, int rank) {
    final data = entry.data() as Map<String, dynamic>;
    final name = data['userName'] ?? 'Player';
    final city = data['userCity'] ?? '';
    final points = data['totalPoints'] ?? 0;
    final status = data['status'] ?? 'active';
    final isEliminated = status == 'eliminated';
    final isMe = entry.id == _userId;

    Color rankColor = Colors.grey;
    IconData? rankIcon;
    if (rank == 1) {
      rankColor = const Color(0xFFFFD700);
      rankIcon = Icons.emoji_events;
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0);
      rankIcon = Icons.emoji_events;
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32);
      rankIcon = Icons.emoji_events;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe
            ? const Color(0xFF1A73E8).withValues(alpha: 0.15)
            : const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              isMe ? const Color(0xFF00C9A7) : const Color(0xFF3D3D5C),
          width: isMe ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: rank <= 3
                  ? rankColor.withValues(alpha: 0.15)
                  : const Color(0xFF1B1B2F),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: rank <= 3
                  ? Icon(rankIcon, color: rankColor, size: 22)
                  : Text(
                      "#$rank",
                      style: const TextStyle(
                        color: Color(0xFF9E9E9E),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        isMe ? "You" : name,
                        style: TextStyle(
                          color: isMe
                              ? const Color(0xFF00C9A7)
                              : const Color(0xFFEAEAEA),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isEliminated) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "OUT",
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (city.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Color(0xFF9E9E9E),
                        size: 12,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        city,
                        style: const TextStyle(
                          color: Color(0xFF9E9E9E),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Text(
            "$points",
            style: TextStyle(
              color:
                  isMe ? const Color(0xFF00C9A7) : const Color(0xFFEAEAEA),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            "pts",
            style: TextStyle(
              color: Color(0xFF9E9E9E),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.leaderboard_outlined,
                color: Colors.grey[600], size: 80),
            const SizedBox(height: 16),
            const Text(
              "No Leaderboard Yet",
              style: TextStyle(
                color: Color(0xFFEAEAEA),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Leaderboard will appear once matches start.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noResultsView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, color: Colors.grey[600], size: 60),
            const SizedBox(height: 16),
            const Text(
              "No Results",
              style: TextStyle(
                color: Color(0xFFEAEAEA),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "No players found matching \"$_searchQuery\"",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}