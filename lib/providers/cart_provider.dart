import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/cart_item.dart';
import '../models/pesanan.dart';
import '../models/voucher.dart';
import '../models/voucher_rules.dart';
import '../services/voucher_repository.dart';

// CheckoutException: kegagalan checkout dengan pesan siap tampil (Bahasa Indonesia)
class CheckoutException implements Exception {
  final String pesan;
  const CheckoutException(this.pesan);

  @override
  String toString() => pesan;
}

class CartProvider extends ChangeNotifier {
  // STATE UTAMA: list item keranjang
  final List<CartItem> _items = [];

  // items: getter untuk mengakses _items
  List<CartItem> get items => List.unmodifiable(_items);

  // STATE: metode pesanan — true = Makan di Tempat, false = Ambil Sendiri
  bool makanDiTempat = false;
  // STATE: voucher yang diterapkan (null = tanpa voucher), sudah divalidasi
  Voucher? _voucher;
  // STATE: tarif pajak pecahan (0.10 = 10%), dibaca dari config/menu
  double tarifPajak = 0.10;

  // STATE: true selama checkout berjalan (cegah tekan dua kali)
  bool _memproses = false;
  bool get memproses => _memproses;

  // ---------- DERIVED STATE ----------
  int get totalItems => _items.fold(0, (s, e) => s + e.jumlah);
  int get subtotal => _items.fold(0, (s, e) => s + e.totalHarga);
  String? get voucher => _voucher?.kode;
  Voucher? get voucherTerpasang => _voucher;
  // alasanVoucher: non-null bila voucher terpasang tapi tak lagi memenuhi syarat
  String? get alasanVoucher => _voucher?.alasanTidakBerlaku(subtotal);
  int get diskon {
    final v = _voucher;
    if (v == null || v.alasanTidakBerlaku(subtotal) != null) return 0;
    return v.hitungDiskon(subtotal);
  }

  int get persenPajak => (tarifPajak * 100).round(); // label UI, mis. 10
  int get pajak => ((subtotal - diskon) * tarifPajak).round();
  int get total => subtotal - diskon + pajak;

  // ---------- UTILITY ----------
  static String formatRupiah(int v) {
    final str = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return 'Rp$buf';
  }

  // _kodeTanggal: "2026-10-18", dipakai mereset nomor antrean tiap hari
  static String _kodeTanggal(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // _bacaTarif: config/menu.pajak berupa pecahan (0.10); nilai > 1 dianggap persen
  static double? _bacaTarif(Object? v) {
    if (v is! num) return null;
    final d = v.toDouble();
    return d > 1 ? d / 100 : d;
  }

  // muatConfig: baca tarif pajak dari config/menu (dipanggil CartPage saat dibuka)
  Future<void> muatConfig() async {
    try {
      final snap = await FirebaseFirestore.instance.doc('config/menu').get();
      final t = _bacaTarif(snap.data()?['pajak']);
      if (t != null && t != tarifPajak) {
        tarifPajak = t;
        notifyListeners();
      }
    } catch (_) {
      // Gagal baca config: tetap pakai tarif default
    }
  }

  // ---------- METODE PESANAN ----------
  void setMakanDiTempat(bool nilai) {
    makanDiTempat = nilai;
    notifyListeners();
  }

  // ---------- VOUCHER ----------
  // terapkanVoucher: validasi ke vouchers/{kode}. null = berhasil, selain itu pesan galat.
  Future<String?> terapkanVoucher(String kode) async {
    try {
      final v = await VoucherRepository.ambil(kode);
      if (v == null) return 'Kode voucher tidak ditemukan.';
      final alasan = v.alasanTidakBerlaku(subtotal);
      if (alasan != null) return alasan;
      _voucher = v;
      notifyListeners();
      return null;
    } on FirebaseException catch (e) {
      return e.code == 'unavailable'
          ? 'Tidak ada koneksi internet.'
          : 'Gagal memeriksa voucher.';
    } catch (_) {
      return 'Gagal memeriksa voucher.';
    }
  }

  void lepasVoucher() {
    _voucher = null;
    notifyListeners();
  }

  // Hanya untuk unit test (tanpa Firestore)
  @visibleForTesting
  void pasangVoucher(Voucher? v) {
    _voucher = v;
    notifyListeners();
  }

  // ---------- CRUD ----------
  void addItem(CartItem item) {
    final i = _items.indexWhere((e) => e.kunci == item.kunci);
    if (i >= 0) {
      _items[i] = _items[i].copyWith(jumlah: _items[i].jumlah + item.jumlah);
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  void changeQuantity(String kunci, int jumlah) {
    final i = _items.indexWhere((e) => e.kunci == kunci);
    if (i < 0) return;
    if (jumlah <= 0) {
      _items.removeAt(i);
    } else {
      _items[i] = _items[i].copyWith(jumlah: jumlah);
    }
    notifyListeners();
  }

  // ---------- CHECKOUT ----------
  // Alur: validasi → transaction (cek produk habis, naikkan counters/antrean,
  // buat orders berstatus menunggu_bayar) → kosongkan keranjang.
  // Melempar CheckoutException berisi pesan siap tampil bila gagal.
  Future<void> checkout() async {
    if (_items.isEmpty || _memproses) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const CheckoutException('Sesi login berakhir. Silakan masuk lagi.');
    }

    _memproses = true;
    notifyListeners();

    try {
      final db = FirebaseFirestore.instance;
      final counterRef = db.doc('counters/antrean');
      final orderRef = db.collection('orders').doc();
      final hariIni = _kodeTanggal(DateTime.now());

      final itemsPesan = List<CartItem>.of(_items);
      final sub = subtotal, dis = diskon, paj = pajak, tot = total;
      final kodeVoucher = voucher;
      final dineIn = makanDiTempat;
      final idProduk = {
        for (final i in itemsPesan)
          if (i.productId.isNotEmpty) i.productId,
      };

      await db
          .runTransaction<void>((tx) async {
            for (final id in idProduk) {
              final snap = await tx.get(db.doc('products/$id'));
              if (!snap.exists) {
                throw const CheckoutException(
                  'Ada menu di keranjang yang sudah tidak tersedia.',
                );
              }
              if (snap.data()?['habis'] == true) {
                throw CheckoutException(
                  '${snap.data()?['nama'] ?? 'Salah satu menu'} sedang habis. Hapus dari keranjang dulu.',
                );
              }
            }
            if (kodeVoucher != null) {
              final vs = await tx.get(db.doc('vouchers/$kodeVoucher'));
              final d = vs.data();
              final alasan = (!vs.exists || d == null)
                  ? 'Voucher tidak ditemukan.'
                  : Voucher.fromMap(vs.id, d).alasanTidakBerlaku(sub);
              if (alasan != null) {
                throw CheckoutException(
                  'Voucher $kodeVoucher tidak bisa dipakai: $alasan Lepas voucher lalu coba lagi.',
                );
              }
            }
            final c = (await tx.get(counterRef)).data();

            final nomorBaru = c?['tanggal'] == hariIni
                ? ((c?['nomor'] ?? 0) as int) + 1
                : 1;
            final kode = 'A-${nomorBaru.toString().padLeft(3, '0')}';

            final pesanan = Pesanan(
              id: orderRef.id,
              uid: user.uid,
              nomor: kode,
              makanDiTempat: dineIn,
              nomorMeja: 0,
              status: 0, // menunggu_bayar
              items: itemsPesan,
              subtotal: sub,
              diskon: dis,
              pajak: paj,
              total: tot,
              voucher: kodeVoucher,
            );

            tx.set(counterRef, {'tanggal': hariIni, 'nomor': nomorBaru});
            tx.set(orderRef, {
              ...(pesanan.toMap()..remove('nomorMeja')),
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          })
          .timeout(const Duration(seconds: 15));

      _items.clear();
      _voucher = null;
    } on CheckoutException {
      rethrow;
    } on TimeoutException {
      throw const CheckoutException(
        'Koneksi lambat atau terputus. Periksa internet lalu coba lagi.',
      );
    } on FirebaseException catch (e) {
      throw CheckoutException(
        e.code == 'unavailable'
            ? 'Tidak ada koneksi internet. Coba lagi nanti.'
            : e.code == 'permission-denied'
            ? 'Tidak punya izin membuat pesanan (cek Firestore rules).'
            : 'Gagal membuat pesanan (${e.code}).',
      );
    } finally {
      _memproses = false;
      notifyListeners();
    }
  }
}
