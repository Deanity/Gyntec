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
