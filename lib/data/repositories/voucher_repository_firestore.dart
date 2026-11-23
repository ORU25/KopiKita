import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/voucher.dart';
import '../../domain/hasil.dart';
import '../../domain/repositories/voucher_repository.dart';
import '../firebase_kegagalan.dart';

/// VoucherRepositoryFirestore: koleksi vouchers/{kode}.
class VoucherRepositoryFirestore implements VoucherRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  Future<Hasil<Voucher?>> ambil(String kode) => coba(() async {
    final id = kode.trim().toUpperCase();
    if (id.isEmpty) return null;
    final snap = await _db.collection('vouchers').doc(id).get();
    final data = snap.data();
    if (!snap.exists || data == null) return null;
    return Voucher.fromMap(snap.id, tanpaTimestamp(data));
  });

  /// whereIn Firestore maksimal 30 nilai, cukup untuk voucher per pengguna.
  @override
  Stream<List<Voucher>> streamKode(List<String> kode) {
    if (kode.isEmpty) return Stream.value(const <Voucher>[]);
    final daftar = kode.take(30).toList();
    return _db
        .collection('vouchers')
        .where(FieldPath.documentId, whereIn: daftar)
        .snapshots()
        .map((snap) {
          final hasil = <Voucher>[];
          for (final d in snap.docs) {
            try {
              hasil.add(Voucher.fromMap(d.id, tanpaTimestamp(d.data())));
            } catch (_) {
              // Dokumen rusak dilewati
            }
          }
          // Urutan mengikuti urutan kode di dokumen user
          hasil.sort(
            (a, b) => daftar.indexOf(a.kode).compareTo(daftar.indexOf(b.kode)),
          );
          return hasil;
        })
        .terjemahkanGalat();
  }
}
