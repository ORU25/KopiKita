import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../domain/repositories/push_repository.dart';

/// PushRepositoryFcm: simpan token FCM HP ini di users/{uid}.fcmTokens agar
/// kopikita-web (/api/notif) bisa mengirim push saat app ditutup.
/// Notif dengan payload `notification` ditampilkan otomatis oleh Android
/// saat app di background/ditutup; saat app terbuka, lonceng Beranda yang dipakai.
class PushRepositoryFcm implements PushRepository {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  StreamSubscription<String>? _sub;
  String? _token;

  /// Dipanggil saat login. TIDAK menampilkan dialog izin: hanya mendaftarkan
  /// token jika izin sudah ada. Dialog izin diminta lewat [mintaIzin] saat
  /// pengguna menyalakan "Notifikasi pesanan" (izin diminta saat fitur dipakai).
  @override
  Future<void> daftar() async {
    if (_sub != null) return;
    _sub = _fcm.onTokenRefresh.listen(_simpan);
    try {
      final s = await _fcm.getNotificationSettings();
      if (!_diizinkan(s.authorizationStatus)) return;
      final t = await _fcm.getToken();
      if (t != null) await _simpan(t);
    } catch (_) {
      // Tanpa Play Services: app tetap jalan, hanya tanpa push
    }
  }

  /// Menampilkan dialog izin notifikasi (Android 13+) lalu mendaftarkan token.
  /// Mengembalikan true jika diizinkan.
  @override
  Future<bool> mintaIzin() async {
    try {
      final s = await _fcm.requestPermission();
      if (!_diizinkan(s.authorizationStatus)) return false;
      final t = await _fcm.getToken();
      if (t != null) await _simpan(t);
      return true;
    } catch (_) {
      return false;
    }
  }

  bool _diizinkan(AuthorizationStatus s) =>
      s == AuthorizationStatus.authorized ||
      s == AuthorizationStatus.provisional;

  Future<void> _simpan(String token) async {
    _token = token;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'fcmTokens': FieldValue.arrayUnion([token]),
    });
  }

  /// Hapus token HP ini dari akun. Panggil SEBELUM signOut (butuh izin tulis).
  @override
  Future<void> lepas() async {
    await _sub?.cancel();
    _sub = null;
    final t = _token;
    _token = null;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (t == null || uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmTokens': FieldValue.arrayRemove([t]),
      });
    } catch (_) {}
  }
}
