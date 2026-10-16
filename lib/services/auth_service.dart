import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static User? get user => _auth.currentUser;

  /// Login ke Firebase Auth, lalu pastikan dokumen users/{uid} ada.
  static Future<void> masuk({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = cred.user!.uid;
    final ref = _db.collection('users').doc(uid);
    final snap = await ref.get();

    // Fallback: kalau user Auth ada tapi dokumen Firestore hilang.
    if (!snap.exists) {
      await ref.set({
        'nama': cred.user!.displayName ?? email.trim().split('@').first,
        'email': cred.user!.email ?? email.trim(),
        'role': 'pelanggan',
        'favorit': <String>[],
        'voucher': <String>[],
        'notifikasi': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Daftar akun baru + buat dokumen users/{uid}.
  static Future<void> daftar({
    required String nama,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = cred.user!;
    await user.updateDisplayName(nama.trim());

    try {
      await _db.collection('users').doc(user.uid).set({
        'nama': nama.trim(),
        'email': user.email ?? email.trim(),
        'role': 'pelanggan',
        'favorit': <String>[],
        'voucher': ['KOPIKITA20', 'HEMAT5RB'],
        'notifikasi': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Hindari akun Auth tanpa dokumen users jika Firestore gagal.
      try {
        await user.delete();
      } catch (_) {
        await _auth.signOut();
      }
      rethrow;
    }
  }

  static Future<void> keluar() => _auth.signOut();

  /// Terjemahkan error Firebase ke pesan Indonesia.
  static String pesanError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'Format email tidak valid.';
        case 'user-disabled':
          return 'Akun ini dinonaktifkan.';
        case 'user-not-found':
          return 'Akun tidak ditemukan.';
        case 'wrong-password':
          return 'Kata sandi salah.';
        case 'invalid-credential':
        case 'invalid-login-credentials':
          return 'Email atau kata sandi salah.';
        case 'email-already-in-use':
          return 'Email sudah terdaftar. Silakan masuk.';
        case 'weak-password':
          return 'Kata sandi minimal 6 karakter.';
        case 'network-request-failed':
          return 'Koneksi internet bermasalah.';
        case 'too-many-requests':
          return 'Terlalu banyak percobaan. Coba lagi nanti.';
        default:
          return 'Gagal: ${e.message ?? e.code}';
      }
    }

    if (e is FirebaseException) {
      if (e.code == 'permission-denied') {
        return 'Akses Firestore ditolak. Periksa rules.';
      }
      return 'Firestore error: ${e.message ?? e.code}';
    }

    return 'Terjadi kesalahan: $e';
  }
}