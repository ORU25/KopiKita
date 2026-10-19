import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'user_repo.dart';

/// PushService: simpan token FCM HP ini di users/{uid}.fcmTokens agar
/// kopikita-web (/api/notif) bisa mengirim push saat app ditutup.
/// Notif dengan payload `notification` ditampilkan otomatis oleh Android
/// saat app di background/ditutup; saat app terbuka, lonceng Beranda yang dipakai.
class PushService {
  static final _fcm = FirebaseMessaging.instance;
  static StreamSubscription<String>? _sub;
  static String? _token;

  static Future<void> daftar() async {
    if (_sub != null) return;
    _sub = _fcm.onTokenRefresh.listen(_simpan);
    try {
      await _fcm.requestPermission(); // Android 13+: dialog izin notifikasi
      final t = await _fcm.getToken();
      if (t != null) await _simpan(t);
    } catch (_) {
      // Tanpa Play Services / izin ditolak: app tetap jalan, hanya tanpa push
    }
  }

  static Future<void> _simpan(String token) async {
    _token = token;
    await UserRepo.update({
      'fcmTokens': FieldValue.arrayUnion([token]),
    });
  }

  /// Hapus token HP ini dari akun. Panggil SEBELUM signOut (butuh izin tulis).
  static Future<void> lepas() async {
    await _sub?.cancel();
    _sub = null;
    final t = _token;
    _token = null;
    if (t == null) return;
    try {
      await UserRepo.update({
        'fcmTokens': FieldValue.arrayRemove([t]),
      });
    } catch (_) {}
  }
}
