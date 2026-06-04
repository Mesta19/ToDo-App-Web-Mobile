// lib/services/notification_helper.dart
//
// Conditional export — Dart compiler memilih file yang tepat per platform:
//   dart.library.io  = true  → Android, iOS, Desktop → notification_io.dart (native)
//   dart.library.io  = false → Web Browser           → notification_service_stub.dart (dart:html)
//
// Semua file lain cukup import file ini saja.

export 'notification_service_stub.dart'
    if (dart.library.io) 'notification_io.dart';
