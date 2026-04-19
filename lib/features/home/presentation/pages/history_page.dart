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

      // Lấy lịch sử làm bài của người dùng
      final historySnap = await db.child('userQuizResults/$uid').get();
      final attempts = <_AttemptHistory>[];

      if (historySnap.exists && historySnap.value is Map) {
        final allResults = Map<String, dynamic>.from(historySnap.value as Map);

        // Lấy thông tin bài tập
        final quizzesSnap = await db.child('quizzes').get();
        final lessonsSnap = await db.child('lessons').get();

        Map<String, dynamic> quizzesData = {};
        Map<String, dynamic> lessonsData = {};

        if (quizzesSnap.exists && quizzesSnap.value is Map) {
          quizzesData = Map<String, dynamic>.from(quizzesSnap.value as Map);
        }
        if (lessonsSnap.exists && lessonsSnap.value is Map) {
          lessonsData = Map<String, dynamic>.from(lessonsSnap.value as Map);
        }

        allResults.forEach((quizId, resultData) {
          if (resultData is Map) {
            final data = Map<String, dynamic>.from(resultData);

            String quizTitle = 'Bài tập không xác định';
            String lessonTitle = '';

            // Lấy tên bài tập
            if (quizzesData.containsKey(quizId)) {
              final quizInfo = quizzesData[quizId];
              if (quizInfo is Map && quizInfo.containsKey('title')) {
                quizTitle = quizInfo['title'] ?? quizTitle;
              }
            }

            // Lấy tên bài học
            for (var lesson in lessonsData.values) {
              if (lesson is Map) {
                final qId = lesson['quizId'] ?? lesson['quiz'];
                if (qId.toString() == quizId) {
                  lessonTitle = lesson['title'] ?? '';
                  break;
                }
              }
            }

            attempts.add(_AttemptHistory(
              quizId: quizId,
              quizTitle: quizTitle,
              lessonTitle: lessonTitle,
              score: data['score'] ?? 0,
              total: data['total'] ?? 0,
              timestamp: data['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
            ));
          }
        });

        // Sắp xếp theo thời gian mới nhất trước
        attempts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }

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
                    final isPassed = percentage >= 50;

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

  _AttemptHistory({
    required this.quizId,
    required this.quizTitle,
    required this.lessonTitle,
    required this.score,
    required this.total,
    required this.timestamp,
  });
}



