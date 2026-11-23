import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/notifikasi.dart';
import '../../domain/repositories/notifikasi_repository.dart';
import '../firebase_kegagalan.dart';

/// NotifikasiRepositoryFirestore: users/{uid}/notifikasi/{id}.
class NotifikasiRepositoryFirestore implements NotifikasiRepository {
  CollectionReference<Map<String, dynamic>>? get _col {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifikasi');
  }

  @override
  Future<void> tambah({
    required String judul,
    required String pesan,
    required String orderId,
  }) async {
    await _col?.add({
      'judul': judul,
      'pesan': pesan,
      'orderId': orderId,
      'waktu': FieldValue.serverTimestamp(),
      'dibaca': false,
    });
  }

  @override
  Stream<List<Notifikasi>> stream() {
    final c = _col;
    if (c == null) return Stream.value(const <Notifikasi>[]);
    return c
        .orderBy('waktu', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (s) => [
            for (final d in s.docs)
              Notifikasi.fromMap(d.id, tanpaTimestamp(d.data())),
          ],
        )
        .terjemahkanGalat();
  }

  @override
  Future<void> tandaiSemuaDibaca() async {
    final c = _col;
    if (c == null) return;
    final snap = await c.where('dibaca', isEqualTo: false).get();
    if (snap.docs.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'dibaca': true});
    }
    await batch.commit();
  }
}
