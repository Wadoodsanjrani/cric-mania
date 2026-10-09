import 'dart:convert';
import 'dart:typed_data';
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
  final _firestore = FirebaseFirestore.instance;

  String _searchQuery = '';
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _allEntries = [];

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── Load leaderboard + merge user info ───
  Future<void> _loadLeaderboard() async {
    try {
      final lbSnap = await _firestore
          .collection('tournaments')
          .doc(widget.tournamentId)
          .collection('leaderboard')
          .get();

      final entries = lbSnap.docs;

      if (entries.isEmpty) {
        if (!mounted) return;
        setState(() {
          _allEntries = [];
          _loading = false;
        });
        return;
      }

      // Fetch user profiles in parallel
      final userFutures = entries.map((doc) async {
        try {
          final userDoc =
              await _firestore.collection('users').doc(doc.id).get();
          return userDoc.exists ? (userDoc.data() ?? {}) : <String, dynamic>{};
        } catch (e) {
          return <String, dynamic>{};
        }
      }).toList();

      final userProfiles = await Future.wait(userFutures);

      // Merge leaderboard + user profile
      final List<Map<String, dynamic>> merged = [];
      for (int i = 0; i < entries.length; i++) {
        final lbData = entries[i].data();
        final userData = userProfiles[i];
        final userId = entries[i].id;

        final lbName = (lbData['userName'] ?? '').toString();
        final lbCity = (lbData['userCity'] ?? '').toString();

        merged.add({
          'userId': userId,
          'rank': (lbData['rank'] as num?)?.toInt() ?? 0,
          'totalPoints': (lbData['totalPoints'] as num?)?.toInt() ?? 0,
          'status': lbData['status'] ?? 'active',
          'fpodCount': (lbData['fpodCount'] as num?)?.toInt() ?? 0,
          'userName': lbName.isNotEmpty
              ? lbName
              : (userData['name'] ?? 'Player').toString(),
          'userCity': lbCity.isNotEmpty
              ? lbCity
              : (userData['city'] ?? '').toString(),
          'userPhotoBase64': (userData['profilePhotoBase64'] ?? '').toString(),
        });
      }

      // Sort by totalPoints (descending)
      merged.sort((a, b) {
        final aPts = a['totalPoints'] as int;
        final bPts = b['totalPoints'] as int;
        return bPts.compareTo(aPts);
      });

      // Recalculate ranks
      for (int i = 0; i < merged.length; i++) {
        merged[i]['rank'] = i + 1;
      }

      if (!mounted) return;
      setState(() {
        _allEntries = merged;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load leaderboard: $e';
        _loading = false;
      });
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                _loading = true;
                _error = null;
              });
              _loadLeaderboard();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00C9A7)),
            )
          : _error != null
              ? _errorView(_error!)
              : _allEntries.isEmpty
                  ? _emptyView()
                  : _buildContent(),
    );
  }

  Widget _buildContent() {
    final filtered = _allEntries.where((e) {
      if (_searchQuery.isEmpty) return true;
      final name = (e['userName'] ?? '').toString().toLowerCase();
      final city = (e['userCity'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery) || city.contains(_searchQuery);
    }).toList();

    final myEntry = _allEntries.firstWhere(
      (e) => e['userId'] == _userId,
      orElse: () => <String, dynamic>{},
    );
    final hasMyEntry = myEntry.isNotEmpty;

    return Column(
      children: [
        _searchBar(),
        if (hasMyEntry && _searchQuery.isEmpty) _myRankCard(myEntry),
        Expanded(
          child: filtered.isEmpty ? _noResultsView() : _listView(filtered),
        ),
      ],
    );
  }

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

  Widget _myRankCard(Map<String, dynamic> myEntry) {
    final rank = myEntry['rank'] ?? 0;
    final points = myEntry['totalPoints'] ?? 0;
    final status = myEntry['status'] ?? 'active';
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

  Widget _listView(List<Map<String, dynamic>> filtered) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return _leaderboardRow(filtered[index]);
      },
    );
  }

  Widget _leaderboardRow(Map<String, dynamic> entry) {
    final userId = entry['userId'] ?? '';
    final name = entry['userName'] ?? 'Player';
    final city = entry['userCity'] ?? '';
    final points = entry['totalPoints'] ?? 0;
    final status = entry['status'] ?? 'active';
    final rank = (entry['rank'] as num?)?.toInt() ?? 0;
    final photoBase64 = entry['userPhotoBase64'] ?? '';
    final isEliminated = status == 'eliminated';
    final isMe = userId == _userId;

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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isMe
            ? const Color(0xFF1A73E8).withValues(alpha: 0.15)
            : const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isMe ? const Color(0xFF00C9A7) : const Color(0xFF3D3D5C),
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
          const SizedBox(width: 10),
          if (photoBase64.isNotEmpty)
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isMe ? const Color(0xFF00C9A7) : Colors.white24,
                  width: 1.5,
                ),
              ),
              child: ClipOval(
                child: Image.memory(
                  _safeBase64Decode(photoBase64),
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const Icon(
                    Icons.person,
                    color: Colors.white54,
                    size: 18,
                  ),
                ),
              ),
            ),
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
                        size: 11,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        city,
                        style: const TextStyle(
                          color: Color(0xFF9E9E9E),
                          fontSize: 11,
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

  Uint8List _safeBase64Decode(String base64String) {
    try {
      String cleaned = base64String;
      if (cleaned.contains(',')) {
        cleaned = cleaned.split(',').last;
      }
      return base64Decode(cleaned);
    } catch (e) {
      return Uint8List(0);
    }
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
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
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
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
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