import 'student.dart';

class Group {
  final int id;
  final String name;
  final List<Student> students;
  final int transactionsCount;

  Group({
    required this.id,
    required this.name,
    required this.students,
    this.transactionsCount = 0,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'],
      name: json['name'],
      students: (json['students'] as List<dynamic>?)
              ?.map((e) => Student.fromJson(e))
              .toList() ??
          [],
      transactionsCount: json['transactions_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      // We don't typically send full student objects back when updating a group,
      // but if needed, we'd handle it here. Usually we send IDs.
    };
  }
}
