import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/hasil.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/use_cases/batalkan_pesanan.dart';
import '../../models/pesanan.dart';
import '../../services/user_repo.dart';

// Sinyal internal di dalam transaction: aturan bisnis dilanggar.
// Diterjemahkan menjadi Gagal(AturanDilanggar) di batalkan(); tidak keluar dari sini.
class _AturanDilanggarException implements Exception {
  final String alasan;
  const _AturanDilanggarException(this.alasan);
}

/// OrderRepositoryFirestore: implementasi OrderRepository di atas koleksi
/// orders/{id} milik user yang sedang login.
/// Pesanan Aktif & Riwayat memakai stream ini lewat StreamBuilder.
///
/// ponytail: filter status dikerjakan di klien (bukan whereIn) supaya tidak
/// butuh composite index; katalog pesanan per user kecil jadi aman.
class OrderRepositoryFirestore implements OrderRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  Stream<List<Pesanan>> streamAktif() {
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

  /// Dikelompokkan per bulan di UI (orders_page.dart).
  @override
  Stream<List<Pesanan>> streamRiwayat() {
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

  /// Pakai transaction agar tidak menimpa perubahan staf yang masuk bersamaan.
  /// Exception Firebase diterjemahkan menjadi Kegagalan di sini, satu-satunya tempat.
  @override
  Future<Hasil<void>> batalkan(String orderId) async {
    if (orderId.isEmpty) return const Berhasil<void>(null);
    final ref = _db.collection('orders').doc(orderId);
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final data = snap.data();
        if (data == null) {
          throw const _AturanDilanggarException('Pesanan tidak ditemukan.');
        }
        final status = data['status'] as String? ?? 'menunggu_bayar';
        if (status != 'menunggu_bayar') {
          throw const _AturanDilanggarException(alasanPesananSudahDiproses);
        }
        tx.update(ref, {
          'status': 'batal',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      return const Berhasil<void>(null);
    } on _AturanDilanggarException catch (e) {
      return Gagal<void>(AturanDilanggar(e.alasan));
    } on FirebaseException catch (e) {
      return Gagal<void>(switch (e.code) {
        'unavailable' => const TanpaKoneksi(),
        'permission-denied' => const TanpaIzin(),
        _ => LayananBermasalah(e.code),
      });
    }
  }
}
