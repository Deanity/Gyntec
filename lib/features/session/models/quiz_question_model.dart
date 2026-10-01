class QuizQuestionModel {
  final String id;
  final int number;
  final int totalQuestions;
  final String question;
  final List<String> options;
  final int correctIndex;

  const QuizQuestionModel({
    required this.id,
    required this.number,
    required this.totalQuestions,
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) =>
      QuizQuestionModel(
        id: json['id'] as String,
        number: json['number'] as int,
        totalQuestions: json['totalQuestions'] as int,
        question: json['question'] as String,
        options: (json['options'] as List).map((e) => e as String).toList(),
        correctIndex: json['correctIndex'] as int,
      );
}
