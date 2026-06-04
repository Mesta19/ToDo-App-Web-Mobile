// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/todo_service.dart';
import 'add_todo_screen.dart';
import 'edit_todo_screen.dart';
import 'history_screen.dart';
import 'login_screen.dart';

// ── Palet warna: Navy gelap + Krem hangat + Oranye aksen ─────────────────────
class _C {
  static const headerBg = Color(0xFF1B2349); // navy tua
  static const headerCard =
      Color(0xFF242D5C); // navy lebih terang untuk card di header
  static const bg = Color(0xFFF5F0E8); // krem hangat
  static const card = Color(0xFFFFFFFF);
  static const accent = Color(0xFFF97316); // oranye hangat
  static const accentSoft = Color(0xFFFFF0E4);
  static const ink = Color(0xFF1B2349); // navy sebagai warna teks utama
  static const sub = Color(0xFF7C8BA1);
  static const line = Color(0xFFEDE8DF); // border selaras krem
  static const urgent = Color(0xFFEF4444);
  static const urgentBg = Color(0xFFFEF2F2);
  static const soon = Color(0xFFF59E0B);
  static const soonBg = Color(0xFFFFFBEB);
  static const done = Color(0xFF10B981);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Todo> _todos = [];
  bool _isLoading = true;
  String _userName = '';

  // ── Lifecycle ────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadTodos();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    Future.delayed(const Duration(seconds: 30)).then((_) {
      if (mounted) {
        _loadTodos();
        _startAutoRefresh();
      }
    });
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getUser();
    if (mounted) setState(() => _userName = user?.name ?? '');
  }

  Future<void> _loadTodos() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final todos = await TodoService.getTodos();
      if (mounted) setState(() => _todos = todos);
      try {
        await _syncNotifications(todos);
      } catch (_) {}
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Gagal memuat todo.')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _syncNotifications(List<Todo> todos) async {
    final now = DateTime.now();
    for (final todo in todos) {
      try {
        if (todo.isDone || todo.reminderAt.isBefore(now)) {
          await NotificationService.cancelTodoReminder(todo.id);
        } else {
          await NotificationService.scheduleTodoReminder(todo);
        }
      } catch (_) {}
    }
  }

  Future<void> _deleteTodo(int id) async {
    final res = await TodoService.deleteTodo(id);
    if (!mounted) return;
    if (res['status'] == 'success') {
      await NotificationService.cancelTodoReminder(id);
      _loadTodos();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Todo dihapus.')));
    }
  }

  Future<void> _markDone(int id) async {
    final res = await TodoService.markDone(id);
    if (!mounted) return;
    if (res['status'] == 'success') {
      await NotificationService.cancelTodoReminder(id);
      _loadTodos();
    }
  }

  Future<bool> _confirmDelete(Todo todo) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _C.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(
          fontFamily: 'Merriweather',
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: _C.ink,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: 'Merriweather',
          fontSize: 13,
          color: _C.sub,
          height: 1.4,
        ),
        title: const Text('Hapus Todo'),
        content: Text('Yakin ingin menghapus "${todo.title}"?'),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: _C.sub,
              textStyle: const TextStyle(
                fontFamily: 'Merriweather',
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: _C.urgent,
              textStyle: const TextStyle(
                fontFamily: 'Merriweather',
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _confirmLogout() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _C.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(
          fontFamily: 'Merriweather',
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: _C.ink,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: 'Merriweather',
          fontSize: 13,
          color: _C.sub,
          height: 1.4,
        ),
        title: const Text('Logout'),
        content: const Text('Yakin ingin keluar dari akun ini?'),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: _C.sub,
              textStyle: const TextStyle(
                fontFamily: 'Merriweather',
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: _C.urgent,
              textStyle: const TextStyle(
                fontFamily: 'Merriweather',
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _logout();
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  _Urgency _urgencyOf(Todo todo) {
    final diff = todo.reminderAt.difference(DateTime.now());
    if (diff.isNegative) return _Urgency.overdue;
    if (diff.inHours < 2) return _Urgency.soon;
    return _Urgency.normal;
  }

  int get _totalTodos => _todos.length;
  int get _urgentCount =>
      _todos.where((t) => !t.isDone && _urgencyOf(t) != _Urgency.normal).length;

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: RefreshIndicator(
        color: _C.accent,
        onRefresh: _loadTodos,
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
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
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
      floatingActionButton: _buildFAB(),
    );
  }

  // ── Header navy ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final now = DateTime.now();
    final dayName = DateFormat('EEEE', 'id').format(now);
    final dateFmt = DateFormat('d MMMM yyyy', 'id').format(now);

    return SliverAppBar(
      pinned: true,
      expandedHeight: 210,
      backgroundColor: _C.headerBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      // ── Icon bar (pinned) ──
      actions: [
        IconButton(
          icon: const Icon(Icons.history, color: Colors.white70, size: 22),
          tooltip: 'Riwayat',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HistoryScreen()),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white54, size: 22),
          tooltip: 'Logout',
          onPressed: _confirmLogout,
        ),
        const SizedBox(width: 6),
      ],
      // ── Bagian yang bisa di-collapse ──
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          color: _C.headerBg,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tanggal & nama
              Text(
                dayName,
                style: const TextStyle(
                  fontFamily: 'Merriweather',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                dateFmt,
                style: TextStyle(
                  fontFamily: 'Merriweather',
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 20),
              // ── Stat cards ──
              Row(
                children: [
                  _StatCard(
                    label: 'Total Tugas',
                    value: '$_totalTodos',
                    icon: Icons.checklist_rounded,
                    color: _C.accent,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'Perlu Perhatian',
                    value: '$_urgentCount',
                    icon: Icons.notification_important_rounded,
                    color: _urgentCount > 0 ? _C.urgent : Colors.white24,
                  ),
                  const Spacer(),
                  // Tombol refresh
                  GestureDetector(
                    onTap: _loadTodos,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.refresh_rounded,
                          color: Colors.white70, size: 20),
                    ),
                  ),
                ],
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
            'Aktivitas',
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

  // ── Todo Card ─────────────────────────────────────────────────────────────────
  Widget _buildCard(Todo todo) {
    final urgency = _urgencyOf(todo);
    final dotColor = urgency == _Urgency.overdue
        ? _C.urgent
        : urgency == _Urgency.soon
            ? _C.soon
            : _C.done;
    final formattedDate =
        DateFormat('EEE, dd MMM  •  HH:mm', 'id').format(todo.reminderAt);

    return Dismissible(
      key: Key('todo_${todo.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 28),
        decoration: BoxDecoration(
          color: _C.urgent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_rounded, color: Colors.white, size: 22),
            SizedBox(height: 4),
            Text('Hapus',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontFamily: 'Merriweather',
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      confirmDismiss: (_) => _confirmDelete(todo),
      onDismissed: (_) => _deleteTodo(todo.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _C.line),
          boxShadow: [
            BoxShadow(
              color: _C.ink.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
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
                  const SizedBox(width: 8),
                  _MiniBtn(
                    icon: Icons.edit_outlined,
                    color: _C.sub,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => EditTodoScreen(todo: todo)),
                      );
                      _loadTodos();
                    },
                  ),
                  const SizedBox(width: 4),
                  _MiniBtn(
                    icon: Icons.delete_outline_rounded,
                    color: _C.urgent,
                    onTap: () async {
                      if (await _confirmDelete(todo)) _deleteTodo(todo.id);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => _markDone(todo.id),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _C.done.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _C.done.withOpacity(0.4), width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline_rounded,
                            size: 14, color: _C.done),
                        const SizedBox(width: 4),
                        const Text(
                          'Selesai',
                          style: TextStyle(
                            fontFamily: 'Merriweather',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _C.done,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (todo.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
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
              ],
              const SizedBox(height: 12),
              // Divider tipis
              Divider(color: _C.line, height: 1, thickness: 1),
              const SizedBox(height: 10),
              // Baris bawah: waktu + badge
              Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 13, color: dotColor),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      formattedDate,
                      style: TextStyle(
                        fontFamily: 'Merriweather',
                        fontSize: 11,
                        color: urgency != _Urgency.normal ? dotColor : _C.sub,
                        fontWeight: urgency != _Urgency.normal
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (urgency != _Urgency.normal)
                    _UrgencyBadge(urgency: urgency),
                ],
              ),
            ],
          ),
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
              decoration: BoxDecoration(
                color: _C.headerBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.task_alt_rounded,
                  size: 48, color: Colors.white54),
            ),
            const SizedBox(height: 28),
            const Text(
              'Semua bersih!',
              style: TextStyle(
                fontFamily: 'Merriweather',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _C.ink,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Belum ada tugas hari ini.\nTambahkan dengan tombol + di bawah.',
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

  // ── FAB ───────────────────────────────────────────────────────────────────────
  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTodoScreen()),
        );
        _loadTodos();
      },
      backgroundColor: _C.accent,
      foregroundColor: Colors.white,
      elevation: 6,
      icon: const Icon(Icons.add_rounded, size: 22),
      label: const Text(
        'Tambah',
        style: TextStyle(
          fontFamily: 'Merriweather',
          fontWeight: FontWeight.w700,
          fontSize: 14,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Enum & helper widgets ─────────────────────────────────────────────────────
enum _Urgency { normal, soon, overdue }

// Card statistik di header
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Merriweather',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Merriweather',
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UrgencyBadge extends StatelessWidget {
  final _Urgency urgency;
  const _UrgencyBadge({required this.urgency});

  @override
  Widget build(BuildContext context) {
    final isOverdue = urgency == _Urgency.overdue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isOverdue ? _C.urgentBg : _C.soonBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isOverdue ? '⏰ Terlambat' : '⚡ Segera',
        style: TextStyle(
          fontFamily: 'Merriweather',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isOverdue ? _C.urgent : _C.soon,
        ),
      ),
    );
  }
}

class _MiniBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _MiniBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }
}
