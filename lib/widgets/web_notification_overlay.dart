// lib/widgets/web_notification_overlay.dart
//
// Overlay notifikasi web — menampilkan banner info sederhana
// ketika waktu reminder tiba: mengarahkan user untuk install APK.

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/web_notification_service.dart';

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
    setState(() => _popups.add(_PopupEntry(id: id, event: event)));
    // Auto-dismiss setelah 8 detik
    Future.delayed(const Duration(seconds: 8), () => _dismiss(id));
  }

  void _dismiss(int id) {
    if (!mounted) return;
    setState(() => _popups.removeWhere((p) => p.id == id));
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_popups.isNotEmpty)
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 16, right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: _popups
                      .map((p) => _ReminderInfoBanner(
                            key: ValueKey(p.id),
                            event: p.event,
                            onDismiss: () => _dismiss(p.id),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PopupEntry {
  final int id;
  final WebNotificationEvent event;
  _PopupEntry({required this.id, required this.event});
}

// ── Banner info sederhana — arahkan ke install APK ───────────────────────────
class _ReminderInfoBanner extends StatefulWidget {
  final WebNotificationEvent event;
  final VoidCallback onDismiss;

  const _ReminderInfoBanner({
    super.key,
    required this.event,
    required this.onDismiss,
  });

  @override
  State<_ReminderInfoBanner> createState() => _ReminderInfoBannerState();
}

class _ReminderInfoBannerState extends State<_ReminderInfoBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slide = Tween<Offset>(
      begin: const Offset(1.2, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              width: 300,
              decoration: BoxDecoration(
                color: const Color(0xFF1E2340),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF2D3FE0).withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Baris judul + close ────────────────────────────────
                    Row(
                      children: [
                        const Icon(
                          Icons.alarm_rounded,
                          color: Color(0xFF7B8FFF),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.event.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: _dismissWithAnim,
                          child: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF6B7A99),
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // ── Divider ────────────────────────────────────────────
                    Container(
                      height: 1,
                      color: Colors.white.withOpacity(0.06),
                    ),
                    const SizedBox(height: 10),

                    // ── Pesan utama ────────────────────────────────────────
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.smartphone_rounded,
                          color: Color(0xFFF97316),
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Notifikasi akan muncul di HP Anda.\nSilahkan install Vigenesia pada HP Anda.',
                            style: TextStyle(
                              color: Color(0xFFB0B8D1),
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

