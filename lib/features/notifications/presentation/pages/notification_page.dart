import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:btl/features/notifications/domain/entities/notification_item.dart';

class NotificationPage extends StatelessWidget {
  final String userId;

  const NotificationPage({super.key, required this.userId});

  FirebaseDatabase get _database => FirebaseDatabase.instance;

  Future<void> _markAllAsRead() async {
    try {
      final snapshot = await _database.ref('notifications/$userId').get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final Map<String, dynamic> updates = {};
        data.forEach((key, value) {
          if ((value as Map)['isRead'] == false) {
            // Cập nhật đường dẫn đầy đủ để tránh lỗi permission ở cấp cao hơn
            updates['$key/isRead'] = true;
          }
        });
        if (updates.isNotEmpty) {
          await _database.ref('notifications/$userId').update(updates);
        }
      }
    } catch (e) {
      debugPrint("Lỗi khi đánh dấu tất cả đã đọc: $e");
    }
  }

  Future<void> _deleteNotification(String id) async {
    await _database.ref('notifications/$userId/$id').remove();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context, isDarkMode),
          StreamBuilder(
            stream: _database.ref('notifications/$userId').orderByChild('timestamp').onValue,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return SliverFillRemaining(child: Center(child: Text('Đã xảy ra lỗi: ${snapshot.error}')));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
              }

              if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                return SliverFillRemaining(child: _buildEmptyState(isDarkMode));
              }

              final Map<dynamic, dynamic> data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
              final List<NotificationItem> notifications = data.entries.map((e) {
                return NotificationItem.fromMap(e.key.toString(), Map<dynamic, dynamic>.from(e.value as Map));
              }).toList();

              notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = notifications[index];
                      return Dismissible(
                        key: Key(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                        ),
                        onDismissed: (_) => _deleteNotification(item.id),
                        child: _NotificationCard(item: item, userId: userId, isDarkMode: isDarkMode),
                      );
                    },
                    childCount: notifications.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, bool isDarkMode) {
    return SliverAppBar(
      expandedHeight: 180,
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
      actions: [
        StreamBuilder(
          stream: _database.ref('notifications/$userId').onValue,
          builder: (context, snapshot) {
            bool hasUnread = false;
            if (snapshot.hasData && snapshot.data?.snapshot.value != null) {
              final data = snapshot.data!.snapshot.value;
              if (data is Map) {
                hasUnread = data.values.any((e) => (e as Map)['isRead'] == false);
              }
            }
            
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                    child: Icon(
                      Icons.done_all_rounded, 
                      color: hasUnread ? Colors.white : Colors.white60,
                      size: 20,
                    ),
                  ),
                  onPressed: hasUnread ? () => _markAllAsRead() : null,
                ),
                if (hasUnread)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: const Text(
          'Thông báo', 
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.indigo[800]!, Colors.indigo[500]!],
                ),
              ),
            ),
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(Icons.notifications_active_rounded, size: 150, color: Colors.white.withOpacity(0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_none_rounded, size: 80, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          Text(
            'Không có thông báo mới',
            style: TextStyle(
              fontSize: 18, 
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600], 
              fontWeight: FontWeight.w700
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mọi thứ đều yên tĩnh ở đây.',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatefulWidget {
  final NotificationItem item;
  final String userId;
  final bool isDarkMode;

  const _NotificationCard({required this.item, required this.userId, required this.isDarkMode});

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard> {
  late bool _localIsRead;

  @override
  void initState() {
    super.initState();
    _localIsRead = widget.item.isRead;
  }

  @override
  void didUpdateWidget(_NotificationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.isRead != widget.item.isRead) {
      _localIsRead = widget.item.isRead;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color iconColor = _getIconColor(widget.item.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          if (!_localIsRead) {
            setState(() => _localIsRead = true);
            try {
              // Sử dụng .set(true) trực tiếp vào field isRead để đảm bảo chính xác tuyệt đối
              await FirebaseDatabase.instance
                  .ref('notifications/${widget.userId}/${widget.item.id}/isRead')
                  .set(true);
            } catch (e) {
              // Nếu lỗi (mất mạng...), khôi phục lại trạng thái cũ để người dùng biết
              setState(() => _localIsRead = false);
              debugPrint("Lỗi cập nhật thông báo: $e");
            }
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _localIsRead 
                ? (widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white)
                : (widget.isDarkMode ? Colors.indigo.withOpacity(0.1) : Colors.indigo.withAlpha(15)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _localIsRead 
                  ? (widget.isDarkMode ? Colors.grey[800]! : Colors.grey[100]!)
                  : Colors.indigo.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(_getIcon(widget.item.type), color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.item.title,
                            style: TextStyle(
                              fontWeight: _localIsRead ? FontWeight.w700 : FontWeight.w900,
                              fontSize: 16,
                              color: _localIsRead 
                                  ? (widget.isDarkMode ? Colors.white : Colors.black87)
                                  : (widget.isDarkMode ? Colors.indigo[100] : Colors.indigo[900]),
                            ),
                          ),
                        ),
                        if (!_localIsRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.item.body,
                      style: TextStyle(
                        color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[700], 
                        height: 1.5,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('HH:mm - dd/MM/yyyy').format(widget.item.createdAt),
                          style: TextStyle(
                            fontSize: 11, 
                            color: widget.isDarkMode ? Colors.grey[600] : Colors.grey[400],
                            fontWeight: FontWeight.w500
                          ),
                        ),
                        if (widget.item.type != null)
                          _buildTypeChip(widget.item.type!),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildTypeChip(String type) {
    String label = 'Hệ thống';
    Color color = Colors.indigo;
    
    switch (type) {
      case 'quiz_result':
        label = 'Kết quả';
        color = Colors.green;
        break;
      case 'new_course':
        label = 'Khóa học';
        color = Colors.orange;
        break;
      case 'announcement':
        label = 'Tin mới';
        color = Colors.blue;
        break;
      case 'rank_displacement':
        label = 'Xếp hạng';
        color = Colors.purple;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'quiz_result':
        return Icons.assignment_turned_in_rounded;
      case 'new_course':
        return Icons.rocket_launch_rounded;
      case 'announcement':
        return Icons.campaign_rounded;
      case 'rank_displacement':
        return Icons.leaderboard_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _getIconColor(String? type) {
    switch (type) {
      case 'quiz_result':
        return const Color(0xFF10B981);
      case 'new_course':
        return const Color(0xFFF59E0B);
      case 'announcement':
        return const Color(0xFF3B82F6);
      case 'rank_displacement':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF6366F1);
    }
  }
}
