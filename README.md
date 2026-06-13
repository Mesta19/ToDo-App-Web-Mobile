# ToDo App (Cross-Platform) 🚀

Aplikasi ToDo modern, responsif, dan kaya fitur yang dibangun menggunakan **Flutter**. Aplikasi ini didesain untuk berjalan mulus di **Android (APK)** dan **Web Browser**, memungkinkan pengguna untuk mengatur aktivitas harian dari perangkat apa saja.

![App Banner](https://img.shields.io/badge/Platform-Android%20%7C%20Web-blue?style=for-the-badge&logo=flutter)
![Status](https://img.shields.io/badge/Status-Stable%20Release-success?style=for-the-badge)

## 📱 Fitur Utama

- **Multi-Platform**: Dapat diinstal di HP Android dan diakses langsung melalui Web Browser.
- **Sistem Autentikasi**: Login dan Register yang aman untuk setiap pengguna.
- **Manajemen Aktivitas (CRUD)**:
  - Buat aktivitas dengan judul, catatan detail, dan waktu pengingat.
  - Tandai aktivitas sebagai "Selesai" (*Mark as Done*).
  - Edit aktivitas yang sudah ada.
  - Hapus aktivitas.
- **Riwayat Aktivitas**: Pantau semua tugas yang sudah selesai atau yang waktunya sudah terlewat di halaman "History".
- **Notifikasi Latar Belakang (Android)**: 
  - Sistem pengingat waktu (Alarm) akan berbunyi tepat waktu di HP Anda meskipun aplikasi sedang ditutup.
  - Integrasi cerdas dengan *Autostart* dan *Battery Optimization* (mendukung berbagai merek HP seperti Xiaomi, Oppo, Vivo, Samsung, dll) agar notifikasi anti-telat.
- **Sinkronisasi Web ke Mobile**: 
  - Tambah aktivitas di Web saat sedang bekerja di depan laptop, dan jadwal notifikasinya akan otomatis tersinkronisasi ke HP saat aplikasi Android dibuka.

## 🔗 Akses Aplikasi

### 🌐 Versi Web (Langsung Coba)
Anda bisa langsung mencoba aplikasi ini tanpa perlu mengunduh apapun melalui tautan berikut:
**👉 [Buka ToDo App versi Web](https://Mesta19.github.io/ToDo-App-Web-Mobile/)**

### 📱 Versi Android (APK)
Unduh versi rilis Android (APK) untuk mendapatkan fitur **Notifikasi Alarm** yang berjalan di latar belakang.
**👉 [Unduh APK Terbaru di Halaman Release](https://github.com/Mesta19/ToDo-App-Web-Mobile/releases/latest)**

*(Catatan: Setelah menginstal, pastikan Anda mengizinkan akses notifikasi dan pengaturan Mulai Otomatis (Autostart) saat pertama kali diminta).*

## 🛠️ Arsitektur Teknologi

- **Frontend**: Flutter (Dart) 
- **Backend API**: Native PHP 8 (REST API)
- **Database**: MySQL (MariaDB)
- **Konektivitas**: Menggunakan Ngrok untuk eksposur API lokal ke internet.

## 🤝 Kontribusi
Aplikasi ini dikembangkan sebagai bentuk implementasi manajemen tugas lintas *platform* menggunakan sinkronisasi cerdas antara server web dan notifikasi *native* Android.
