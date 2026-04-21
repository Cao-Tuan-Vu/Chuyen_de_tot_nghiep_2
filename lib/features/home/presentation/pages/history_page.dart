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

  Future<DataSnapshot?> _safeGet(String path) async {
    try {
      return await db.child(path).get();
    } catch (_) {
      return null;
    }
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

  int _toTimestamp(Object? raw) {
    if (raw is int) {
      return raw;
    }
    if (raw is String && raw.isNotEmpty) {
      final date = DateTime.tryParse(raw);
      if (date != null) {
        return date.toLocal().millisecondsSinceEpoch;
      }
    }
    return DateTime.now().millisecondsSinceEpoch;
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
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

      // Nguồn mới: users/{uid}/quizAttempts + attempts/{attemptId}
      final userAttemptsSnap = await _safeGet('users/$uid/quizAttempts');
      final attempts = <_AttemptHistory>[];
      final quizzesSnap = await _safeGet('quizzes');
      final lessonsSnap = await _safeGet('lessons');
      final attemptsDetailSnap = await _safeGet('attempts');

      final quizzesData = _asMap(quizzesSnap?.value);
      final lessonsData = _asMap(lessonsSnap?.value);
      final attemptsDetailData = _asMap(attemptsDetailSnap?.value);

      if (userAttemptsSnap?.exists == true && userAttemptsSnap!.value is Map) {
        final userAttemptsData = _asMap(userAttemptsSnap.value);

        userAttemptsData.forEach((attemptId, item) {
          final basic = _asMap(item);
          final detail = _asMap(attemptsDetailData[attemptId]);
          final quizId = (basic['quizId'] ?? detail['quizId'] ?? '').toString();
          if (quizId.isEmpty) {
            return;
          }

          String quizTitle = (basic['quizTitle'] ?? detail['quizTitle'] ?? '').toString();
          String lessonTitle = '';
          final attemptType = (basic['attemptType'] ?? detail['attemptType'] ?? '').toString();
          final level = (basic['level'] ?? detail['level'] ?? '').toString();

          if (quizTitle.isEmpty && attemptType == 'level_test') {
            final normalizedLevel = level.isEmpty ? 'medium' : level;
            quizTitle = 'Kiểm tra ${normalizedLevel.toUpperCase()}';
          }

          final quizInfo = _asMap(quizzesData[quizId]);
          if (quizTitle.isEmpty && (quizInfo['title'] as String?)?.isNotEmpty == true) {
            quizTitle = quizInfo['title'] as String;
          }

          if (quizTitle.isEmpty) {
            quizTitle = 'Bài tập không xác định';
          }

          for (final lesson in lessonsData.values) {
            final lessonMap = _asMap(lesson);
            final qId = (lessonMap['quizId'] ?? lessonMap['quiz'] ?? '').toString();
            if (qId == quizId) {
              lessonTitle = (lessonMap['title'] ?? '').toString();
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

      // Fallback mới: đọc trực tiếp attempts theo userId khi không có quizAttempts
      if (attempts.isEmpty && attemptsDetailData.isNotEmpty) {
        attemptsDetailData.forEach((attemptId, item) {
          final detail = _asMap(item);
          if (detail['userId']?.toString() != uid) {
            return;
          }

          final quizId = (detail['quizId'] ?? '').toString();
          if (quizId.isEmpty) {
            return;
          }

          String quizTitle = (detail['quizTitle'] ?? '').toString();
          String lessonTitle = '';
          final attemptType = (detail['attemptType'] ?? '').toString();
          final level = (detail['level'] ?? '').toString();

          if (quizTitle.isEmpty && attemptType == 'level_test') {
            final normalizedLevel = level.isEmpty ? 'medium' : level;
            quizTitle = 'Kiểm tra ${normalizedLevel.toUpperCase()}';
          }

          final quizInfo = _asMap(quizzesData[quizId]);
          if (quizTitle.isEmpty && (quizInfo['title'] as String?)?.isNotEmpty == true) {
            quizTitle = quizInfo['title'] as String;
          }

          if (quizTitle.isEmpty) {
            quizTitle = 'Bài tập không xác định';
          }

          for (final lesson in lessonsData.values) {
            final lessonMap = _asMap(lesson);
            final qId = (lessonMap['quizId'] ?? lessonMap['quiz'] ?? '').toString();
            if (qId == quizId) {
              lessonTitle = (lessonMap['title'] ?? '').toString();
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
            attemptType: attemptType,
            level: level,
          ));
        });
      }

      // Fallback cũ: userQuizResults/{uid}
      if (attempts.isEmpty) {
        final legacyHistorySnap = await _safeGet('userQuizResults/$uid');
        if (legacyHistorySnap?.exists == true && legacyHistorySnap!.value is Map) {
          final allResults = _asMap(legacyHistorySnap.value);
          allResults.forEach((quizId, resultData) {
            final data = _asMap(resultData);
            if (data.isEmpty) {
              return;
            }

            String quizTitle = 'Bài tập không xác định';
            String lessonTitle = '';

            final quizInfo = _asMap(quizzesData[quizId]);
            if ((quizInfo['title'] as String?)?.isNotEmpty == true) {
              quizTitle = quizInfo['title'] as String;
            }

            for (final lesson in lessonsData.values) {
              final lessonMap = _asMap(lesson);
              final qId = (lessonMap['quizId'] ?? lessonMap['quiz'] ?? '').toString();
              if (qId == quizId) {
                lessonTitle = (lessonMap['title'] ?? '').toString();
                break;
              }
            }

            attempts.add(_AttemptHistory(
              quizId: quizId,
              quizTitle: quizTitle,
              lessonTitle: lessonTitle,
              score: (data['score'] as num?)?.toInt() ?? 0,
              total: (data['total'] as num?)?.toInt() ?? 0,
              timestamp: _toTimestamp(data['timestamp']),
              attemptType: 'learning',
              level: '',
            ));
          });
        }
      }

      attempts.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      setState(() {
        _attempts = attempts;
        _loading = false;
      });
    } catch (e) {
      print('Error loading history: $e');
      setState(() => _loading = false);
    }
  }

  String _formatDate(int timestamp) {
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$day/$month/$year $hour:$minute';
    } catch (_) {
      return 'Ngày không xác định';
    }
  }

  double _calculatePercentage(int score, int total) {
    if (total == 0) return 0;
    return (score / total) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử làm bài'),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_attempts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text(
                        'Chưa có lịch sử làm bài',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Hãy làm bài tập để xem lịch sử',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _attempts.length,
                  itemBuilder: (context, index) {
                    final attempt = _attempts[index];
                    final percentage = _calculatePercentage(attempt.score, attempt.total);
                    final isPassed = percentage >= 60;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tiêu đề bài tập
                            Text(
                              attempt.quizTitle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // Bài học
                            if (attempt.lessonTitle.isNotEmpty)
                              Text(
                                'Bài học: ${attempt.lessonTitle}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            if (attempt.attemptType == 'level_test')
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  "Mức độ: ${attempt.level.isEmpty ? 'medium' : attempt.level}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.indigo[400],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            // Điểm số
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Điểm: ${attempt.score}/${attempt.total}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Tỉ lệ: ${percentage.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isPassed ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isPassed
                                            ? Colors.green.withAlpha((0.2 * 255).round())
                                            : Colors.red.withAlpha((0.2 * 255).round()),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        isPassed ? 'Đạt' : 'Chưa đạt',
                                        style: TextStyle(
                                          color: isPassed ? Colors.green : Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Thời gian
                            Text(
                              _formatDate(attempt.timestamp),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )),
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



