class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    this.correctIndex,
    this.explanation,
  });

  final String id;
  final String prompt;
  final List<String> options;
  final int? correctIndex;
  final String? explanation;

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: (json['id'] ?? json['questionId']) as String,
      prompt: json['prompt'] as String? ?? '',
      options: (json['options'] as List<dynamic>).cast<String>(),
      correctIndex: (json['correctIndex'] as num?)?.toInt(),
      explanation: json['explanation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prompt': prompt,
      'options': options,
      'correctIndex': correctIndex,
      'explanation': explanation,
    };
  }
}

class Quiz {
  const Quiz({
    required this.id,
    required this.courseId,
    required this.lessonId,
    required this.title,
    required this.questions,
  });

  final String id;
  final String courseId;
  final String lessonId;
  final String title;
  final List<QuizQuestion> questions;

  factory Quiz.fromJson(Map<String, dynamic> json) {
    // Support two possible quiz formats:
    // 1) Modern format: { 'questions': [ { id, prompt, options, correctIndex, explanation }, ... ] }
    // 2) Seed legacy format: { 'q1': 'prompt', 'q1_opts': [...], 'q1_ans': X, 'q2': ..., ... }
    final id = (json['id'] ?? json['quizId']) as String? ?? '';
    final courseId = json['courseId'] as String? ?? '';
    final lessonId = json['lessonId'] as String? ?? '';
    final title = json['title'] as String? ?? '';

    List<QuizQuestion> questions = [];
    if (json['questions'] != null) {
      questions = (json['questions'] as List<dynamic>)
          .map((item) => QuizQuestion.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      // build from legacy qN / qN_opts / qN_ans scheme
      final pattern = RegExp(r'^q(\d+)$');
      final indices = <int>[];
      for (final key in json.keys) {
        final m = pattern.firstMatch(key);
        if (m != null) {
          final idx = int.tryParse(m.group(1) ?? '0') ?? 0;
          indices.add(idx);
        }
      }
      indices.sort();
      for (final idx in indices) {
        final qKey = 'q$idx';
        final optsKey = 'q${idx}_opts';
        final ansKey = 'q${idx}_ans';
        final prompt = json[qKey] as String? ?? '';
        final options = (json[optsKey] as List<dynamic>?)?.cast<String>() ?? <String>[];
        final correctIndex = (json[ansKey] as num?)?.toInt();
        questions.add(QuizQuestion(
          id: qKey,
          prompt: prompt,
          options: options,
          correctIndex: correctIndex,
          explanation: null,
        ));
      }
    }

    return Quiz(
      id: id,
      courseId: courseId,
      lessonId: lessonId,
      title: title,
      questions: questions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'lessonId': lessonId,
      'title': title,
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }
}

class QuizReviewItem {
  const QuizReviewItem({
    required this.questionId,
    required this.selectedIndex,
    required this.correctIndex,
    required this.isCorrect,
    required this.explanation,
  });

  final String questionId;
  final int? selectedIndex;
  final int correctIndex;
  final bool isCorrect;
  final String explanation;

  factory QuizReviewItem.fromJson(Map<String, dynamic> json) {
    return QuizReviewItem(
      questionId: json['questionId'] as String? ?? '',
      selectedIndex: (json['selectedIndex'] as num?)?.toInt(),
      correctIndex: (json['correctIndex'] as num?)?.toInt() ?? 0,
      isCorrect: json['isCorrect'] as bool? ?? false,
      explanation: json['explanation'] as String? ?? '',
    );
  }
}

class QuizAttemptResult {
  const QuizAttemptResult({
    required this.attemptId,
    required this.quizId,
    required this.userId,
    required this.score,
    required this.total,
    required this.submittedAt,
    required this.review,
  });

  final String attemptId;
  final String quizId;
  final String userId;
  final int score;
  final int total;
  final String submittedAt;
  final List<QuizReviewItem> review;

  factory QuizAttemptResult.fromJson(Map<String, dynamic> json) {
    return QuizAttemptResult(
      attemptId: json['attemptId'] as String? ?? '',
      quizId: json['quizId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      submittedAt: json['submittedAt'] as String? ?? '',
      review: (json['review'] as List<dynamic>)
          .map((item) => QuizReviewItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attemptId': attemptId,
      'quizId': quizId,
      'userId': userId,
      'score': score,
      'total': total,
      'submittedAt': submittedAt,
      'review': review
          .map(
            (item) => {
              'questionId': item.questionId,
              'selectedIndex': item.selectedIndex,
              'correctIndex': item.correctIndex,
              'isCorrect': item.isCorrect,
              'explanation': item.explanation,
            },
          )
          .toList(),
    };
  }
}

