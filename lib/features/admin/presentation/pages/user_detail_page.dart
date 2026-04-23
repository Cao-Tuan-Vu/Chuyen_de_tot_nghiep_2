import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:btl/features/auth/domain/entities/app_user.dart';
import 'package:intl/intl.dart';

class UserDetailPage extends StatefulWidget {
  final AppUser user;

  const UserDetailPage({super.key, required this.user});

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  List<Map<String, dynamic>> _attempts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserStats();
  }

  Future<void> _fetchUserStats() async {
    try {
      final snapshot = await _database.ref('attempts').get();
      if (snapshot.exists && snapshot.value != null) {
        final Map<dynamic, dynamic> allAttempts = snapshot.value as Map;
        final userAttempts = allAttempts.values
            .map((e) => Map<String, dynamic>.from(e as Map))
            .where((attempt) => attempt['userId'] == widget.user.id)
            .toList();
        
        // Sắp xếp theo thời gian mới nhất
        userAttempts.sort((a, b) => (b['submittedAt'] ?? '').compareTo(a['submittedAt'] ?? ''));

        setState(() {
          _attempts = userAttempts;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching user stats: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user.displayName.isNotEmpty ? widget.user.displayName : 'Chi tiết học viên'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 24),
                  const Text('Thống kê học tập', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatBox('Lượt làm bài', _attempts.length.toString(), Colors.blue),
                      const SizedBox(width: 12),
                      _buildStatBox('Điểm TB', _calculateAvgScore(), Colors.orange),
                      const SizedBox(width: 12),
                      _buildStatBox('Tỷ lệ đạt', _calculatePassRate(), Colors.green),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Lịch sử làm bài', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (_attempts.isEmpty)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text('Chưa có lịch sử làm bài'),
                    ))
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _attempts.length,
                      itemBuilder: (context, index) {
                        final attempt = _attempts[index];
                        final score = (attempt['score'] as num?)?.toInt() ?? 0;
                        final total = (attempt['total'] as num?)?.toInt() ?? 0;
                        final dateStr = attempt['submittedAt'] ?? '';
                        String formattedDate = 'Không rõ ngày';
                        if (dateStr.isNotEmpty) {
                          try {
                            formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(dateStr));
                          } catch (_) {}
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: (score / total) >= 0.6 ? Colors.green[50] : Colors.red[50],
                              child: Text('$score/$total', style: TextStyle(
                                fontSize: 12, 
                                color: (score / total) >= 0.6 ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold
                              )),
                            ),
                            title: Text('Quiz ID: ${attempt['quizId'] ?? 'N/A'}'),
                            subtitle: Text(formattedDate),
                            trailing: Icon(
                              (score / total) >= 0.6 ? Icons.check_circle : Icons.error,
                              color: (score / total) >= 0.6 ? Colors.green : Colors.orange,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.indigo.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.indigo[100],
            child: Text(widget.user.displayName.isNotEmpty ? widget.user.displayName[0].toUpperCase() : 'U',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.user.displayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(widget.user.email, style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.indigo,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(widget.user.role.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }

  String _calculateAvgScore() {
    if (_attempts.isEmpty) return '0.0';
    double total = 0;
    for (var a in _attempts) {
      final s = (a['score'] as num?)?.toDouble() ?? 0.0;
      final t = (a['total'] as num?)?.toDouble() ?? 1.0;
      total += (s / t) * 10;
    }
    return (total / _attempts.length).toStringAsFixed(1);
  }

  String _calculatePassRate() {
    if (_attempts.isEmpty) return '0%';
    int passes = 0;
    for (var a in _attempts) {
      final s = (a['score'] as num?)?.toDouble() ?? 0.0;
      final t = (a['total'] as num?)?.toDouble() ?? 1.0;
      if (s / t >= 0.6) passes++;
    }
    return '${((passes / _attempts.length) * 100).toInt()}%';
  }
}
