import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/hasil.dart';

// Penerjemah SATU-SATUNYA dari exception Firebase ke bahasa Kegagalan domain.
// Lapisan UI tidak pernah melihat FirebaseException.

Kegagalan kegagalanDari(Object e) {
  if (e is Kegagalan) return e;
  // Timeout = koneksi lambat/terputus
  if (e is TimeoutException) return const TanpaKoneksi();
  if (e is FirebaseAuthException) {
    return switch (e.code) {
      'wrong-password' ||
      'invalid-credential' ||
      'invalid-login-credentials' ||
      'user-not-found' => const KredensialSalah(),
      'network-request-failed' => const TanpaKoneksi(),
      'invalid-email' => const AturanDilanggar('Format email tidak valid.'),
      'user-disabled' => const AturanDilanggar('Akun ini dinonaktifkan.'),
      'email-already-in-use' => const AturanDilanggar(
        'Email sudah terdaftar. Silakan masuk.',
      ),
      'weak-password' => const AturanDilanggar(
        'Kata sandi minimal 6 karakter.',
      ),
      'too-many-requests' => const AturanDilanggar(
        'Terlalu banyak percobaan. Coba lagi nanti.',
      ),
      _ => LayananBermasalah(e.code),
    };
  }
  if (e is FirebaseException) {
    return switch (e.code) {
      'unavailable' => const TanpaKoneksi(),
      'permission-denied' => const TanpaIzin(),
      _ => LayananBermasalah(e.code),
    };
  }
  return LayananBermasalah('$e');
}

/// coba: jalankan aksi; exception apa pun menjadi Gagal(Kegagalan).
Future<Hasil<T>> coba<T>(Future<T> Function() aksi) async {
  try {
    return Berhasil(await aksi());
  } catch (e) {
    return Gagal(kegagalanDari(e));
  }
}

extension TerjemahkanGalat<T> on Stream<T> {
  /// Galat stream diteruskan sebagai Kegagalan (bukan FirebaseException).
  Stream<T> terjemahkanGalat() =>
      handleError((Object e, StackTrace st) => throw kegagalanDari(e));
}

/// tanpaTimestamp: ubah nilai Timestamp (tingkat atas) menjadi DateTime agar
/// entitas domain tidak perlu mengenal tipe Firestore.
Map<String, dynamic> tanpaTimestamp(Map<String, dynamic> m) => {
  for (final e in m.entries)
    e.key: e.value is Timestamp ? (e.value as Timestamp).toDate() : e.value,
};
