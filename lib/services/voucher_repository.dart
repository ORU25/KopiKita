import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/voucher.dart';

/// VoucherRepository: akses koleksi vouchers/{kode}.
/// Dipakai Keranjang (validasi), sheet Ganti voucher, Akun, dan Promo & Voucher.
class VoucherRepository {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Ambil satu voucher berdasarkan kode (huruf besar). Null bila tidak ada.
  static Future<Voucher?> ambil(String kode) async {
    final id = kode.trim().toUpperCase();
    if (id.isEmpty) return null;
    final snap = await _db.collection('vouchers').doc(id).get();
    final data = snap.data();
    if (!snap.exists || data == null) return null;
    return Voucher.fromMap(snap.id, data);
  }

  /// Ambil beberapa voucher sekaligus; kode yang tidak ada dilewati.
  static Future<List<Voucher>> ambilBanyak(Iterable<String> kode) async {
    final hasil = await Future.wait(kode.map(ambil));
    return [for (final v in hasil) ?v];
  }

  /// Stream (realtime) voucher milik user menurut daftar kode di users/{uid}.voucher.
  /// whereIn Firestore maksimal 30 nilai, cukup untuk voucher per pengguna.
  static Stream<List<Voucher>> streamKode(List<String> kode) {
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
          hasil.add(Voucher.fromMap(d.id, d.data()));
        } catch (_) {
          // Dokumen rusak dilewati
        }
      }
      // Urutan mengikuti urutan kode di dokumen user
      hasil.sort(
          (a, b) => daftar.indexOf(a.kode).compareTo(daftar.indexOf(b.kode)));
      return hasil;
    });
  }
}