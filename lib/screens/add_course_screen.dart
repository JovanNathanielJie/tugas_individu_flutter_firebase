import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import 'dart:async';

class AddCourseScreen extends StatefulWidget {
  const AddCourseScreen({Key? key}) : super(key: key);

  @override
  State<AddCourseScreen> createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends State<AddCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _courseNameController = TextEditingController();
  final _lecturerController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;

  @override
  void dispose() {
    _courseNameController.dispose();
    _lecturerController.dispose();
    super.dispose();
  }

  String? _validateCourseName(String value) {
    if (value.isEmpty) {
      return null; // Don't show error while typing
    } else if (value.length < 3) {
      return 'Minimal 3 karakter';
    }
    return null;
  }

  String? _validateLecturer(String value) {
    if (value.isEmpty) {
      return null;
    } else if (value.length < 3) {
      return 'Minimal 3 karakter';
    }
    return null;
  }

  Future<void> _addCourse() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Add timeout to prevent hanging
        await _firebaseService
            .addCourse(
              _courseNameController.text.trim(),
              _lecturerController.text.trim(),
            )
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                throw TimeoutException('Connection timeout. Please check your internet.');
              },
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Mata kuliah berhasil ditambahkan'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } on TimeoutException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message ?? 'Request timeout'),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Mata Kuliah'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tambah Mata Kuliah',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Daftarkan mata kuliah baru',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Nama Mata Kuliah',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _courseNameController,
                builder: (context, value, child) {
                  final error = _validateCourseName(value.text);
                  final isValid = error == null && value.text.isNotEmpty;

                  return TextFormField(
                    controller: _courseNameController,
                    decoration: InputDecoration(
                      hintText: 'Contoh: Pemrograman Mobile',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: error != null ? Colors.red : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: error != null ? Colors.red : Colors.deepPurple,
                          width: 2,
                        ),
                      ),
                      prefixIcon: const Icon(Icons.book_outlined, color: Colors.deepPurple),
                      suffixIcon: isValid
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      errorText: error,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nama mata kuliah tidak boleh kosong';
                      }
                      if (value.length < 3) {
                        return 'Minimal 3 karakter';
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Nama Dosen',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _lecturerController,
                builder: (context, value, child) {
                  final error = _validateLecturer(value.text);
                  final isValid = error == null && value.text.isNotEmpty;

                  return TextFormField(
                    controller: _lecturerController,
                    decoration: InputDecoration(
                      hintText: 'Contoh: Dr. Andi Wijaya',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: error != null ? Colors.red : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: error != null ? Colors.red : Colors.deepPurple,
                          width: 2,
                        ),
                      ),
                      prefixIcon: const Icon(Icons.person_outline, color: Colors.deepPurple),
                      suffixIcon: isValid
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      errorText: error,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nama dosen tidak boleh kosong';
                      }
                      if (value.length < 3) {
                        return 'Minimal 3 karakter';
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addCourse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'SIMPAN MATA KULIAH',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
