class Lesson {
  const Lesson({
    required this.id,
    required this.courseId,
    required this.title,
    required this.order,
    required this.content,
    this.theory,
    this.quizId,
  });

  final String id;
  final String courseId;
  final String title;
  final int order;
  final String content;
  final String? theory;
  final String? quizId;

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: (json['id'] ?? json['lessonId']) as String,
      // Support both 'courseId' and legacy/key named 'course' from seed data
      courseId: (json['courseId'] ?? json['course']) as String? ?? '',
      title: json['title'] as String? ?? '',
      order: (json['order'] as num?)?.toInt() ?? 0,
      content: json['content'] as String? ?? '',
      theory: json['theory'] as String? ?? json['content'] as String? ?? '',
      // Support both 'quizId' and legacy/key named 'quiz'
      quizId: (json['quizId'] ?? json['quiz']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'order': order,
      'content': content,
      'theory': theory,
      'quizId': quizId,
    };
  }
}

