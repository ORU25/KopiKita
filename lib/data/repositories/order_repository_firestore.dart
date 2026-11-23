import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/pesanan.dart';
import '../../domain/entities/voucher.dart';
import '../../domain/entities/voucher_rules.dart';
import '../../domain/hasil.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/use_cases/batalkan_pesanan.dart';
import '../firebase_kegagalan.dart';

/// OrderRepositoryFirestore: implementasi OrderRepository di atas koleksi
/// orders/{id} milik user yang sedang login.
///
/// ponytail: filter status dikerjakan di klien (bukan whereIn) supaya tidak
/// butuh composite index; katalog pesanan per user kecil jadi aman.
class OrderRepositoryFirestore implements OrderRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // _stream: pesanan milik user yang lolos [filter], terbaru dulu.
  Stream<List<Pesanan>> _stream(bool Function(Pesanan p) filter) {
    final uid = _uid;
    if (uid == null) return Stream.value(const <Pesanan>[]);
    return _db
        .collection('orders')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snap) {
          final daftar = <Pesanan>[];
          for (final d in snap.docs) {
            try {
              final p = Pesanan.fromMap(d.id, tanpaTimestamp(d.data()));
              if (filter(p)) daftar.add(p);
            } catch (_) {
              // Dokumen rusak dilewati, tidak menjatuhkan layar Pesanan
            }
          }
          daftar.sort((a, b) {
            final ca = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final cb = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return cb.compareTo(ca);
          });
          return daftar;
        })
        .terjemahkanGalat();
  }

  @override
  Stream<List<Pesanan>> streamAktif() =>
      _stream((p) => statusKode[p.status] != 'selesai' && !p.batal);

  @override
  Stream<List<Pesanan>> streamRiwayat() =>
      _stream((p) => statusKode[p.status] == 'selesai' || p.batal);

  // _kodeTanggal: "2026-10-18", dipakai mereset nomor antrean tiap hari
  static String _kodeTanggal(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Transaction: cek produk habis & voucher, naikkan counters/antrean, lalu
  /// buat orders berstatus menunggu_bayar. Semua atau tidak sama sekali.
  @override
  Future<Hasil<String>> buat(Pesanan draf) async {
    final uid = _uid;
    if (uid == null) {
      return const Gagal(
        AturanDilanggar('Sesi login berakhir. Silakan masuk lagi.'),
      );
    }
    final counterRef = _db.doc('counters/antrean');
    final orderRef = _db.collection('orders').doc();
    final hariIni = _kodeTanggal(DateTime.now());
    final idProduk = {
      for (final i in draf.items)
        if (i.productId.isNotEmpty) i.productId,
    };

    final hasil = await coba(
      () => _db
          .runTransaction<String>((tx) async {
            for (final id in idProduk) {
              final snap = await tx.get(_db.doc('products/$id'));
              if (!snap.exists) {
                throw const AturanDilanggar(
                  'Ada menu di keranjang yang sudah tidak tersedia.',
                );
              }
              if (snap.data()?['habis'] == true) {
                throw AturanDilanggar(
                  '${snap.data()?['nama'] ?? 'Salah satu menu'} sedang habis. Hapus dari keranjang dulu.',
                );
              }
            }
            final kodeVoucher = draf.voucher;
            if (kodeVoucher != null) {
              final vs = await tx.get(_db.doc('vouchers/$kodeVoucher'));
              final d = vs.data();
              final alasan = (!vs.exists || d == null)
                  ? 'Voucher tidak ditemukan.'
                  : Voucher.fromMap(
                      vs.id,
                      tanpaTimestamp(d),
                    ).alasanTidakBerlaku(draf.subtotal);
              if (alasan != null) {
                throw AturanDilanggar(
                  'Voucher $kodeVoucher tidak bisa dipakai: $alasan Lepas voucher lalu coba lagi.',
                );
              }
            }
            final c = (await tx.get(counterRef)).data();
            final nomorBaru = c?['tanggal'] == hariIni
                ? ((c?['nomor'] ?? 0) as int) + 1
                : 1;
            final nomor = 'A-${nomorBaru.toString().padLeft(3, '0')}';

            final pesanan = Pesanan(
              id: orderRef.id,
              uid: uid,
              nomor: nomor,
              makanDiTempat: draf.makanDiTempat,
              nomorMeja: 0,
              status: 0, // menunggu_bayar
              items: draf.items,
              subtotal: draf.subtotal,
              diskon: draf.diskon,
              pajak: draf.pajak,
              total: draf.total,
              voucher: kodeVoucher,
            );

            tx.set(counterRef, {'tanggal': hariIni, 'nomor': nomorBaru});
            tx.set(orderRef, {
              ...(pesanan.toMap()..remove('nomorMeja')),
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
            return nomor;
          })
          .timeout(const Duration(seconds: 15)),
    );
    return hasil;
  }

  /// Pakai transaction agar tidak menimpa perubahan staf yang masuk bersamaan.
  @override
  Future<Hasil<void>> batalkan(String orderId) async {
    if (orderId.isEmpty) return const Berhasil<void>(null);
    final ref = _db.collection('orders').doc(orderId);
    return coba(
      () => _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final data = snap.data();
        if (data == null) {
          throw const AturanDilanggar('Pesanan tidak ditemukan.');
        }
        final status = data['status'] as String? ?? 'menunggu_bayar';
        if (status != 'menunggu_bayar') {
          throw const AturanDilanggar(alasanPesananSudahDiproses);
        }
        tx.update(ref, {
          'status': 'batal',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }),
    );
  }
}
