import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/note.dart';
import '../services/firebase_service.dart';
import 'add_course_screen.dart';
import 'add_note_screen.dart';
import 'course_detail_screen.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  final Function(bool)? onThemeChanged;
  
  const HomeScreen({
    Key? key,
    this.onThemeChanged,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  late TabController _tabController;
  bool _isDarkMode = false;
  String _searchQuery = '';
  String _searchCourseQuery = '';
  final TextEditingController _courseSearchController = TextEditingController();
  Timer? _courseSearchDebounce;
  String? _selectedCourseFilter;
  List<Course> _allCourses = [];
  String _sortBy = 'newest'; // 'newest', 'oldest', 'a-z', 'z-a'
  bool _showFavoritesOnly = false; // NEW: Filter untuk favorites

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _courseSearchController.dispose();
    _courseSearchDebounce?.cancel();
    super.dispose();
  }

  String _formatDate(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Kuliah'),
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Toggle Dark Mode',
            onPressed: () {
              setState(() {
                _isDarkMode = !_isDarkMode;
              });
              widget.onThemeChanged?.call(_isDarkMode);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: 'Mata Kuliah'),
            Tab(text: 'Catatan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Courses
          _buildCoursesTab(),
          // Tab 2: Notes
          _buildNotesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddCourseScreen()),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddNoteScreen()),
            );
          }
        },
        backgroundColor: Colors.deepPurple,
        child: Icon(
          _tabController.index == 0 ? Icons.add : Icons.note_add,
        ),
      ),
    );
  }

  Widget _buildCoursesTab() {
    return StreamBuilder<List<Course>>(
      stream: _firebaseService.getCoursesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Error Loading Courses',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final courses = snapshot.data ?? [];

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            // Statistics Card
            Padding(
              padding: const EdgeInsets.all(16),
              child: StreamBuilder<List<Note>>(
                stream: _firebaseService.getNotesStream(),
                builder: (context, notesSnapshot) {
                  final noteCount = notesSnapshot.data?.length ?? 0;
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  final textColor = isDark ? Colors.white : Colors.white;
                  final subtextColor = isDark ? Colors.white70 : Colors.white.withOpacity(0.85);
                  
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [Colors.deepPurple, Colors.indigo]
                            : [Colors.deepPurple.shade400, Colors.deepPurple.shade600],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? Colors.deepPurple : Colors.deepPurple.shade300)
                              .withOpacity(isDark ? 0.3 : 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(isDark ? 0.2 : 0.25),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.book_outlined,
                                  color: textColor,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${courses.length}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                'Mata Kuliah',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: subtextColor,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(isDark ? 0.2 : 0.25),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.note_outlined,
                                  color: textColor,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '$noteCount',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                'Catatan',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: subtextColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Search Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _courseSearchController,
                      onChanged: (v) {
                        if (_courseSearchDebounce?.isActive ?? false) {
                          _courseSearchDebounce!.cancel();
                        }
                        _courseSearchDebounce = Timer(const Duration(milliseconds: 400), () {
                          if (mounted) {
                            setState(() {
                              _searchCourseQuery = v.toLowerCase();
                            });
                          }
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Cari mata kuliah...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _courseSearchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _courseSearchController.clear();
                                  _courseSearchDebounce?.cancel();
                                  if (mounted) {
                                    setState(() {
                                      _searchCourseQuery = '';
                                    });
                                  }
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Tampilkan hanya favorit',
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _showFavoritesOnly = !_showFavoritesOnly;
                        });
                      },
                      icon: Icon(
                        _showFavoritesOnly ? Icons.favorite : Icons.favorite_outline,
                        color: _showFavoritesOnly ? Colors.red : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Courses List
            if (courses.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 80),
                  child: Column(
                    children: [
                      Icon(
                        Icons.school,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada mata kuliah',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tekan tombol + untuk menambahkan',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Builder(
                builder: (context) {
                  var filteredCourses = courses.where((course) {
                    return course.name.toLowerCase().contains(_searchCourseQuery) ||
                        course.lecturer.toLowerCase().contains(_searchCourseQuery);
                  }).toList();

                  // Apply favorites filter
                  if (_showFavoritesOnly) {
                    filteredCourses = filteredCourses.where((course) => course.isFavorite).toList();
                  }

                  if (filteredCourses.isEmpty && _searchCourseQuery.isNotEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tidak ada mata kuliah yang sesuai',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (filteredCourses.isEmpty && _showFavoritesOnly) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Column(
                          children: [
                            Icon(
                              Icons.favorite_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada mata kuliah favorit',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredCourses.length,
                    itemBuilder: (context, index) {
                      final course = filteredCourses[index];
                      final colors = [
                        Colors.deepPurple,
                        Colors.blue,
                        Colors.teal,
                        Colors.indigo,
                        Colors.cyan,
                      ];
                      final color = colors[index % colors.length];
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CourseDetailScreen(course: course),
                                    ),
                                  );
                                },
                                child: Card(
                                  elevation: 0,
                                  margin: EdgeInsets.zero,
                                  child: Column(
                                    children: [
                                      Container(
                                        height: 4,
                                        color: color,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 56,
                                              height: 56,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    color,
                                                    color.withOpacity(0.7),
                                                  ],
                                                ),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Icon(
                                                Icons.book_outlined,
                                                color: Colors.white,
                                                size: 28,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    course.name,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 16,
                                                      letterSpacing: 0.2,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.person_outline,
                                                        size: 14,
                                                        color: Colors.grey[600],
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          course.lecturer,
                                                          style: TextStyle(
                                                            color: Colors.grey[600],
                                                            fontSize: 13,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  // Note count
                                                  StreamBuilder<List<Note>>(
                                                    stream: _firebaseService.getNotesStream(),
                                                    builder: (context, notesSnapshot) {
                                                      final courseNotes = (notesSnapshot.data ?? [])
                                                          .where((n) => n.courseId == course.id)
                                                          .length;
                                                      return Text(
                                                        '📝 $courseNotes catatan',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.grey[500],
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () async {
                                                try {
                                                  await _firebaseService.toggleCourseFavorite(
                                                    course.id,
                                                    course.isFavorite,
                                                  );
                                                } catch (e) {
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('Error: $e'),
                                                        backgroundColor: Colors.red,
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                                              icon: Icon(
                                                course.isFavorite ? Icons.favorite : Icons.favorite_outline,
                                                color: course.isFavorite ? Colors.red : Colors.grey[600],
                                                size: 24,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildNotesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Search field
              TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Cari catatan...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Course filter dropdown
              StreamBuilder<List<Course>>(
                stream: _firebaseService.getCoursesStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }
                  
                  _allCourses = snapshot.data ?? [];
                  List<String> courseNames = ['Semua', ..._allCourses.map((c) => c.name)];
                  
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButton<String?>(
                      value: _selectedCourseFilter == null ? 'Semua' : _selectedCourseFilter,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: courseNames.map((String name) {
                        return DropdownMenuItem<String?>(
                          value: name == 'Semua' ? null : name,
                          child: Text(name),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCourseFilter = newValue;
                        });
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.sort, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildSortButton('Terbaru', 'newest'),
                          const SizedBox(width: 8),
                          _buildSortButton('Terlama', 'oldest'),
                          const SizedBox(width: 8),
                          _buildSortButton('A-Z', 'a-z'),
                          const SizedBox(width: 8),
                          _buildSortButton('Z-A', 'z-a'),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('❤ Favorit'),
                            selected: _showFavoritesOnly,
                            onSelected: (selected) {
                              setState(() {
                                _showFavoritesOnly = !_showFavoritesOnly;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildNotesList(),
        ),
      ],
    );
  }

  Widget _buildSortButton(String label, String value) {
    final isSelected = _sortBy == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _sortBy = value;
        });
      },
    );
  }

  Widget _buildNotesList() {
    return StreamBuilder<List<Note>>(
      stream: _firebaseService.getNotesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Error Loading Notes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        var notes = snapshot.data ?? [];
        
        if (_searchQuery.isNotEmpty) {
          notes = notes.where((note) {
            return note.title.toLowerCase().contains(_searchQuery) ||
                note.content.toLowerCase().contains(_searchQuery) ||
                note.courseName.toLowerCase().contains(_searchQuery);
          }).toList();
        }
        
        if (_selectedCourseFilter != null) {
          notes = notes.where((note) {
            return note.courseName == _selectedCourseFilter;
          }).toList();
        }

        if (_showFavoritesOnly) {
          notes = notes.where((note) => note.isFavorite).toList();
        }

        switch (_sortBy) {
          case 'oldest':
            notes.sort((a, b) => a.timestamp.compareTo(b.timestamp));
            break;
          case 'a-z':
            notes.sort((a, b) => a.title.compareTo(b.title));
            break;
          case 'z-a':
            notes.sort((a, b) => b.title.compareTo(a.title));
            break;
          case 'newest':
          default:
            notes.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        }

        if (notes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.note_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty || _selectedCourseFilter != null
                      ? 'Tidak ada catatan yang sesuai'
                      : 'Belum ada catatan',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            final colors = [
              Colors.deepPurple,
              Colors.green,
              Colors.orange,
              Colors.blue,
              Colors.pink,
            ];
            final color = colors[index % colors.length];
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Card(
                        elevation: 0,
                        margin: EdgeInsets.zero,
                        child: Column(
                          children: [
                            Container(
                              height: 4,
                              color: color,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.note_outlined,
                                          color: color,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              note.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                                letterSpacing: 0.2,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              note.courseName,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 13,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDate(note.timestamp),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: color.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '${note.content.length} char',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: color,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            onPressed: () async {
                                              try {
                                                await _firebaseService.toggleNoteFavorite(
                                                  note.id,
                                                  note.isFavorite,
                                                );
                                              } catch (e) {
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Error: $e'),
                                                      backgroundColor: Colors.red,
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                            icon: Icon(
                                              note.isFavorite ? Icons.favorite : Icons.favorite_outline,
                                              color: note.isFavorite ? Colors.red : Colors.grey[600],
                                              size: 20,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ExpansionTile(
                                    tilePadding: EdgeInsets.zero,
                                    childrenPadding: EdgeInsets.zero,
                                    title: const Text(
                                      'Lihat Detail',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.deepPurple,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    children: [
                                      const Divider(),
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              note.content,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[800],
                                                height: 1.5,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                TextButton.icon(
                                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                                  label: const Text('Edit'),
                                                  onPressed: () => _showEditDialog(context, note),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: Colors.deepPurple,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                TextButton.icon(
                                                  icon: const Icon(Icons.delete_outline, size: 18),
                                                  label: const Text('Hapus'),
                                                  onPressed: () => _showDeleteDialog(context, note.id),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, Note note) {
    final titleController = TextEditingController(text: note.title);
    final contentController = TextEditingController(text: note.content);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Catatan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Isi',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firebaseService.updateNote(
                  note.id,
                  titleController.text,
                  contentController.text,
                );
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Catatan berhasil diperbarui')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String noteId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Catatan'),
        content: const Text('Apakah Anda yakin ingin menghapus catatan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firebaseService.deleteNote(noteId);
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Catatan berhasil dihapus')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
