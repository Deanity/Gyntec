class ModuleModel {
  final String id;
  final String level;
  final String title;
  final String description;
  final String subject;
  final int totalQuestions;
  final int discussionCount;

  const ModuleModel({
    required this.id,
    required this.level,
    required this.title,
    required this.description,
    this.subject = 'IPA',
    this.totalQuestions = 30,
    this.discussionCount = 1,
  });

  factory ModuleModel.fromJson(Map<String, dynamic> json) => ModuleModel(
        id: json['id'] as String,
        level: json['level'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        subject: json['subject'] as String? ?? 'IPA',
        totalQuestions: json['totalQuestions'] as int? ?? 30,
        discussionCount: json['discussionCount'] as int? ?? 1,
      );
}
