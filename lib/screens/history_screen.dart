// lib/screens/history_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo_model.dart';
import '../services/todo_service.dart';

// Palet sama dengan HomeScreen
class _C {
  static const headerBg = Color(0xFF1B2349);
  static const bg = Color(0xFFF5F0E8);
  static const card = Color(0xFFFFFFFF);
  static const accent = Color(0xFFF97316);
  static const ink = Color(0xFF1B2349);
  static const sub = Color(0xFF7C8BA1);
  static const line = Color(0xFFEDE8DF);
  static const done = Color(0xFF10B981);
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Todo> _todos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final todos = await TodoService.getHistory();
    if (mounted) {
      setState(() {
        _todos = todos;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: RefreshIndicator(
        color: _C.accent,
        onRefresh: _loadHistory,
        child: CustomScrollView(
          slivers: [
            _buildHeader(),
            if (_isLoading)
              const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()))
            else if (_todos.isEmpty)
              SliverFillRemaining(child: _buildEmpty())
            else ...[
              SliverToBoxAdapter(child: _buildSectionLabel()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _buildCard(_todos[i]),
                    childCount: _todos.length,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Header navy ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 140,
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
      title: const Text('Riwayat'),
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
                'Catatan Lalu',
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
                'Semua aktivitas yang telah dicatat',
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

  // ── Label section ─────────────────────────────────────────────────────────────
  Widget _buildSectionLabel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: _C.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Riwayat',
            style: TextStyle(
              fontFamily: 'Merriweather',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _C.ink,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _C.accent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_todos.length}',
              style: const TextStyle(
                fontFamily: 'Merriweather',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── History Card (tanpa status badge) ────────────────────────────────────────
  Widget _buildCard(Todo todo) {
    final formattedDate =
        DateFormat('EEE, dd MMM  •  HH:mm', 'id').format(todo.reminderAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ikon centang kecil
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(top: 1, right: 12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _C.done.withOpacity(0.12),
                    border:
                        Border.all(color: _C.done.withOpacity(0.4), width: 1.5),
                  ),
                  child: Icon(Icons.check_rounded, size: 13, color: _C.done),
                ),
                // Judul
                Expanded(
                  child: Text(
                    todo.title,
                    style: const TextStyle(
                      fontFamily: 'Merriweather',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: _C.ink,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            if (todo.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 36),
                child: Text(
                  todo.description,
                  style: const TextStyle(
                    fontFamily: 'Merriweather',
                    fontSize: 12,
                    color: _C.sub,
                    height: 1.6,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Divider(color: _C.line, height: 1, thickness: 1),
            const SizedBox(height: 10),
            // Waktu
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 12, color: _C.sub),
                  const SizedBox(width: 5),
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontFamily: 'Merriweather',
                      fontSize: 11,
                      color: _C.sub,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: const BoxDecoration(
                color: _C.headerBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history_rounded,
                  size: 48, color: Colors.white54),
            ),
            const SizedBox(height: 28),
            const Text(
              'Belum ada riwayat',
              style: TextStyle(
                fontFamily: 'Merriweather',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _C.ink,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Aktivitas yang selesai akan\nmuncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Merriweather',
                fontSize: 13,
                color: _C.sub,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
