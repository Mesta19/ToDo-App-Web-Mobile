// lib/widgets/web_notification_overlay.dart
//
// Widget overlay yang menampilkan popup notifikasi in-display di versi web.
// Dengarkan WebNotificationService.stream dan tampilkan banner animasi
// di pojok kanan atas layar. Bisa menumpuk beberapa popup sekaligus.

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/web_notification_service.dart';

// ── Wrapper widget — pasang di atas MaterialApp atau di Scaffold ────────────
class WebNotificationOverlay extends StatefulWidget {
  final Widget child;

  const WebNotificationOverlay({super.key, required this.child});

  @override
  State<WebNotificationOverlay> createState() => _WebNotificationOverlayState();
}

class _WebNotificationOverlayState extends State<WebNotificationOverlay> {
  final List<_PopupEntry> _popups = [];
  StreamSubscription<WebNotificationEvent>? _sub;
  int _idCounter = 0;

  @override
  void initState() {
    super.initState();
    _sub = WebNotificationService.stream.listen(_onEvent);
  }

  void _onEvent(WebNotificationEvent event) {
    if (!mounted) return;
    final id = _idCounter++;
    setState(() {
      _popups.add(_PopupEntry(id: id, event: event));
    });

    // Auto-dismiss setelah 6 detik
    Future.delayed(const Duration(seconds: 6), () {
      _dismiss(id);
    });
  }

  void _dismiss(int id) {
    if (!mounted) return;
    setState(() {
      _popups.removeWhere((p) => p.id == id);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      // Stack tidak intercept pointer secara default — pass-through ke child
      children: [
        widget.child,

        // Hanya tambahkan overlay jika ada popup aktif
        // Saat _popups kosong, tidak ada widget di atas app → sentuhan bebas
        if (_popups.isNotEmpty)
          Positioned(
            top: 0,
            right: 0,
            // IgnorePointer di area LUAR popup card agar tidak memblokir app
            child: IgnorePointer(
              ignoring: false, // popup sendiri tetap interaktif (dismiss button)
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, right: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: _popups
                        .map((p) => _WebNotifPopup(
                              key: ValueKey(p.id),
                              event: p.event,
                              onDismiss: () => _dismiss(p.id),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

}

// ── Internal data class ──────────────────────────────────────────────────────
class _PopupEntry {
  final int id;
  final WebNotificationEvent event;
  _PopupEntry({required this.id, required this.event});
}

// ── Popup card widget dengan animasi slide + fade ────────────────────────────
class _WebNotifPopup extends StatefulWidget {
  final WebNotificationEvent event;
  final VoidCallback onDismiss;

  const _WebNotifPopup({
    super.key,
    required this.event,
    required this.onDismiss,
  });

  @override
  State<_WebNotifPopup> createState() => _WebNotifPopupState();
}

class _WebNotifPopupState extends State<_WebNotifPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;
  late Animation<double> _progress;

  static const _duration = Duration(seconds: 6);

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _slide = Tween<Offset>(
      begin: const Offset(1.2, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );

    // Progress bar mengecil dari 1 → 0 selama durasi tampil
    _progress = Tween<double>(begin: 1.0, end: 0.0).animate(
      AnimationController(vsync: this, duration: _duration)..forward(),
    );

    _ctrl.forward();
  }

  Future<void> _dismissWithAnim() async {
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2D3FE0);
    const cardColor = Color(0xFF1E2340);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Container(
            width: 320,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header ──────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 10, 6),
                    child: Row(
                      children: [
                        // Icon alarm animasi pulse
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.alarm_rounded,
                            color: Color(0xFF7B8FFF),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '⏰ Pengingat Todo',
                                style: TextStyle(
                                  color: Color(0xFF7B8FFF),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.event.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Tombol dismiss
                        IconButton(
                          onPressed: _dismissWithAnim,
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF6B7A99),
                            size: 18,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Deskripsi (jika ada) ─────────────────────────────────
                  if (widget.event.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: Text(
                        widget.event.description,
                        style: const TextStyle(
                          color: Color(0xFF8E97B5),
                          fontSize: 12,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  // ── Waktu reminder ───────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: Color(0xFF6B7A99),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(widget.event.scheduledAt),
                          style: const TextStyle(
                            color: Color(0xFF6B7A99),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Progress bar (auto-dismiss timer) ───────────────────
                  AnimatedBuilder(
                    animation: _progress,
                    builder: (context, _) => LinearProgressIndicator(
                      value: _progress.value,
                      backgroundColor: Colors.white.withOpacity(0.05),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(primaryColor),
                      minHeight: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    return '$h:$m • $d/$mo/${dt.year}';
  }
}
