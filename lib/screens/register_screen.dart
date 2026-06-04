// lib/screens/register_screen.dart

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscurePass = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final res = await AuthService.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registrasi berhasil! Silakan login.'),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Registrasi gagal.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        children: [
          _buildTopSection(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormCard(),
                  const SizedBox(height: 24),
                  _buildLoginLink(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection() {
    return Container(
      width: double.infinity,
      color: _C.headerBg,
      padding: const EdgeInsets.fromLTRB(28, 64, 28, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _C.accent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.person_add_alt_1_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(height: 20),
          const Text(
            'Buat\nAkun Baru',
            style: TextStyle(
              fontFamily: 'Merriweather',
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Daftar untuk mulai mengelola aktivitasmu',
            style: TextStyle(
              fontFamily: 'Merriweather',
              fontSize: 14,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _C.line),
        boxShadow: [
          BoxShadow(
            color: _C.ink.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _fieldLabel('Nama Lengkap', icon: Icons.person_outline),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameCtrl,
              style: _inputTextStyle(),
              decoration: _inputDecor('Nama lengkapmu'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 20),
            _fieldLabel('Email', icon: Icons.email_outlined),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: _inputTextStyle(),
              decoration: _inputDecor('contoh@email.com'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                if (!v.contains('@')) return 'Format email tidak valid';
                return null;
              },
            ),
            const SizedBox(height: 20),
            _fieldLabel('Password', icon: Icons.lock_outline_rounded),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscurePass,
              style: _inputTextStyle(),
              decoration: _inputDecor('Masukkan password').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePass
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: _C.sub,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password wajib diisi';
                if (v.length < 6) return 'Password minimal 6 karakter';
                return null;
              },
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
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
                        'Daftar',
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
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Sudah punya akun? ',
            style: TextStyle(
              fontFamily: 'Merriweather',
              fontSize: 13,
              color: _C.sub,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
            child: const Text(
              'Login',
              style: TextStyle(
                fontFamily: 'Merriweather',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _C.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text, {required IconData icon}) {
    return Row(
      children: [
        Icon(icon, size: 15, color: _C.accent),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'Merriweather',
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: _C.ink,
          ),
        ),
      ],
    );
  }

  TextStyle _inputTextStyle() => const TextStyle(
        fontFamily: 'Merriweather',
        fontSize: 14,
        color: _C.ink,
      );

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
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
