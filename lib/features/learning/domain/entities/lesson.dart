class Lesson {
  const Lesson({
    required this.id,
    required this.courseId,
    required this.title,
    required this.order,
    required this.content,
    this.quizId,
  });

  final String id;
  final String courseId;
  final String title;
  final int order;
  final String content;
  final String? quizId;

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: (json['id'] ?? json['lessonId']) as String,
      courseId: json['courseId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      order: (json['order'] as num?)?.toInt() ?? 0,
      content: json['content'] as String? ?? '',
      quizId: json['quizId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'order': order,
      'content': content,
      'quizId': quizId,
    };
  }
}

