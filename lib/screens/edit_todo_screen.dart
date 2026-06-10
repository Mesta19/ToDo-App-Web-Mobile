// lib/screens/edit_todo_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo_model.dart';
import '../services/todo_service.dart';

// Palet sama dengan seluruh app
class _C {
  static const headerBg = Color(0xFF1B2349);
  static const bg = Color(0xFFF5F0E8);
  static const card = Color(0xFFFFFFFF);
  static const accent = Color(0xFFF97316);
  static const ink = Color(0xFF1B2349);
  static const sub = Color(0xFF7C8BA1);
  static const line = Color(0xFFEDE8DF);
  static const error = Color(0xFFEF4444);
}

class EditTodoScreen extends StatefulWidget {
  final Todo todo;
  const EditTodoScreen({super.key, required this.todo});

  @override
  State<EditTodoScreen> createState() => _EditTodoScreenState();
}

class _EditTodoScreenState extends State<EditTodoScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _titleCtrl = TextEditingController(text: widget.todo.title);
  late final _descCtrl = TextEditingController(text: widget.todo.description);

  late DateTime _selectedDateTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.todo.reminderAt;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime.isAfter(DateTime.now())
          ? _selectedDateTime
          : DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1B2349),
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1B2349),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waktu pengingat harus di masa depan.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final res = await TodoService.updateTodo(
      id: widget.todo.id,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      reminderAt: _selectedDateTime,
      isDone: widget.todo.isDone,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['status'] == 'success') {
      if (kIsWeb) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: _C.bg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              'Sinkronisasi Notifikasi',
              style: TextStyle(fontFamily: 'Merriweather', fontWeight: FontWeight.bold, color: _C.ink),
            ),
            content: const Text(
              'Aktivitas berhasil diperbarui!\n\nKarena Anda memperbarui dari Web, mohon buka aplikasi ToDo App di HP Anda sekali agar alarm pengingat dapat disinkronkan dan berbunyi tepat waktu.',
              style: TextStyle(fontFamily: 'Merriweather', fontSize: 14, color: _C.ink),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Oke, Mengerti', style: TextStyle(color: _C.accent, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aktivitas berhasil diperbarui!')),
        );
      }
      if (!mounted) return;
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Gagal memperbarui todo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: CustomScrollView(
        slivers: [
          _buildHeader(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Judul ──────────────────────────────────────────────
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Judul Aktivitas',
                              icon: Icons.title_rounded),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _titleCtrl,
                            style: const TextStyle(
                              fontFamily: 'Merriweather',
                              fontSize: 15,
                              color: _C.ink,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: _inputDecor('Judul aktivitas'),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Judul wajib diisi'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Deskripsi ──────────────────────────────────────────
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Catatan',
                              icon: Icons.notes_rounded, optional: true),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _descCtrl,
                            maxLines: 4,
                            style: const TextStyle(
                              fontFamily: 'Merriweather',
                              fontSize: 14,
                              color: _C.ink,
                            ),
                            decoration:
                                _inputDecor('Tulis detail tambahan di sini...'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Waktu Pengingat ────────────────────────────────────
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Waktu Pengingat',
                              icon: Icons.alarm_rounded),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _pickDateTime,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: _C.accent.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _C.accent.withOpacity(0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: _C.accent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.calendar_month_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          DateFormat('EEEE, dd MMMM yyyy', 'id')
                                              .format(_selectedDateTime),
                                          style: const TextStyle(
                                            fontFamily: 'Merriweather',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: _C.ink,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          DateFormat('HH:mm')
                                              .format(_selectedDateTime),
                                          style: const TextStyle(
                                            fontFamily: 'Merriweather',
                                            fontSize: 12,
                                            color: _C.accent,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded,
                                      color: _C.accent),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Tombol Simpan ──────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _C.accent,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: _C.accent.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white),
                              )
                            : const Text(
                                'Simpan Perubahan',
                                style: TextStyle(
                                  fontFamily: 'Merriweather',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header navy ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 130,
      backgroundColor: _C.headerBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(color: Colors.white70),
      titleTextStyle: const TextStyle(
        fontFamily: 'Merriweather',
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      title: const Text('Edit Aktivitas'),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          color: _C.headerBg,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Aktivitas',
                style: TextStyle(
                  fontFamily: 'Merriweather',
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Perbarui detail dan pengingat',
                style: TextStyle(
                  fontFamily: 'Merriweather',
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helper widgets ────────────────────────────────────────────────────────────
  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.line),
        boxShadow: [
          BoxShadow(
            color: _C.ink.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _fieldLabel(String text,
      {required IconData icon, bool optional = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _C.accent),
        const SizedBox(width: 7),
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'Merriweather',
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: _C.ink,
          ),
        ),
        if (optional) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: _C.line,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'opsional',
              style: TextStyle(
                fontFamily: 'Merriweather',
                fontSize: 10,
                color: _C.sub,
              ),
            ),
          ),
        ],
      ],
    );
  }

  InputDecoration _inputDecor(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: 'Merriweather',
          color: _C.sub,
          fontSize: 13,
        ),
        filled: true,
        fillColor: _C.bg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.error, width: 2),
        ),
      );
}
