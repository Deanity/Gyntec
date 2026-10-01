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
