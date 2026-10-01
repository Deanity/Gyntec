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
