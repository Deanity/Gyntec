// Model classes yang merepresentasikan struktur data dari data.json

class UserModel {
  final String name;
  final String greeting;

  const UserModel({required this.name, required this.greeting});

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        name: json['name'] as String,
        greeting: json['greeting'] as String,
      );
}

class OfflineBannerModel {
  final String title;
  final String description;
  final int savedModules;

  const OfflineBannerModel({
    required this.title,
    required this.description,
    required this.savedModules,
  });

  factory OfflineBannerModel.fromJson(Map<String, dynamic> json) =>
      OfflineBannerModel(
        title: json['title'] as String,
        description: json['description'] as String,
        savedModules: json['savedModules'] as int,
      );
}

class SessionModel {
  final String id;
  final String date;
  final String level;
  final String title;
  final int studentCount;
  final String subject;
  final int durationMinutes;

  const SessionModel({
    required this.id,
    required this.date,
    required this.level,
    required this.title,
    required this.studentCount,
    required this.subject,
    required this.durationMinutes,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) => SessionModel(
        id: json['id'] as String,
        date: json['date'] as String,
        level: json['level'] as String,
        title: json['title'] as String,
        studentCount: json['studentCount'] as int,
        subject: json['subject'] as String,
        durationMinutes: json['durationMinutes'] as int,
      );
}

class ModuleModel {
  final String id;
  final String level;
  final String title;
  final String description;

  const ModuleModel({
    required this.id,
    required this.level,
    required this.title,
    required this.description,
  });

  factory ModuleModel.fromJson(Map<String, dynamic> json) => ModuleModel(
        id: json['id'] as String,
        level: json['level'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Modul Detail Models
// ─────────────────────────────────────────────────────────────────────────────

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

class ModulDetailModel {
  final String id;
  final String title;
  final String level;
  final String subject;
  final int totalQuestions;
  final int discussionCount;
  final List<MateriBlockModel> materi;
  final GroupQuestionModel groupQuestion;
  final List<QuizQuestionModel> quiz;

  const ModulDetailModel({
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

  factory ModulDetailModel.fromJson(Map<String, dynamic> json) {
    final quizList = (json['quiz'] as List? ?? [])
        .map((e) => QuizQuestionModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return ModulDetailModel(
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

class StudentModel {
  final String id;
  final String name;

  const StudentModel({
    required this.id,
    required this.name,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) => StudentModel(
        id: json['id'] as String,
        name: json['name'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}

