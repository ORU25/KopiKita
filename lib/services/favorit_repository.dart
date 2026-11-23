import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_repo.dart';

/// FavoritRepository: daftar favorit user di users/{uid}.favorit ([productId]).
/// Membaca lewat UserRepo.stream() (milik P2), menulis langsung ke dokumen user
/// dengan arrayUnion/arrayRemove sehingga aman dari tulis-timpa antar perangkat.
class FavoritRepository {
  /// Stream himpunan productId favorit. Kosong bila belum login.
  static Stream<Set<String>> stream() {
    final s = UserRepo.stream();
    if (s == null) return Stream.value(const <String>{});
    return s.map((snap) => idDari(snap.data()));
  }

  /// idDari: ambil field `favorit` dari data user (null-safe).
  static Set<String> idDari(Map<String, dynamic>? d) {
    final v = d?['favorit'];
    if (v is List) return v.whereType<String>().toSet();
    return const <String>{};
  }

  /// set: tambah (favorit = true) atau hapus (false) satu produk dari favorit.
  /// Future baru selesai saat server mengonfirmasi, tetapi stream langsung
  /// berubah dari cache lokal sehingga UI terasa instan.
  static Future<void> set(String productId, {required bool favorit}) async {
    final uid = UserRepo.uid;
    if (uid == null || productId.isEmpty) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'favorit': favorit
          ? FieldValue.arrayUnion([productId])
          : FieldValue.arrayRemove([productId]),
    }, SetOptions(merge: true));
  }
}
