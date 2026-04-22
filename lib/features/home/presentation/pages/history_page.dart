import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

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

      // Fallback 1: attempts by userId
      if (attempts.isEmpty) {
        attemptsDetailData.forEach((attemptId, item) {
          final detail = _asMap(item);
          if (detail['userId']?.toString() != uid) return;
          final quizId = detail['quizId']?.toString() ?? '';
          if (quizId.isEmpty) return;

          String quizTitle = detail['quizTitle']?.toString() ?? '';
          if (quizTitle.isEmpty && detail['attemptType'] == 'level_test') {
            quizTitle = 'Kiểm tra ${detail['level']?.toString().toUpperCase() ?? 'MEDIUM'}';
          }
          if (quizTitle.isEmpty) quizTitle = _asMap(quizzesData[quizId])['title']?.toString() ?? 'Bài tập';

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
            score: (detail['score'] as num?)?.toInt() ?? 0,
            total: (detail['total'] as num?)?.toInt() ?? 0,
            timestamp: _toTimestamp(detail['submittedAt']),
            attemptType: detail['attemptType']?.toString() ?? '',
            level: detail['level']?.toString() ?? '',
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
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        title: const Text('Lịch sử học tập', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadHistory,
              child: _attempts.isEmpty ? _buildEmptyState(isDarkMode) : _buildList(theme, isDarkMode),
            ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.history_edu_rounded, size: 80, color: Colors.indigo),
              ),
              const SizedBox(height: 24),
              Text(
                'Chưa có dữ liệu',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hãy hoàn thành bài học đầu tiên của bạn!',
                style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildList(ThemeData theme, bool isDarkMode) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _attempts.length,
      itemBuilder: (context, index) {
        final attempt = _attempts[index];
        final percent = attempt.total > 0 ? (attempt.score / attempt.total) : 0.0;
        final isPassed = percent >= 0.6;
        final date = DateTime.fromMillisecondsSinceEpoch(attempt.timestamp);
        final dateStr = "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Thanh màu bên trái
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: isPassed ? Colors.green : Colors.orange,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                attempt.quizTitle,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _buildTypeTag(attempt),
                          ],
                        ),
                        if (attempt.lessonTitle.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            attempt.lessonTitle,
                            style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600], fontSize: 13),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildInfoItem(Icons.calendar_today_rounded, dateStr, isDarkMode),
                            const Spacer(),
                            _buildScoreIndicator(attempt.score, attempt.total, isPassed),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeTag(_AttemptHistory attempt) {
    bool isLevelTest = attempt.attemptType == 'level_test';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLevelTest ? Colors.purple.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isLevelTest ? 'Kiểm tra' : 'Học tập',
        style: TextStyle(
          color: isLevelTest ? Colors.purple : Colors.blue,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, bool isDarkMode) {
    return Row(
      children: [
        Icon(icon, size: 14, color: isDarkMode ? Colors.grey[400] : Colors.grey),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildScoreIndicator(int score, int total, bool isPassed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPassed ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPassed ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 14,
            color: isPassed ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 4),
          Text(
            "$score/$total",
            style: TextStyle(
              color: isPassed ? Colors.green[700] : Colors.red[700],
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
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
