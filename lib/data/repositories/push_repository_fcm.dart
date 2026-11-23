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
  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  StreamSubscription<String>? _sub;
  String? _token;

  Future<void> _tulis(Object nilai) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'fcmTokens': nilai,
    });
  }

  Future<void> _simpan(String token) async {
    _token = token;
    await _tulis(FieldValue.arrayUnion([token]));
  }

  @override
  Future<void> daftar() async {
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

  @override
  Future<void> lepas() async {
    await _sub?.cancel();
    _sub = null;
    final t = _token;
    _token = null;
    if (t == null) return;
    try {
      await _tulis(FieldValue.arrayRemove([t]));
    } catch (_) {}
  }
}
