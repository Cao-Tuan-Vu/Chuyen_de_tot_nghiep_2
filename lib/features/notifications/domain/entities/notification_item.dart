class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String? type;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.type,
  });

  factory NotificationItem.fromMap(String id, Map<dynamic, dynamic> map) {
    return NotificationItem(
      id: id,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? DateTime.now().millisecondsSinceEpoch),
      isRead: map['isRead'] ?? false,
      type: map['type'],
    );
  }
}
