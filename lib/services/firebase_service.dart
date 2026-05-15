import 'package:firebase_database/firebase_database.dart';
import '../models/course.dart';
import '../models/note.dart';

class FirebaseService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  late final DatabaseReference _coursesRef;
  late final DatabaseReference _notesRef;

  FirebaseService() {
    _coursesRef = _database.ref().child('courses');
    _notesRef = _database.ref().child('notes');
  }

  // ============ COURSE OPERATIONS ============

  /// Add a new course to Firebase
  Future<String> addCourse(String name, String lecturer) async {
    try {
      final newCourseRef = _coursesRef.push();
      await newCourseRef.set({
        'name': name,
        'lecturer': lecturer,
      });
      return newCourseRef.key ?? '';
    } catch (e) {
      throw Exception('Error adding course: $e');
    }
  }

  /// Get all courses as a stream
  Stream<List<Course>> getCoursesStream() {
    print('[FirebaseService] Loading courses...');
    return _coursesRef.onValue
        .timeout(
          const Duration(seconds: 30),
          onTimeout: (sink) {
            print('[FirebaseService] Course stream timeout after 30 seconds');
            sink.addError('Connection timeout. Check your internet connection.');
          },
        )
        .map((event) {
      final courses = <Course>[];
      try {
        if (event.snapshot.exists) {
          final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
          data.forEach((key, value) {
            try {
              courses.add(Course.fromMap(key, Map<dynamic, dynamic>.from(value)));
            } catch (e) {
              print('Error parsing course: $e');
            }
          });
        }
      } catch (e) {
        print('Error in getCoursesStream: $e');
      }
      return courses;
    }).handleError((error) {
      print('[FirebaseService] ERROR loading courses: $error');
      return [];
    });
  }

  /// Get all courses as a future (one-time read)
  Future<List<Course>> getCourses() async {
    try {
      final event = await _coursesRef.once();
      final courses = <Course>[];
      if (event.snapshot.exists) {
        final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          try {
            courses.add(Course.fromMap(key, Map<dynamic, dynamic>.from(value)));
          } catch (e) {
            print('Error parsing course: $e');
          }
        });
      }
      return courses;
    } catch (e) {
      throw Exception('Error fetching courses: $e');
    }
  }

  // ============ NOTE OPERATIONS ============

  /// Add a new note to Firebase
  Future<String> addNote(
    String courseId,
    String courseName,
    String title,
    String content,
  ) async {
    try {
      final newNoteRef = _notesRef.push();
      await newNoteRef.set({
        'courseId': courseId,
        'courseName': courseName,
        'title': title,
        'content': content,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      return newNoteRef.key ?? '';
    } catch (e) {
      throw Exception('Error adding note: $e');
    }
  }

  /// Get all notes as a stream
  Stream<List<Note>> getNotesStream() {
    print('[FirebaseService] Loading notes...');
    return _notesRef.onValue
        .timeout(
          const Duration(seconds: 30),
          onTimeout: (sink) {
            print('[FirebaseService] Note stream timeout after 30 seconds');
            sink.addError('Connection timeout. Check your internet connection.');
          },
        )
        .map((event) {
      final notes = <Note>[];
      try {
        if (event.snapshot.exists) {
          final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
          data.forEach((key, value) {
            try {
              notes.add(Note.fromMap(key, Map<dynamic, dynamic>.from(value)));
            } catch (e) {
              print('Error parsing note: $e');
            }
          });
        }
      } catch (e) {
        print('Error in getNotesStream: $e');
      }
      // Sort notes by timestamp in descending order (newest first)
      notes.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return notes;
    }).handleError((error) {
      print('[FirebaseService] ERROR loading notes: $error');
      return [];
    });
  }

  /// Get all notes as a future (one-time read)
  Future<List<Note>> getNotes() async {
    try {
      final event = await _notesRef.once();
      final notes = <Note>[];
      if (event.snapshot.exists) {
        final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          try {
            notes.add(Note.fromMap(key, Map<dynamic, dynamic>.from(value)));
          } catch (e) {
            print('Error parsing note: $e');
          }
        });
      }
      // Sort notes by timestamp in descending order
      notes.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return notes;
    } catch (e) {
      throw Exception('Error fetching notes: $e');
    }
  }

  /// Get notes for a specific course
  Stream<List<Note>> getNotesByCourseStream(String courseId) {
    return _notesRef.onValue
        .timeout(
          const Duration(seconds: 10),
          onTimeout: (sink) {
            sink.addError('Connection timeout. Check your internet connection.');
          },
        )
        .map((event) {
      final notes = <Note>[];
      try {
        if (event.snapshot.exists) {
          final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
          data.forEach((key, value) {
            try {
              final note = Note.fromMap(key, Map<dynamic, dynamic>.from(value));
              if (note.courseId == courseId) {
                notes.add(note);
              }
            } catch (e) {
              print('Error parsing note: $e');
            }
          });
        }
      } catch (e) {
        print('Error in getNotesByCourseStream: $e');
      }
      notes.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return notes;
    }).handleError((error) {
      print('Firebase Stream Error: $error');
      return [];
    });
  }

  /// Update an existing note
  Future<void> updateNote(String noteId, String title, String content) async {
    try {
      await _notesRef.child(noteId).update({
        'title': title,
        'content': content,
      });
    } catch (e) {
      throw Exception('Error updating note: $e');
    }
  }

  /// Delete a note
  Future<void> deleteNote(String noteId) async {
    try {
      await _notesRef.child(noteId).remove();
    } catch (e) {
      throw Exception('Error deleting note: $e');
    }
  }
}
