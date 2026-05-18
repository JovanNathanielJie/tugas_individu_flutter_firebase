import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/note.dart';
import '../services/firebase_service.dart';
import 'package:intl/intl.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;
  const CourseDetailScreen({Key? key, required this.course}) : super(key: key);

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  late TextEditingController _courseNameController;
  late TextEditingController _lecturerController;
  final FirebaseService _firebaseService = FirebaseService();
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _courseNameController = TextEditingController(text: widget.course.name);
    _lecturerController = TextEditingController(text: widget.course.lecturer);
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    _lecturerController.dispose();
    super.dispose();
  }

  Future<void> _updateCourse() async {
    if (_courseNameController.text.isEmpty || _lecturerController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Field tidak boleh kosong'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('[CourseDetailScreen] Starting course update...');
      await _firebaseService.updateCourse(
        widget.course.id,
        _courseNameController.text.trim(),
        _lecturerController.text.trim(),
      );

      if (mounted) {
        print('[CourseDetailScreen] Update completed, waiting for sync...');
        await Future.delayed(const Duration(milliseconds: 1000));
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Mata kuliah berhasil diperbarui'), backgroundColor: Colors.green),
        );
        
        print('[CourseDetailScreen] Refreshing UI and navigating back...');
        setState(() => _isEditing = false);
        
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      print('[CourseDetailScreen] Error during update: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Mata Kuliah'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Edit',
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _courseNameController.text = widget.course.name;
                _lecturerController.text = widget.course.lecturer;
                setState(() => _isEditing = false);
              },
              tooltip: 'Batal',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade600],
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isEditing)
                    TextFormField(
                      controller: _courseNameController,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: 'Nama mata kuliah',
                        hintStyle: const TextStyle(color: Colors.white70),
                        border: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white, width: 2)),
                      ),
                    )
                  else
                    Text(
                      _courseNameController.text,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  const SizedBox(height: 12),
                  if (_isEditing)
                    TextFormField(
                      controller: _lecturerController,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Nama dosen',
                        hintStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.person, color: Colors.white70),
                        border: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white, width: 2)),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Icon(Icons.person, color: Colors.white70, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _lecturerController.text,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                  if (_isEditing)
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateCourse,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                        child: _isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Simpan Perubahan', style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
            StreamBuilder<List<Note>>(
              stream: _firebaseService.getNotesByCourseStream(widget.course.id),
              builder: (context, snapshot) {
                final notes = snapshot.data ?? [];
                final lastNote = notes.isNotEmpty
                    ? DateTime.fromMillisecondsSinceEpoch(notes.first.timestamp)
                    : null;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatCard('📝 Catatan', notes.length.toString()),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              '❤️ Favorit',
                              widget.course.isFavorite ? 'Ya' : 'Tidak',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              '⏱️ Update',
                              lastNote != null
                                  ? DateFormat('dd MMM').format(lastNote)
                                  : '-',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Catatan untuk mata kuliah ini',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          if (notes.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.note_outlined, size: 48, color: Colors.grey[400]),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Belum ada catatan untuk mata kuliah ini',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: notes.length,
                              itemBuilder: (context, index) {
                                final note = notes[index];
                                final noteTime = DateTime.fromMillisecondsSinceEpoch(note.timestamp);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Card(
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  note.title,
                                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  note.isFavorite ? Icons.favorite : Icons.favorite_outline,
                                                  color: note.isFavorite ? Colors.red : Colors.grey[600],
                                                  size: 20,
                                                ),
                                                onPressed: () async {
                                                  try {
                                                    await _firebaseService.toggleNoteFavorite(note.id, note.isFavorite);
                                                  } catch (e) {
                                                    if (mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                                      );
                                                    }
                                                  }
                                                },
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            note.content,
                                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            DateFormat('dd MMM yyyy, HH:mm').format(noteTime),
                                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
        ],
      ),
    );
  }
}
