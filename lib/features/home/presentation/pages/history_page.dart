import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final db = FirebaseDatabase.instance.ref();
  bool _loading = true;
  List<_AttemptHistory> _attempts = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<DataSnapshot?> _safeGet(String path) async {
    try {
      return await db.child(path).get();
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((key, dynamic item) => MapEntry(key.toString(), item));
    return <String, dynamic>{};
  }

  int _toTimestamp(Object? raw) {
    if (raw is int) return raw;
    if (raw is String && raw.isNotEmpty) {
      final date = DateTime.tryParse(raw);
      if (date != null) return date.toLocal().millisecondsSinceEpoch;
    }
    return DateTime.now().millisecondsSinceEpoch;
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _attempts = [];
          _loading = false;
        });
        return;
      }

      final uid = user.uid;
      final userAttemptsSnap = await _safeGet('users/$uid/quizAttempts');
      final quizzesSnap = await _safeGet('quizzes');
      final lessonsSnap = await _safeGet('lessons');
      final attemptsDetailSnap = await _safeGet('attempts');

      final quizzesData = _asMap(quizzesSnap?.value);
      final lessonsData = _asMap(lessonsSnap?.value);
      final attemptsDetailData = _asMap(attemptsDetailSnap?.value);

      final List<_AttemptHistory> attempts = [];

      if (userAttemptsSnap?.exists == true && userAttemptsSnap!.value is Map) {
        final userAttemptsData = _asMap(userAttemptsSnap.value);
        userAttemptsData.forEach((attemptId, item) {
          final basic = _asMap(item);
          final detail = _asMap(attemptsDetailData[attemptId]);
          final quizId = (basic['quizId'] ?? detail['quizId'] ?? '').toString();
          if (quizId.isEmpty) return;

          String quizTitle = (basic['quizTitle'] ?? detail['quizTitle'] ?? '').toString();
          final attemptType = (basic['attemptType'] ?? detail['attemptType'] ?? '').toString();
          final level = (basic['level'] ?? detail['level'] ?? '').toString();

          if (quizTitle.isEmpty && attemptType == 'level_test') {
            quizTitle = 'Kiểm tra ${level.toUpperCase()}';
          }

          final quizInfo = _asMap(quizzesData[quizId]);
          if (quizTitle.isEmpty) quizTitle = quizInfo['title']?.toString() ?? 'Bài tập';

          String lessonTitle = '';
          for (final lesson in lessonsData.values) {
            final lessonMap = _asMap(lesson);
            if ((lessonMap['quizId'] ?? lessonMap['quiz'] ?? '').toString() == quizId) {
              lessonTitle = lessonMap['title']?.toString() ?? '';
              break;
            }
          }

          attempts.add(_AttemptHistory(
            quizId: quizId,
            quizTitle: quizTitle,
            lessonTitle: lessonTitle,
            score: ((basic['score'] ?? detail['score']) as num?)?.toInt() ?? 0,
            total: ((basic['total'] ?? detail['total']) as num?)?.toInt() ?? 0,
            timestamp: _toTimestamp(basic['submittedAt'] ?? detail['submittedAt']),
            attemptType: attemptType,
            level: level,
          ));
        });
      }

      attempts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      if (mounted) {
        setState(() {
          _attempts = attempts;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    int totalPassed = _attempts.where((a) => (a.score / a.total) >= 0.7).length;
    double avgScore = _attempts.isEmpty ? 0 : (_attempts.map((a) => a.score / a.total).reduce((a, b) => a + b) / _attempts.length) * 10;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(isDarkMode, totalPassed, avgScore),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                    child: Row(
                      children: [
                        Text(
                          'Hoạt động gần đây',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDarkMode ? Colors.white : Colors.indigo[900],
                            letterSpacing: -0.5,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_attempts.length} bài tập',
                          style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
                _attempts.isEmpty 
                    ? SliverFillRemaining(child: _buildEmptyState(isDarkMode))
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _HistoryCard(attempt: _attempts[index], isDarkMode: isDarkMode),
                            childCount: _attempts.length,
                          ),
                        ),
                      ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
    );
  }

  Widget _buildSliverAppBar(bool isDarkMode, int totalPassed, double avgScore) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      elevation: 0,
      stretch: true,
      backgroundColor: Colors.indigo[700],
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white),
        ),
      ),
      centerTitle: true,
      title: const Text(
        'Hành trình học tập', 
        style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background Gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.indigo[800]!, Colors.indigo[500]!],
                ),
              ),
            ),
            // Decorative circles
            Positioned(
              right: -50,
              top: -50,
              child: CircleAvatar(radius: 100, backgroundColor: Colors.white.withValues(alpha: 0.05)),
            ),
            // Stats content
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Bài tập', _attempts.length.toString(), Icons.assignment_rounded),
                      _buildStatItem('Hoàn thành', totalPassed.toString(), Icons.verified_rounded),
                      _buildStatItem('ĐTB', avgScore.toStringAsFixed(1), Icons.stars_rounded),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_stories_rounded, size: 80, color: Colors.indigo[200]),
          ),
          const SizedBox(height: 24),
          const Text('Chưa có hành trình nào', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final _AttemptHistory attempt;
  final bool isDarkMode;

  const _HistoryCard({required this.attempt, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final percent = attempt.total > 0 ? (attempt.score / attempt.total) : 0.0;
    final isPassed = percent >= 0.7;
    final date = DateTime.fromMillisecondsSinceEpoch(attempt.timestamp);
    final dateStr = DateFormat('HH:mm, dd/MM/yyyy').format(date);

    Color statusColor = isPassed ? const Color(0xFF10B981) : Colors.orange;
    if (percent < 0.4) statusColor = Colors.redAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.4 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getLevelColor(attempt.level).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIcon(attempt.attemptType, attempt.level),
                      color: _getLevelColor(attempt.level),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attempt.quizTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: isDarkMode ? Colors.white : Colors.indigo[900],
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          attempt.lessonTitle.isNotEmpty ? attempt.lessonTitle : 'Luyện tập tổng hợp',
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildScoreBadge(percent, attempt.score, attempt.total),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1, thickness: 1, color: Colors.black12),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time_filled_rounded, size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 6),
                      Text(
                        dateStr,
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isPassed ? 'HOÀN THÀNH' : 'CẦN CỐ GẮNG',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 6,
                  backgroundColor: isDarkMode ? Colors.white10 : Colors.grey[100],
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreBadge(double percent, int score, int total) {
    return Column(
      children: [
        Text(
          "$score",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: percent >= 0.7 ? const Color(0xFF10B981) : Colors.orange[800],
            height: 1,
          ),
        ),
        Text(
          "/$total",
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[400]),
        ),
      ],
    );
  }

  IconData _getIcon(String type, String level) {
    if (type == 'level_test') {
      switch (level.toLowerCase()) {
        case 'easy': return Icons.child_care_rounded;
        case 'medium': return Icons.psychology_rounded;
        case 'hard': return Icons.workspace_premium_rounded;
        default: return Icons.quiz_rounded;
      }
    }
    return Icons.menu_book_rounded;
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'easy': return Colors.green;
      case 'medium': return Colors.blue;
      case 'hard': return Colors.purple;
      default: return Colors.indigo;
    }
  }
}

class _AttemptHistory {
  final String quizId;
  final String quizTitle;
  final String lessonTitle;
  final int score;
  final int total;
  final int timestamp;
  final String attemptType;
  final String level;

  _AttemptHistory({
    required this.quizId,
    required this.quizTitle,
    required this.lessonTitle,
    required this.score,
    required this.total,
    required this.timestamp,
    required this.attemptType,
    required this.level,
  });
}


