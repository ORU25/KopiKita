import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/pesanan.dart';
import 'user_repo.dart';

/// OrderRepository: akses koleksi orders/{id} milik user yang sedang login.
/// Pesanan Aktif & Riwayat memakai stream ini lewat StreamBuilder —
/// tanpa provider baru (lihat PEMBAGIAN_TUGAS.md aturan kerja tim).
///
/// ponytail: filter status dikerjakan di klien (bukan whereIn) supaya tidak
/// butuh composite index; katalog pesanan per user kecil jadi aman.
class OrderRepository {
  static final _db = FirebaseFirestore.instance;

  /// streamAktif: pesanan user yang belum selesai/batal, terbaru dulu.
  static Stream<List<Pesanan>> streamAktif() {
    final uid = UserRepo.uid;
    if (uid == null) return Stream.value(const <Pesanan>[]);
    return _db
        .collection('orders')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snap) {
      final daftar = <Pesanan>[];
      for (final d in snap.docs) {
        try {
          final p = Pesanan.fromMap(d.id, d.data());
          if (statusKode[p.status] != 'selesai' && !p.batal) daftar.add(p);
        } catch (_) {
          // Dokumen rusak dilewati, tidak menjatuhkan layar Pesanan
        }
      }
      daftar.sort((a, b) {
        final ca = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final cb = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return cb.compareTo(ca); // Terbaru dulu
      });
      return daftar;
    });
  }

  /// streamRiwayat: pesanan user yang sudah `selesai` atau `batal`,
  /// terbaru dulu. Dikelompokkan per bulan di UI (orders_page.dart).
  static Stream<List<Pesanan>> streamRiwayat() {
    final uid = UserRepo.uid;
    if (uid == null) return Stream.value(const <Pesanan>[]);
    return _db
        .collection('orders')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snap) {
      final daftar = <Pesanan>[];
      for (final d in snap.docs) {
        try {
          final p = Pesanan.fromMap(d.id, d.data());
          if (statusKode[p.status] == 'selesai' || p.batal) daftar.add(p);
        } catch (_) {
          // Dokumen rusak dilewati
        }
      }
      daftar.sort((a, b) {
        final ca = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final cb = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return cb.compareTo(ca);
      });
      return daftar;
    });
  }

  /// batalkan: ubah status pesanan ke `batal` hanya bila masih `menunggu_bayar`.
  /// Pakai transaction agar tidak menimpa perubahan staf yang masuk bersamaan.
  /// Melempar `StateError` bila status sudah berubah — UI menampilkan pesan.
  static Future<void> batalkan(String orderId) async {
    if (orderId.isEmpty) return;
    final ref = _db.collection('orders').doc(orderId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (data == null) {
        throw StateError('Pesanan tidak ditemukan.');
      }
      final status = data['status'] as String? ?? 'menunggu_bayar';
      if (status != 'menunggu_bayar') {
        throw StateError(
          'Pesanan sudah diproses kasir dan tidak bisa dibatalkan.',
        );
      }
      tx.update(ref, {
        'status': 'batal',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}