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

  /// Update an existing course
  Future<void> updateCourse(String courseId, String name, String lecturer) async {
    try {
      print('[FirebaseService] Updating course: $courseId with name: $name');
      
      // Update course info first
      await _coursesRef.child(courseId).update({
        'name': name,
        'lecturer': lecturer,
      });
      print('[FirebaseService] Course updated successfully');
      
      // Update all notes with the same courseId to reflect the new course name
      // Query all notes and update matching ones
      try {
        final event = await _notesRef.once();
        if (event.snapshot.exists) {
          final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
          print('[FirebaseService] Total notes in database: ${data.length}');
          
          final updateFutures = <Future>[];
          
          data.forEach((key, value) {
            try {
              final note = Map<dynamic, dynamic>.from(value);
              final notesCourseId = note['courseId']?.toString() ?? '';
              final targetCourseId = courseId.toString();
              
              print('[FirebaseService] Checking note $key: courseId=$notesCourseId vs target=$targetCourseId, courseName=${note['courseName']}');
              
              // Compare as strings to avoid type mismatch issues
              if (notesCourseId == targetCourseId && notesCourseId.isNotEmpty) {
                print('[FirebaseService] MATCH! Updating note: $key from "${note['courseName']}" to "$name"');
                updateFutures.add(
                  _notesRef.child(key).update({'courseName': name}).then((_) {
                    print('[FirebaseService] Successfully updated note $key');
                  }).catchError((e) {
                    print('[FirebaseService] Failed to update note $key: $e');
                  })
                );
              }
            } catch (e) {
              print('[FirebaseService] Error processing note $key: $e');
            }
          });
          
          // Wait for all note updates to complete
          if (updateFutures.isNotEmpty) {
            print('[FirebaseService] Waiting for ${updateFutures.length} note updates...');
            await Future.wait(updateFutures);
            print('[FirebaseService] All notes updated successfully!');
            
            // Extra delay to ensure Firebase replication
            await Future.delayed(const Duration(milliseconds: 300));
          } else {
            print('[FirebaseService] No matching notes found to update');
          }
        } else {
          print('[FirebaseService] No notes exist in database');
        }
      } catch (notesError) {
        print('[FirebaseService] Error updating notes: $notesError');
      }
    } catch (e) {
      print('[FirebaseService] ERROR updating course: $e');
      throw Exception('Error updating course: $e');
    }
  }

  /// Toggle favorite status of a course
  Future<void> toggleCourseFavorite(String courseId, bool isFavorite) async {
    try {
      await _coursesRef.child(courseId).update({
        'isFavorite': !isFavorite,
      });
    } catch (e) {
      throw Exception('Error updating course favorite: $e');
    }
  }

  /// Toggle favorite status of a note
  Future<void> toggleNoteFavorite(String noteId, bool isFavorite) async {
    try {
      await _notesRef.child(noteId).update({
        'isFavorite': !isFavorite,
      });
    } catch (e) {
      throw Exception('Error updating note favorite: $e');
    }
  }

  /// Get favorite courses
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

  /// Get favorite notes
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
      // Sort notes by timestamp in descending order (newest first)
      notes.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return notes;
    }).handleError((error) {
      print('[FirebaseService] ERROR loading favorite notes: $error');
      return [];
    });
  }
}
