import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/image_helper.dart';
import '../../services/sponsor_service.dart';

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
  final _sponsorService = SponsorService();

  String _searchQuery = '';
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _allEntries = [];

  // Filter state
  String _selectedFilter = 'overall';
  String? _latestMatchId;
  String _latestMatchNumber = '';

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

  // ─── Load leaderboard + latest match ───
  Future<void> _loadLeaderboard() async {
    try {
      // Fetch latest match (sorted by timestamp)
      try {
        final matchSnap = await _firestore
            .collection('tournaments')
            .doc(widget.tournamentId)
            .collection('matches')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        if (matchSnap.docs.isNotEmpty) {
          final matchData =
              matchSnap.docs.first.data() as Map<String, dynamic>;
          _latestMatchId = matchSnap.docs.first.id;
          _latestMatchNumber = (matchData['matchNumber'] ?? '').toString();
        }
      } catch (e) {
        // Silently ignore
      }

      // Load leaderboard
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

        final Map<String, dynamic> matchPoints =
            Map<String, dynamic>.from(lbData['matchPoints'] ?? {});

        merged.add({
          'userId': userId,
          'rank': (lbData['rank'] as num?)?.toInt() ?? 0,
          'totalPoints': (lbData['totalPoints'] as num?)?.toInt() ?? 0,
          'matchPoints': matchPoints,
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

  // Filtered + sorted list
  List<Map<String, dynamic>> _getFilteredEntries() {
    List<Map<String, dynamic>> working = _allEntries.map((e) {
      final copy = Map<String, dynamic>.from(e);
      if (_selectedFilter == 'latest' && _latestMatchId != null) {
        final mp = Map<String, dynamic>.from(copy['matchPoints'] ?? {});
        copy['displayPoints'] = (mp[_latestMatchId] as num?)?.toInt() ?? 0;
      } else {
        copy['displayPoints'] = (copy['totalPoints'] as num?)?.toInt() ?? 0;
      }
      return copy;
    }).toList();

    if (_selectedFilter == 'latest' && _latestMatchId != null) {
      working = working.where((e) => (e['displayPoints'] as int) > 0).toList();
    }

    working.sort((a, b) {
      final aPts = a['displayPoints'] as int;
      final bPts = b['displayPoints'] as int;
      final ptsCompare = bPts.compareTo(aPts);
      if (ptsCompare != 0) return ptsCompare;
      final aName = (a['userName'] ?? '').toString().toLowerCase();
      final bName = (b['userName'] ?? '').toString().toLowerCase();
      return aName.compareTo(bName);
    });

    for (int i = 0; i < working.length; i++) {
      working[i]['rank'] = i + 1;
    }

    return working;
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
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    // Agar leaderboard empty hai — sponsor + empty view dikhao
    if (_allEntries.isEmpty) {
      return SingleChildScrollView(
        child: Column(
          children: [
            _sponsorSection(),
            const SizedBox(height: 60),
            _emptyView(),
          ],
        ),
      );
    }

    final filteredEntries = _getFilteredEntries();
    final filtered = filteredEntries.where((e) {
      if (_searchQuery.isEmpty) return true;
      final name = (e['userName'] ?? '').toString().toLowerCase();
      final city = (e['userCity'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery) || city.contains(_searchQuery);
    }).toList();

    final myEntry = filteredEntries.firstWhere(
      (e) => e['userId'] == _userId,
      orElse: () => <String, dynamic>{},
    );
    final hasMyEntry = myEntry.isNotEmpty;

    return Column(
      children: [
        _sponsorSection(),
        _chipRow(),
        _searchBar(),
        if (hasMyEntry && _searchQuery.isEmpty) _myRankCard(myEntry),
        Expanded(
          child: filtered.isEmpty ? _noResultsView() : _listView(filtered),
        ),
      ],
    );
  }

  // ✅ NAYA: Sponsor section
  Widget _sponsorSection() {
    return StreamBuilder<SponsorConfig>(
      stream: _sponsorService.streamConfig(widget.tournamentId),
      builder: (context, snapshot) {
        final config = snapshot.data ?? SponsorConfig();

        if (!config.hasBanner && !config.hasAnySlot) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          color: const Color(0xFF2D2D44),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main banner
              if (config.hasBanner) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    ImageHelper.base64ToBytes(config.bannerBase64),
                    width: double.infinity,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              // 3 slots
              if (config.hasAnySlot)
                Row(
                  children: [
                    if (config.hasSlot1)
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            ImageHelper.base64ToBytes(config.slot1Base64),
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    if (config.hasSlot1 && (config.hasSlot2 || config.hasSlot3))
                      const SizedBox(width: 6),
                    if (config.hasSlot2)
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            ImageHelper.base64ToBytes(config.slot2Base64),
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    if (config.hasSlot2 && config.hasSlot3)
                      const SizedBox(width: 6),
                    if (config.hasSlot3)
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            ImageHelper.base64ToBytes(config.slot3Base64),
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  // Filter chips
  Widget _chipRow() {
    final hasLatest =
        _latestMatchId != null && _latestMatchNumber.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      color: const Color(0xFF2D2D44),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (hasLatest) ...[
              _filterChip(
                label: 'Latest: Match $_latestMatchNumber',
                value: 'latest',
              ),
              const SizedBox(width: 8),
            ],
            _filterChip(
              label: 'Overall',
              value: 'overall',
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip({required String label, required String value}) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00C9A7)
              : const Color(0xFF1B1B2F),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00C9A7)
                : const Color(0xFF3D3D5C),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.check_circle
                  : (value == 'latest'
                      ? Icons.sports_cricket
                      : Icons.leaderboard),
              color: isSelected
                  ? const Color(0xFF1B1B2F)
                  : const Color(0xFF9E9E9E),
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF1B1B2F)
                    : const Color(0xFFEAEAEA),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
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
    final points = myEntry['displayPoints'] ?? myEntry['totalPoints'] ?? 0;
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
    final points = entry['displayPoints'] ?? entry['totalPoints'] ?? 0;
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