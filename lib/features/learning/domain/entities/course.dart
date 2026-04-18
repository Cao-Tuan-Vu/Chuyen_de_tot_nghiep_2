class Course {
  const Course({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
  });

  final String id;
  final String title;
  final String description;
  final String level;

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: (json['id'] ?? json['courseId']) as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      level: json['level'] as String? ?? 'beginner',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'level': level,
    };
  }
}

