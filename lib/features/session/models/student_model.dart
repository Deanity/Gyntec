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
