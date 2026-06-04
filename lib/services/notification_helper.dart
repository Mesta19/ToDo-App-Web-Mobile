// lib/services/notification_helper.dart
//
// Wrapper dengan conditional import:
// - Di web   → pakai notification_service_stub.dart (tidak import package native)
// - Di mobile → pakai notification_service.dart (pakai flutter_local_notifications)
//
// Semua file lain import dari sini, BUKAN langsung dari notification_service.dart

export 'notification_service_stub.dart'
    if (dart.library.io) 'notification_service.dart';
