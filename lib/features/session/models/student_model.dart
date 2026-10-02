import 'session_model.dart';

class StudentModel {
  final String id;
  final String name;
  final int sessionCount;
  final List<SessionModel> sessions;

  const StudentModel({
    required this.id,
    required this.name,
    this.sessionCount = 0,
    this.sessions = const [],
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) => StudentModel(
        id: json['id'] as String,
        name: json['name'] as String,
        sessionCount: (json['sessionCount'] as int?) ?? 0,
        sessions: (json['sessions'] as List? ?? [])
            .map((e) => SessionModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sessionCount': sessionCount,
        'sessions': sessions.map((s) => s.toJson()).toList(),
      };
}


class DiscussionGroupModel {
  final int number;
  final String name;
  final List<StudentModel> members;

  const DiscussionGroupModel({
    required this.number,
    required this.name,
    required this.members,
  });
}
