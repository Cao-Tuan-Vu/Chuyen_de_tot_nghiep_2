import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class RankingPage extends StatefulWidget {
  const RankingPage({Key? key}) : super(key: key);

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  final db = FirebaseDatabase.instance.ref();
  bool _loading = true;
  List<_UserRanking> _rankings = [];
  int _currentUserRank = 0;
  String _currentUserName = '';

  @override
  void initState() {
    super.initState();
    _loadRankings();
  }

  Future<void> _loadRankings() async {
    setState(() => _loading = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _rankings = [];
          _loading = false;
        });
        return;
      }

      final usersSnap = await db.child('users').get();
      final rankings = <_UserRanking>[];

      if (usersSnap.exists && usersSnap.value is Map) {
        final allUsers = Map<String, dynamic>.from(usersSnap.value as Map);

        for (var entry in allUsers.entries) {
          final userId = entry.key;
          final userData = entry.value;

          if (userData is Map) {
            final userMap = Map<String, dynamic>.from(userData);
            final displayName = userMap['displayName'] ?? userMap['email'] ?? 'Học viên';

            if (userId == currentUser.uid) {
              _currentUserName = displayName;
            }

            int totalScore = 0;
            int totalAttempts = 0;
            int passedCount = 0;

            final resultSnap = await db.child('userQuizResults/$userId').get();
            if (resultSnap.exists && resultSnap.value is Map) {
              final results = Map<String, dynamic>.from(resultSnap.value as Map);
              results.forEach((quizId, resultData) {
                if (resultData is Map) {
                  final score = (resultData['score'] ?? 0) as num;
                  final total = (resultData['total'] ?? 100) as num;
                  totalScore += score.toInt();
                  totalAttempts++;

                  if (total > 0 && score / total >= 0.5) {
                    passedCount++;
                  }
                }
              });
            }

            rankings.add(_UserRanking(
              userId: userId,
              displayName: displayName,
              totalScore: totalScore,
              totalAttempts: totalAttempts,
              passedCount: passedCount,
              averageScore: totalAttempts > 0 ? totalScore / totalAttempts : 0,
            ));
          }
        }
      }

      rankings.removeWhere((r) => r.totalAttempts == 0);
      rankings.sort((a, b) {
        if (b.totalScore != a.totalScore) {
          return b.totalScore.compareTo(a.totalScore);
        }
        return b.averageScore.compareTo(a.averageScore);
      });

      int currentUserRank = 0;
      for (int i = 0; i < rankings.length; i++) {
        if (rankings[i].userId == currentUser.uid) {
          currentUserRank = i + 1;
          break;
        }
      }

      setState(() {
        _rankings = rankings;
        _currentUserRank = currentUserRank;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading rankings: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(),
                if (_rankings.isNotEmpty) SliverToBoxAdapter(child: _buildPodium(isDarkMode)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
                  sliver: _rankings.length <= 3
                      ? (_rankings.isEmpty 
                          ? const SliverFillRemaining(child: Center(child: Text('Chưa có dữ liệu xếp hạng')))
                          : const SliverToBoxAdapter(child: SizedBox.shrink()))
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final ranking = _rankings[index + 3];
                              return _buildRankingTile(ranking, index + 4, isDarkMode);
                            },
                            childCount: _rankings.length - 3,
                          ),
                        ),
                ),
              ],
            ),
      bottomSheet: _buildMyRankSheet(isDarkMode),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      centerTitle: true,
      elevation: 0,
      backgroundColor: const Color(0xFF6366F1),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Bảng Xếp Hạng', 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPodium(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF6366F1),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_rankings.length > 1) _buildPodiumItem(_rankings[1], 2, 100, isDarkMode),
              _buildPodiumItem(_rankings[0], 1, 140, isDarkMode),
              if (_rankings.length > 2) _buildPodiumItem(_rankings[2], 3, 80, isDarkMode),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(_UserRanking user, int rank, double height, bool isDarkMode) {
    Color medalColor = rank == 1 ? const Color(0xFFFFD700) : (rank == 2 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32));
    double avatarSize = rank == 1 ? 44 : 36;

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: medalColor.withOpacity(0.8), width: 3),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: CircleAvatar(
                radius: avatarSize,
                backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                child: Text(user.displayName[0].toUpperCase(), 
                  style: TextStyle(fontSize: avatarSize * 0.8, fontWeight: FontWeight.bold, color: const Color(0xFF6366F1))),
              ),
            ),
            Positioned(
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: medalColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                child: Text(rank.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 10)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 80,
          child: Text(user.displayName, 
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        Text('${user.totalScore}', 
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        Container(
          width: 60,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white.withOpacity(0.25), Colors.white.withOpacity(0.05)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
        )
      ],
    );
  }

  Widget _buildRankingTile(_UserRanking ranking, int position, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(position.toString(), 
              style: TextStyle(fontWeight: FontWeight.w900, color: isDarkMode ? Colors.white30 : Colors.grey[400], fontSize: 16)),
          ),
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
            child: Text(ranking.displayName[0].toUpperCase(), 
              style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ranking.displayName, 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDarkMode ? Colors.white : const Color(0xFF1E293B))),
                Text('Đã học: ${ranking.passedCount} bài', 
                  style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white54 : const Color(0xFF94A3B8))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1), 
              borderRadius: BorderRadius.circular(12)
            ),
            child: Text('${ranking.totalScore}', 
              style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w900)),
          )
        ],
      ),
    );
  }

  Widget _buildMyRankSheet(bool isDarkMode) {
    if (_currentUserRank == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF262626) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF818CF8)]),
              shape: BoxShape.circle
            ),
            child: Center(
              child: Text('#$_currentUserRank', 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('THỨ HẠNG CỦA BẠN', 
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.indigo[300], letterSpacing: 1)),
                const SizedBox(height: 2),
                Text(_currentUserName, 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: isDarkMode ? Colors.white : const Color(0xFF1E293B))),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('TỔNG ĐIỂM', 
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.indigo[300], letterSpacing: 1)),
              const SizedBox(height: 2),
              Text('${_rankings.firstWhere((r) => r.userId == FirebaseAuth.instance.currentUser?.uid).totalScore}', 
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF6366F1))),
            ],
          )
        ],
      ),
    );
  }
}

class _UserRanking {
  final String userId;
  final String displayName;
  final int totalScore;
  final int totalAttempts;
  final int passedCount;
  final double averageScore;

  _UserRanking({
    required this.userId,
    required this.displayName,
    required this.totalScore,
    required this.totalAttempts,
    required this.passedCount,
    required this.averageScore,
  });
}
