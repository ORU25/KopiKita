import 'package:flutter/material.dart';

import '../main.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'register_page.dart';

// LoginPage: layar Masuk (DESIGN.md 3.1)
// Banner gelap di atas + card melayang berisi form email & kata sandi
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // State: _sembunyikan menentukan apakah kata sandi disamarkan
  bool _sembunyikan = true;

  // _masuk: pindah ke halaman utama (NavigationPage)
  // ponytail: belum ada validasi, Firebase Auth menyusul
  void _masuk() => masukAplikasi(context);

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      judul: 'Masuk',
      subjudul: 'Masuk untuk mulai memesan.',
      ajakan: 'Belum punya akun?',
      aksi: 'Daftar',
      onAksi: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RegisterPage()),
      ),
      children: [
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
            hintText: 'Kata sandi',
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

        // Link "Lupa kata sandi?" rata kanan
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => segeraHadir(context, 'Lupa kata sandi'),
            child: Text('Lupa kata sandi?',
                style: ts(13, 700, color: AppColors.primary)),
          ),
        ),
        const SizedBox(height: 4),

        // Tombol Masuk
        PrimaryButton(label: 'Masuk', onPressed: _masuk),
      ],
    );
  }
}

// masukAplikasi: buka halaman utama (tab Beranda) dan buang riwayat Login/Daftar
void masukAplikasi(BuildContext context) {
  NavigationPage.tab.value = NavigationPage.tabBeranda; // Mulai dari Beranda
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const NavigationPage()),
    (_) => false,
  );
}

// labelField: label field 12/700 textSecondary
Widget labelField(String teks) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(teks, style: ts(12, 700, color: AppColors.textSecondary)),
    );

// AuthScaffold: kerangka bersama Masuk & Daftar —
// banner gelap, badge logo, card melayang berisi form, dan ajakan di bawah
class AuthScaffold extends StatelessWidget {
  final String judul; // "Masuk" / "Daftar"
  final String subjudul; // Kalimat di bawah judul
  final List<Widget> children; // Isi form di dalam card
  final String ajakan; // Teks bawah, mis. "Belum punya akun?"
  final String aksi; // Link bawah, mis. "Daftar"
  final VoidCallback onAksi; // Aksi link bawah
  const AuthScaffold({
    super.key,
    required this.judul,
    required this.subjudul,
    required this.children,
    required this.ajakan,
    required this.aksi,
    required this.onAksi,
  });

  @override
  Widget build(BuildContext context) {
    // Scaffold: kerangka halaman Masuk/Daftar
    return Scaffold(
      // SingleChildScrollView: agar form bisa digeser saat keyboard muncul
      body: SingleChildScrollView(
        // Stack: banner di belakang, card melayang menimpa bagian bawah banner
        child: Stack(
          children: [
            // Container: banner atas tinggi 290, latar ink, radius bawah 24
            Container(
              height: 290,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 64, 24, 0),
              decoration: const BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              // Column: brand + tagline rata tengah (selaras badge logo)
              child: Column(
                children: [
                  Text('KopiKita',
                      style: ts(30, 800, color: AppColors.cream, ls: -0.6)),
                  const SizedBox(height: 6),
                  Text('Pesan kopi favoritmu tanpa antre.',
                      style: ts(14, 500, color: AppColors.cream)),
                ],
              ),
            ),
            // Padding: posisi card melayang (top 226, inset 16)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 226, 16, 24),
              // Container: card radius 24, padding atas 58 (ruang setengah badge logo)
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 58, 20, 20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppShadows.float,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul + subjudul rata tengah (di bawah badge logo)
                    Center(child: Text(judul, style: ts(22, 800, ls: -0.3))),
                    const SizedBox(height: 2),
                    Center(
                      child: Text(subjudul,
                          style: ts(13, 500, color: AppColors.muted)),
                    ),
                    const SizedBox(height: 18),
                    ...children,
                  ],
                ),
              ),
            ),
            // Badge logo 92 di tengah tepi atas card (top 226 − 46):
            // setengah di banner gelap, setengah di card
            Positioned(
              top: 180,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 92,
                  height: 92,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bg, // Putih, sama dengan latar logo
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 4),
                    boxShadow: AppShadows.float,
                  ),
                  child: Image.asset(
                    'assets/images/logo-app.png',
                    semanticLabel: 'Logo KopiKita',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // bottomNavigationBar: ajakan + link (bottom 36, tengah)
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(ajakan, style: ts(14, 500, color: AppColors.muted)),
              // TextButton: link (hit area tetap ≥ 44)
              TextButton(
                onPressed: onAksi,
                child: Text(aksi, style: ts(14, 800, color: AppColors.primary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
