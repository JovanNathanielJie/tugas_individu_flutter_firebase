class Course {
  final String id;
  final String name;
  final String lecturer;
  final bool isFavorite;

  Course({
    required this.id,
    required this.name,
    required this.lecturer,
    this.isFavorite = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'lecturer': lecturer,
      'isFavorite': isFavorite,
    };
  }

  factory Course.fromMap(String id, Map<dynamic, dynamic> map) {
    return Course(
      id: id,
      name: map['name'] ?? '',
      lecturer: map['lecturer'] ?? '',
      isFavorite: map['isFavorite'] ?? false,
    );
  }
}
