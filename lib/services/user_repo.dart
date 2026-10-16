import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// UserRepo: akses dokumen users/{uid} tanpa provider.
/// Beranda, Akun, dan Notifikasi pakai StreamBuilder di sini.
class UserRepo {
  static final _db = FirebaseFirestore.instance;

  /// UID user yang sedang login, atau null.
  static String? get uid => FirebaseAuth.instance.currentUser?.uid;

  /// Stream dokumen users/{uid}. Null bila belum login.
  static Stream<DocumentSnapshot<Map<String, dynamic>>>? stream() {
    final id = uid;
    if (id == null) return null;
    return _db.collection('users').doc(id).snapshots();
  }

  /// Ambil data users/{uid} sekali (untuk kasus yang butuh nilai sekarang).
  static Future<Map<String, dynamic>?> ambil() async {
    final id = uid;
    if (id == null) return null;
    final snap = await _db.collection('users').doc(id).get();
    return snap.data();
  }

  /// Update dokumen users/{uid} (mis. ganti nama, toggle notifikasi).
  static Future<void> update(Map<String, dynamic> data) async {
    final id = uid;
    if (id == null) return;
    await _db.collection('users').doc(id).update(data);
  }

  // ---- Getter aman dari Map (null-safe) ----
  static String namaDari(Map<String, dynamic>? d) {
    final v = d?['nama'];
    return v is String ? v : '';
  }

  static String emailDari(Map<String, dynamic>? d) {
    final v = d?['email'];
    return v is String ? v : (FirebaseAuth.instance.currentUser?.email ?? '');
  }

  static String roleDari(Map<String, dynamic>? d) {
    final v = d?['role'];
    return v is String ? v : 'pelanggan';
  }

  static List<String> voucherDari(Map<String, dynamic>? d) {
    final v = d?['voucher'];
    if (v is List) return v.whereType<String>().toList();
    return const [];
  }

  static bool notifikasiDari(Map<String, dynamic>? d) {
    final v = d?['notifikasi'];
    return v is bool ? v : true;
  }
}