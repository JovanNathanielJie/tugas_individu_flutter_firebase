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
      notes.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return notes;
    }).handleError((error) {
      print('[FirebaseService] ERROR loading notes: $error');
      return [];
    });
  }

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
      notes.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return notes;
    } catch (e) {
      throw Exception('Error fetching notes: $e');
    }
  }

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

  Future<void> deleteNote(String noteId) async {
    try {
      await _notesRef.child(noteId).remove();
    } catch (e) {
      throw Exception('Error deleting note: $e');
    }
  }

  Future<void> updateCourse(String courseId, String name, String lecturer) async {
    try {
      await _coursesRef.child(courseId).update({
        'name': name,
        'lecturer': lecturer,
      });
      
      try {
        final event = await _notesRef.once();
        if (event.snapshot.exists) {
          final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
          
          final updateFutures = <Future>[];
          
          data.forEach((key, value) {
            try {
              final note = Map<dynamic, dynamic>.from(value);
              final notesCourseId = note['courseId']?.toString() ?? '';
              final targetCourseId = courseId.toString();
              
              if (notesCourseId == targetCourseId && notesCourseId.isNotEmpty) {
                updateFutures.add(
                  _notesRef.child(key).update({'courseName': name})
                );
              }
            } catch (e) {
              print('[FirebaseService] Error processing note $key: $e');
            }
          });
          
          if (updateFutures.isNotEmpty) {
            await Future.wait(updateFutures);
            await Future.delayed(const Duration(milliseconds: 300));
          }
        }
      } catch (notesError) {}
    } catch (e) {
      throw Exception('Error updating course: $e');
    }
  }

  Future<void> toggleCourseFavorite(String courseId, bool isFavorite) async {
    try {
      await _coursesRef.child(courseId).update({
        'isFavorite': !isFavorite,
      });
    } catch (e) {
      throw Exception('Error updating course favorite: $e');
    }
  }

  Future<void> toggleNoteFavorite(String noteId, bool isFavorite) async {
    try {
      await _notesRef.child(noteId).update({
        'isFavorite': !isFavorite,
      });
    } catch (e) {
      throw Exception('Error updating note favorite: $e');
    }
  }

  Stream<List<Course>> getFavoriteCoursesStream() {
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
              final course = Course.fromMap(key, Map<dynamic, dynamic>.from(value));
              if (course.isFavorite) {
                courses.add(course);
              }
            } catch (e) {
              print('Error parsing course: $e');
            }
          });
        }
      } catch (e) {
        print('Error in getFavoriteCoursesStream: $e');
      }
      return courses;
    }).handleError((error) {
      print('[FirebaseService] ERROR loading favorite courses: $error');
      return [];
    });
  }

  Stream<List<Note>> getFavoriteNotesStream() {
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
              final note = Note.fromMap(key, Map<dynamic, dynamic>.from(value));
              if (note.isFavorite) {
                notes.add(note);
              }
            } catch (e) {
              print('Error parsing note: $e');
            }
          });
        }
      } catch (e) {
        print('Error in getFavoriteNotesStream: $e');
      }
      notes.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return notes;
    }).handleError((error) {
      return [];
    });
  }
}
