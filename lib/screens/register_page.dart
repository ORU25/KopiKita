import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'login_page.dart';

// RegisterPage: layar Daftar (DESIGN.md 3.1a)
// Kerangka sama dengan Masuk; form berisi nama, email, kata sandi
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // State: _sembunyikan menentukan apakah kata sandi disamarkan
  bool _sembunyikan = true;

  // _daftar: masuk ke halaman utama setelah daftar
  // ponytail: belum ada validasi, Firebase Auth + dokumen users/{uid} menyusul
  void _daftar() => masukAplikasi(context);

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      judul: 'Daftar',
      subjudul: 'Buat akun untuk mulai memesan.',
      ajakan: 'Sudah punya akun?',
      aksi: 'Masuk',
      onAksi: () => Navigator.pop(context), // Kembali ke Masuk
      children: [
        // Field Nama
        labelField('Nama'),
        TextField(
          textCapitalization: TextCapitalization.words,
          style: ts(14, 500),
          decoration: const InputDecoration(
            hintText: 'Nama lengkap',
            prefixIcon: Icon(Icons.person_outline_rounded, size: 22),
          ),
        ),
        const SizedBox(height: 14),

        // Field Email
        labelField('Email'),
        TextField(
          keyboardType: TextInputType.emailAddress,
          style: ts(14, 500),
          decoration: const InputDecoration(
            hintText: 'nama@email.com',
            prefixIcon: Icon(Icons.mail_outline_rounded, size: 22),
          ),
        ),
        const SizedBox(height: 14),

        // Field Kata sandi + tombol mata
        labelField('Kata sandi'),
        TextField(
          obscureText: _sembunyikan, // Samarkan teks sesuai state
          style: ts(14, 500),
          decoration: InputDecoration(
            hintText: 'Minimal 6 karakter',
            prefixIcon: const Icon(Icons.lock_outline_rounded,
                size: 22, color: AppColors.primary),
            // suffixIcon: tombol mata 44 untuk menampilkan/menyembunyikan
            suffixIcon: IconButton(
              tooltip: _sembunyikan ? 'Tampilkan sandi' : 'Sembunyikan sandi',
              onPressed: () => setState(() => _sembunyikan = !_sembunyikan),
              icon: Icon(_sembunyikan
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Tombol Daftar
        PrimaryButton(label: 'Daftar', onPressed: _daftar),
      ],
    );
  }
}
