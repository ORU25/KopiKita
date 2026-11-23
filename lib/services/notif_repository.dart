import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_repo.dart';

class NotifRepository {
  static final _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>>? get _col {
    final uid = UserRepo.uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('notifikasi');
  }

  /// Simpan notifikasi baru ke Firestore.
  static Future<void> tambah({
    required String judul,
    required String pesan,
    required String orderId,
  }) async {
    final c = _col;
    if (c == null) return;
    await c.add({
      'judul': judul,
      'pesan': pesan,
      'orderId': orderId,
      'waktu': FieldValue.serverTimestamp(),
      'dibaca': false,
    });
  }

  /// Stream daftar notifikasi (terbaru di atas).
  static Stream<QuerySnapshot<Map<String, dynamic>>>? stream() {
    final c = _col;
    if (c == null) return null;
    return c.orderBy('waktu', descending: true).limit(50).snapshots();
  }

  /// Stream jumlah notifikasi yang belum dibaca (untuk badge merah).
  static Stream<int>? streamBelumDibaca() {
    final c = _col;
    if (c == null) return null;
    return c.where('dibaca', isEqualTo: false).snapshots().map((s) => s.docs.length);
  }

  /// Tandai semua notifikasi sebagai sudah dibaca.
  static Future<void> tandaiSemuaDibaca() async {
    final c = _col;
    if (c == null) return;
    final snap = await c.where('dibaca', isEqualTo: false).get();
    if (snap.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'dibaca': true});
    }
    await batch.commit();
  }
}