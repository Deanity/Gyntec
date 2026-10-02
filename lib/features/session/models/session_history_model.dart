/// Model untuk satu kelompok diskusi dalam sebuah sesi belajar.
class SessionGroupModel {
  final String name;
  final int totalPoints;
  final List<String> members;

  const SessionGroupModel({
    required this.name,
    required this.totalPoints,
    required this.members,
  });

  factory SessionGroupModel.fromJson(Map<String, dynamic> json) =>
      SessionGroupModel(
        name: json['name'] as String,
        totalPoints: json['totalPoints'] as int,
        members: List<String>.from(json['members'] as List),
      );
}

/// Model lengkap untuk riwayat sesi belajar — mencakup info sesi,
/// kelompok diskusi beserta anggota & poin, serta daftar seluruh anggota.
class SessionHistoryModel {
  final String id;
  final String date;
  final String level;
  final String title;
  final int studentCount;
  final String subject;
  final int durationMinutes;
  final int totalQuestions;
  final int discussionCount;
  final List<SessionGroupModel> groups;
  final List<String> members;

  const SessionHistoryModel({
    required this.id,
    required this.date,
    required this.level,
    required this.title,
    required this.studentCount,
    required this.subject,
    required this.durationMinutes,
    required this.totalQuestions,
    required this.discussionCount,
    required this.groups,
    required this.members,
  });

  factory SessionHistoryModel.fromJson(Map<String, dynamic> json) =>
      SessionHistoryModel(
        id: json['id'] as String,
        date: json['date'] as String,
        level: json['level'] as String,
        title: json['title'] as String,
        studentCount: json['studentCount'] as int,
        subject: json['subject'] as String,
        durationMinutes: json['durationMinutes'] as int,
        totalQuestions: json['totalQuestions'] as int,
        discussionCount: json['discussionCount'] as int,
        groups: (json['groups'] as List)
            .map((e) => SessionGroupModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        members: List<String>.from(json['members'] as List),
      );
}
