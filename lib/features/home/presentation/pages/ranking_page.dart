import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  final db = FirebaseDatabase.instance.ref();
  bool _loading = true;
  List<_UserRanking> _rankings = [];
  int _currentUserRank = 0;
  String _currentUserName = '';

  String _initialOf(String value) {
    final text = value.trim();
    if (text.isEmpty) return 'H';
    return text[0].toUpperCase();
  }

  _UserRanking? _findMyRanking() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return null;
    }
    for (final ranking in _rankings) {
      if (ranking.userId == currentUserId) {
        return ranking;
      }
    }
    return null;
  }

  String? _normalizeLevel(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final normalized = value.trim().toLowerCase();
    if (normalized == 'easy' || normalized == 'beginner') {
      return 'easy';
    }
    if (normalized == 'medium' || normalized == 'intermediate') {
      return 'medium';
    }
    if (normalized == 'hard' || normalized == 'advanced') {
      return 'hard';
    }
    return null;
  }

  double _scoreByLevel(_UserRanking ranking, String level) {
    switch (level) {
      case 'easy':
        return ranking.easyTestScore;
      case 'medium':
        return ranking.mediumTestScore;
      case 'hard':
        return ranking.hardTestScore;
      default:
        return 0.0;
    }
  }

  bool _hasAttemptByLevel(_UserRanking ranking, String level) {
    switch (level) {
      case 'easy':
        return ranking.hasEasyAttempt;
      case 'medium':
        return ranking.hasMediumAttempt;
      case 'hard':
        return ranking.hasHardAttempt;
      default:
        return false;
    }
  }

  bool _hasAnyLevelAttempt(_UserRanking ranking) {
    return ranking.hasEasyAttempt || ranking.hasMediumAttempt || ranking.hasHardAttempt;
  }

  double _combinedLevelScore(_UserRanking ranking) {
    return ranking.easyTestScore + ranking.mediumTestScore + ranking.hardTestScore;
  }

  String _levelLabel(String level) {
    switch (level) {
      case 'easy':
        return 'Dễ';
      case 'medium':
        return 'Trung bình';
      case 'hard':
        return 'Khó';
      default:
        return level;
    }
  }

  List<_UserRanking> _buildLevelRankings(String level) {
    final list = _rankings.where((item) => _hasAttemptByLevel(item, level)).toList();
    list.sort((a, b) {
      final bScore = _scoreByLevel(b, level);
      final aScore = _scoreByLevel(a, level);
      if (bScore != aScore) {
        return bScore.compareTo(aScore);
      }
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return list;
  }

  List<_UserRanking> _buildCombinedLevelRankings() {
    final list = _rankings.where(_hasAnyLevelAttempt).toList();
    list.sort((a, b) {
      final bScore = _combinedLevelScore(b);
      final aScore = _combinedLevelScore(a);
      if (bScore != aScore) {
        return bScore.compareTo(aScore);
      }
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return list;
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, dynamic item) => MapEntry(key.toString(), item));
    }
    return <String, dynamic>{};
  }

  Future<_UserRanking?> _buildCurrentUserFallbackRanking(User currentUser) async {
    final attemptsIndexSnap = await db.child('users/${currentUser.uid}/quizAttempts').get();
    final attemptsDetailSnap = await db.child('attempts').get();
    final attemptsIndex = _asMap(attemptsIndexSnap.value);
    final attemptsDetail = _asMap(attemptsDetailSnap.value);
    final levelBest = <String, Map<String, dynamic>>{};

    for (final entry in attemptsIndex.entries) {
      final attemptId = entry.key;
      final basic = _asMap(entry.value);
      final detail = _asMap(attemptsDetail[attemptId]);
      final quizId = (basic['quizId'] ?? detail['quizId'] ?? '').toString();
      if (quizId.isEmpty) {
        continue;
      }

      final score = ((basic['score'] ?? detail['score']) as num?)?.toInt() ?? 0;
      final total = ((basic['total'] ?? detail['total']) as num?)?.toInt() ?? 0;
      final percentage = total > 0 ? (score / total) * 100 : 0.0;
      final passed = percentage >= 60;
      final item = {
        'quizId': quizId,
        'score': score,
        'total': total,
        'percentage': percentage,
        'passed': passed,
        'submittedAt': (basic['submittedAt'] ?? detail['submittedAt'] ?? '').toString(),
      };

      final attemptType =
          (basic['attemptType'] ?? detail['attemptType'] ?? '').toString();
      final rawLevel = (basic['level'] ?? detail['level'] ?? '').toString();
      final normalizedLevel = _normalizeLevel(rawLevel);

      if (attemptType == 'level_test' && normalizedLevel != null) {
        final currentLevel = levelBest[normalizedLevel];
        final currentLevelBest =
            currentLevel == null ? -1 : ((currentLevel['percentage'] as num?)?.toDouble() ?? -1);
        if (percentage >= currentLevelBest) {
          levelBest[normalizedLevel] = item;
        }
        continue;
      }
    }

    final levelValues = levelBest.values.toList();
    final activityCount = levelValues.length;
    final passedCount = levelValues.where((e) => e['passed'] == true).length;
    final easyTestScore = (levelBest['easy']?['percentage'] as num?)?.toDouble() ?? 0.0;
    final mediumTestScore = (levelBest['medium']?['percentage'] as num?)?.toDouble() ?? 0.0;
    final hardTestScore = (levelBest['hard']?['percentage'] as num?)?.toDouble() ?? 0.0;
    final totalScore = easyTestScore + mediumTestScore + hardTestScore;

    if (activityCount == 0) {
      return null;
    }

    final displayName =
        (currentUser.displayName != null && currentUser.displayName!.trim().isNotEmpty)
            ? currentUser.displayName!.trim()
            : (currentUser.email?.split('@').first ?? 'Học viên');

    return _UserRanking(
      userId: currentUser.uid,
      displayName: displayName,
      learningScore: 0,
      finalTestScore: 0,
      totalScore: totalScore,
      activityCount: activityCount,
      passedCount: passedCount,
      updatedAt: DateTime.now().toUtc().toIso8601String(),
      easyTestScore: easyTestScore,
      mediumTestScore: mediumTestScore,
      hardTestScore: hardTestScore,
      hasEasyAttempt: levelBest['easy'] != null,
      hasMediumAttempt: levelBest['medium'] != null,
      hasHardAttempt: levelBest['hard'] != null,
    );
  }

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

      final leaderboardSnap = await db.child('leaderboard').get();
      final rankings = <_UserRanking>[];

      if (leaderboardSnap.exists && leaderboardSnap.value is Map) {
        final allRanks = Map<String, dynamic>.from(leaderboardSnap.value as Map);

        for (final entry in allRanks.entries) {
          final userId = entry.key;
          if (entry.value is! Map) {
            continue;
          }
          final userMap = Map<String, dynamic>.from(entry.value as Map);

          final displayName =
              (userMap['displayName'] as String?)?.trim().isNotEmpty == true
                  ? userMap['displayName'] as String
                  : 'Học viên';
          final updatedAt = (userMap['updatedAt'] as String?) ?? '';
          final levelTests = _asMap(userMap['levelTests']);
          final easyTestScore =
              (userMap['easyTestScore'] as num?)?.toDouble() ?? (_asMap(levelTests['easy'])['percentage'] as num?)?.toDouble() ?? 0.0;
          final mediumTestScore =
              (userMap['mediumTestScore'] as num?)?.toDouble() ?? (_asMap(levelTests['medium'])['percentage'] as num?)?.toDouble() ?? 0.0;
          final hardTestScore =
              (userMap['hardTestScore'] as num?)?.toDouble() ?? (_asMap(levelTests['hard'])['percentage'] as num?)?.toDouble() ?? 0.0;
          final hasEasyAttempt = userMap['hasEasyAttempt'] == true || levelTests.containsKey('easy');
          final hasMediumAttempt = userMap['hasMediumAttempt'] == true || levelTests.containsKey('medium');
          final hasHardAttempt = userMap['hasHardAttempt'] == true || levelTests.containsKey('hard');
          final totalScore = easyTestScore + mediumTestScore + hardTestScore;
          final activityCount = [hasEasyAttempt, hasMediumAttempt, hasHardAttempt].where((v) => v).length;
          final passedCount = [
            easyTestScore,
            mediumTestScore,
            hardTestScore,
          ].where((score) => score >= 60).length;

          if (userId == currentUser.uid) {
            _currentUserName = displayName;
          }

          rankings.add(_UserRanking(
            userId: userId,
            displayName: displayName,
            learningScore: 0,
            finalTestScore: 0,
            totalScore: totalScore,
            activityCount: activityCount,
            passedCount: passedCount,
            updatedAt: updatedAt,
            easyTestScore: easyTestScore,
            mediumTestScore: mediumTestScore,
            hardTestScore: hardTestScore,
            hasEasyAttempt: hasEasyAttempt,
            hasMediumAttempt: hasMediumAttempt,
            hasHardAttempt: hasHardAttempt,
          ));
        }
      }

      rankings.removeWhere((r) =>
          r.activityCount == 0 &&
          !r.hasEasyAttempt &&
          !r.hasMediumAttempt &&
          !r.hasHardAttempt);

      if (rankings.isEmpty) {
        final fallback = await _buildCurrentUserFallbackRanking(currentUser);
        if (fallback != null) {
          rankings.add(fallback);
          _currentUserName = fallback.displayName;
        }
      } else {
        final existingCurrentUser = rankings.where((r) => r.userId == currentUser.uid).toList();
        if (existingCurrentUser.isEmpty) {
          final fallback = await _buildCurrentUserFallbackRanking(currentUser);
          if (fallback != null) {
            rankings.add(fallback);
            _currentUserName = fallback.displayName;
          }
        }
      }

      rankings.sort((a, b) {
        if (b.totalScore != a.totalScore) {
          return b.totalScore.compareTo(a.totalScore);
        }
        if (b.passedCount != a.passedCount) {
          return b.passedCount.compareTo(a.passedCount);
        }
        return b.updatedAt.compareTo(a.updatedAt);
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
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F7FF),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: const Color(0xFF4F46E5),
              onRefresh: _loadRankings,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                slivers: [
                  _buildSliverAppBar(isDarkMode),
                  if (_rankings.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildLevelRankingSection(isDarkMode),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                    sliver: _rankings.length <= 3
                            ? (_rankings.isEmpty
                                ? SliverToBoxAdapter(child: _buildEmptyRankingState(isDarkMode))
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
            ),
      bottomSheet: _buildMyRankSheet(isDarkMode),
    );
  }

  Widget _buildSliverAppBar(bool isDarkMode) {
    return SliverAppBar(
      expandedHeight: 170,
      pinned: true,
      centerTitle: true,
      elevation: 0,
      backgroundColor: const Color(0xFF4F46E5),
      title: const Text(
        'Bảng Xếp Hạng',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          tooltip: 'Làm mới BXH',
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _loadRankings,
        ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF6366F1), Color(0xFF818CF8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            right: -30,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -15,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Positioned(
            left: 20,
            right: 56,
            bottom: 18,
            child: Text(
              'Theo dõi tiến bộ học tập và test cuối của bạn',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRankingState(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(top: 28),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events_outlined, color: Color(0xFF6366F1), size: 30),
          ),
          const SizedBox(height: 14),
          Text(
            'Chưa có dữ liệu kiểm tra',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isDarkMode ? Colors.white : const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          Text(
            'Hãy hoàn thành các bài kiểm tra Dễ / Trung bình / Khó để xuất hiện trên bảng xếp hạng.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.grey[400] : Colors.grey[600], height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelRankingSection(bool isDarkMode) {
    final tabTitles = ['Tổng hợp', 'Easy', 'Medium', 'Hard'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'BXH theo bài kiểm tra',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            DefaultTabController(
              length: tabTitles.length,
              child: Column(
                children: [
                  TabBar(
                    isScrollable: true,
                    labelColor: const Color(0xFF4F46E5),
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: const Color(0xFF4F46E5),
                    tabs: tabTitles.map((title) => Tab(text: title)).toList(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 280,
                    child: TabBarView(
                      children: [
                        _buildRankingTabList(
                          rankings: _buildCombinedLevelRankings(),
                          emptyText: 'Chưa có dữ liệu kiểm tra tổng hợp.',
                          scoreBuilder: _combinedLevelScore,
                          isPercent: false,
                        ),
                        _buildRankingTabList(
                          rankings: _buildLevelRankings('easy'),
                          emptyText: 'Chưa có dữ liệu kiểm tra ${_levelLabel('easy')}.',
                          scoreBuilder: (user) => _scoreByLevel(user, 'easy'),
                        ),
                        _buildRankingTabList(
                          rankings: _buildLevelRankings('medium'),
                          emptyText: 'Chưa có dữ liệu kiểm tra ${_levelLabel('medium')}.',
                          scoreBuilder: (user) => _scoreByLevel(user, 'medium'),
                        ),
                        _buildRankingTabList(
                          rankings: _buildLevelRankings('hard'),
                          emptyText: 'Chưa có dữ liệu kiểm tra ${_levelLabel('hard')}.',
                          scoreBuilder: (user) => _scoreByLevel(user, 'hard'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingTabList({
    required List<_UserRanking> rankings,
    required String emptyText,
    required double Function(_UserRanking user) scoreBuilder,
    bool isPercent = true,
  }) {
    if (rankings.isEmpty) {
      return Align(
        alignment: Alignment.topLeft,
        child: Text(
          emptyText,
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    final visible = rankings.length > 8 ? rankings.sublist(0, 8) : rankings;
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: visible.length,
      separatorBuilder: (context, index) => const Divider(height: 8),
      itemBuilder: (context, index) {
        final user = visible[index];
        final score = scoreBuilder(user);
        final displayScore = isPercent ? '${score.toStringAsFixed(1)}%' : score.toStringAsFixed(1);
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
            child: Text('${index + 1}'),
          ),
          title: Text(user.displayName),
          trailing: Text(
            displayScore,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        );
      },
    );
  }

  Widget _buildRankingTile(_UserRanking ranking, int position, bool isDarkMode) {
    final avatarText = _initialOf(ranking.displayName);
    final totalProgress = (ranking.totalScore / 300).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.indigo.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 14, offset: const Offset(0, 6))],
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
            backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
            child: Text(avatarText,
              style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ranking.displayName, 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDarkMode ? Colors.white : const Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Text('Dễ: ${ranking.easyTestScore.toStringAsFixed(1)}% • TB: ${ranking.mediumTestScore.toStringAsFixed(1)}% • Khó: ${ranking.hardTestScore.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white54 : const Color(0xFF64748B))),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 7,
                    value: totalProgress,
                    backgroundColor: Colors.grey.withValues(alpha: 0.1),
                    color: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _InlineMetricBar(
                        label: 'Dễ',
                        value: ranking.easyTestScore,
                        color: const Color(0xFF4F46E5),
                        progress: (ranking.easyTestScore / 100).clamp(0.0, 1.0),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _InlineMetricBar(
                        label: 'Khó',
                        value: ranking.hardTestScore,
                        color: const Color(0xFFF59E0B),
                        progress: (ranking.hardTestScore / 100).clamp(0.0, 1.0),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF818CF8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14)
            ),
            child: Text(ranking.totalScore.toStringAsFixed(1),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          )
        ],
      ),
    );
  }

  Widget _buildMyRankSheet(bool isDarkMode) {
    if (_currentUserRank == 0) return const SizedBox.shrink();
    final myRanking = _findMyRanking();
    if (myRanking == null) {
      return const SizedBox.shrink();
    }
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
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$_currentUserRank',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'THỨ HẠNG CỦA BẠN',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.indigo[300], letterSpacing: 1),
                ),
                const SizedBox(height: 2),
                Text(
                  _currentUserName,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: isDarkMode ? Colors.white : const Color(0xFF1E293B)),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'TỔNG ĐIỂM TEST',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.indigo[300], letterSpacing: 1),
              ),
              const SizedBox(height: 2),
              Text(
                '${myRanking.totalScore.toStringAsFixed(1)}/300',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF6366F1)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserRanking {
  final String userId;
  final String displayName;
  final double learningScore;
  final double finalTestScore;
  final double totalScore;
  final int activityCount;
  final int passedCount;
  final String updatedAt;
  final double easyTestScore;
  final double mediumTestScore;
  final double hardTestScore;
  final bool hasEasyAttempt;
  final bool hasMediumAttempt;
  final bool hasHardAttempt;

  _UserRanking({
    required this.userId,
    required this.displayName,
    required this.learningScore,
    required this.finalTestScore,
    required this.totalScore,
    required this.activityCount,
    required this.passedCount,
    required this.updatedAt,
    required this.easyTestScore,
    required this.mediumTestScore,
    required this.hardTestScore,
    this.hasEasyAttempt = false,
    this.hasMediumAttempt = false,
    this.hasHardAttempt = false,
  });
}


class _InlineMetricBar extends StatelessWidget {
  const _InlineMetricBar({
    required this.label,
    required this.value,
    required this.color,
    required this.progress,
  });

  final String label;
  final double value;
  final Color color;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${value.toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color),
            ),
            Icon(Icons.trending_up_rounded, size: 14, color: color),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 5,
            value: progress.clamp(0.0, 1.0),
            backgroundColor: color.withValues(alpha: 0.1),
            color: color,
          ),
        ),
      ],
    );
  }
}



