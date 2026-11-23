// Tampilan keadaan data: memuat, error, kosong (DESIGN.md 3.3a)
// Dipakai Menu, Beranda, Cari, dan Favorit agar semua keadaan konsisten.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// pesanErrorData: pesan Bahasa Indonesia yang ramah untuk error Firestore
String pesanErrorData(Object e) {
  if (e is FirebaseException) {
    if (e.code == 'permission-denied') {
      return 'Akses ke data ditolak. Coba keluar lalu masuk lagi.';
    }
    if (e.code == 'unavailable') {
      return 'Tidak bisa terhubung ke server. Periksa koneksi internetmu.';
    }
  }
  return 'Terjadi kesalahan saat memuat data. Coba lagi sebentar lagi.';
}

// keadaanStream: pilih tampilan untuk snapshot stream yang BELUM berisi data siap pakai.
// Mengembalikan null bila data ada dan tidak kosong → pemanggil menampilkan datanya.
// Error hanya ditampilkan setelah stream benar-benar gagal; saat "Coba lagi"
// (stream baru, status waiting) tampil Memuat dulu, bukan error lama.
Widget? keadaanStream<T>(
  AsyncSnapshot<T> snap, {
  required VoidCallback onCoba,
  required bool Function(T data) kosong,
  required Widget tampilanKosong,
}) {
  if (snap.hasError && snap.connectionState != ConnectionState.waiting) {
    return ErrorView(pesan: pesanErrorData(snap.error!), onCoba: onCoba);
  }
  if (!snap.hasData) return const LoadingView();
  if (kosong(snap.requireData)) return tampilanKosong;
  return null;
}

// LoadingView: indikator memuat di tengah area
class LoadingView extends StatelessWidget {
  final String pesan; // Teks di bawah indikator
  const LoadingView({super.key, this.pesan = 'Memuat…'});

  @override
  Widget build(BuildContext context) {
    // Center + Padding: tetap rapi di dalam Column/sliver maupun layar penuh
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(pesan, style: ts(13, 500, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

// EmptyView: keadaan kosong (ikon dalam lingkaran tint + judul + penjelasan)
class EmptyView extends StatelessWidget {
  final IconData icon; // Ikon ilustrasi
  final String judul; // Judul 16/800
  final String pesan; // Penjelasan 13 muted
  const EmptyView({
    super.key,
    required this.icon,
    required this.judul,
    required this.pesan,
  });

  @override
  Widget build(BuildContext context) =>
      _KeadaanKosong(icon: icon, judul: judul, pesan: pesan);
}

// ErrorView: keadaan gagal memuat + tombol "Coba lagi"
class ErrorView extends StatelessWidget {
  final String pesan; // Penjelasan error (Bahasa Indonesia)
  final VoidCallback onCoba; // Dipanggil saat "Coba lagi" ditekan
  const ErrorView({super.key, required this.pesan, required this.onCoba});

  @override
  Widget build(BuildContext context) {
    return _KeadaanKosong(
      icon: Icons.cloud_off_rounded,
      judul: 'Gagal memuat',
      pesan: pesan,
      aksi: FilledButton(
        onPressed: onCoba,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          minimumSize: const Size(160, 44), // Target sentuh minimal 44
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text('Coba lagi', style: ts(14, 700, color: Colors.white)),
      ),
    );
  }
}

// _KeadaanKosong: kerangka bersama EmptyView & ErrorView
class _KeadaanKosong extends StatelessWidget {
  final IconData icon;
  final String judul;
  final String pesan;
  final Widget? aksi; // Tombol opsional di bawah teks
  const _KeadaanKosong({
    required this.icon,
    required this.judul,
    required this.pesan,
    this.aksi,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lingkaran 72 latar tint, ikon 32 primary
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.tint,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(judul, textAlign: TextAlign.center, style: ts(16, 800)),
            const SizedBox(height: 6),
            Text(
              pesan,
              textAlign: TextAlign.center,
              style: ts(13, 500, color: AppColors.muted, height: 1.4),
            ),
            if (aksi != null) ...[const SizedBox(height: 18), aksi!],
          ],
        ),
      ),
    );
  }
}
