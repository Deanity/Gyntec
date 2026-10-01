import '../../session/models/quiz_question_model.dart';

class MateriBlockModel {
  final String id;
  final String heading;
  final String body;
  final String? imageAsset;

  const MateriBlockModel({
    required this.id,
    required this.heading,
    required this.body,
    this.imageAsset,
  });

  factory MateriBlockModel.fromJson(Map<String, dynamic> json) =>
      MateriBlockModel(
        id: json['id'] as String,
        heading: json['heading'] as String,
        body: json['body'] as String,
        imageAsset: json['imageAsset'] as String?,
      );
}

class GroupQuestionModel {
  final String title;
  final List<String> instructions;
  final List<String> indicators;

  const GroupQuestionModel({
    required this.title,
    required this.instructions,
    required this.indicators,
  });

  factory GroupQuestionModel.fromJson(Map<String, dynamic> json) =>
      GroupQuestionModel(
        title: json['title'] as String,
        instructions:
            (json['instructions'] as List).map((e) => e as String).toList(),
        indicators:
            (json['indicators'] as List).map((e) => e as String).toList(),
      );
}

class ModuleDetailModel {
  final String id;
  final String title;
  final String level;
  final String subject;
  final int totalQuestions;
  final int discussionCount;
  final List<MateriBlockModel> materi;
  final GroupQuestionModel groupQuestion;
  final List<QuizQuestionModel> quiz;

  const ModuleDetailModel({
    required this.id,
    required this.title,
    required this.level,
    required this.subject,
    this.totalQuestions = 30,
    this.discussionCount = 1,
    required this.materi,
    required this.groupQuestion,
    required this.quiz,
  });

  factory ModuleDetailModel.fromJson(Map<String, dynamic> json) {
    final quizList = (json['quiz'] as List? ?? [])
        .map((e) => QuizQuestionModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return ModuleDetailModel(
      id: json['id'] as String,
      title: json['title'] as String,
      level: json['level'] as String,
      subject: json['subject'] as String,
      totalQuestions: json['totalQuestions'] as int? ??
          (quizList.isNotEmpty ? quizList.first.totalQuestions : 30),
      discussionCount: json['discussionCount'] as int? ?? 1,
      materi: (json['materi'] as List)
          .map((e) => MateriBlockModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      groupQuestion: GroupQuestionModel.fromJson(
          json['groupQuestion'] as Map<String, dynamic>),
      quiz: quizList,
    );
  }
}

/// Backward compatibility alias
typedef ModulDetailModel = ModuleDetailModel;
