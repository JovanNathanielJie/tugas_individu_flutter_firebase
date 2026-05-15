class Note {
  final String id;
  final String courseId;
  final String courseName;
  final String title;
  final String content;
  final int timestamp;
  final bool isFavorite;

  Note({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.title,
    required this.content,
    required this.timestamp,
    this.isFavorite = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'courseName': courseName,
      'title': title,
      'content': content,
      'timestamp': timestamp,
      'isFavorite': isFavorite,
    };
  }

  factory Note.fromMap(String id, Map<dynamic, dynamic> map) {
    return Note(
      id: id,
      courseId: map['courseId'] ?? '',
      courseName: map['courseName'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      timestamp: map['timestamp'] ?? 0,
      isFavorite: map['isFavorite'] ?? false,
    );
  }
}
