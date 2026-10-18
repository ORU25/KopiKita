// Unit test logika murni CartProvider & aturan voucher (tanpa Firebase).
import 'package:flutter_test/flutter_test.dart';

import 'package:kopikita/models/cart_item.dart';
import 'package:kopikita/models/voucher.dart';
import 'package:kopikita/models/voucher_rules.dart';
import 'package:kopikita/providers/cart_provider.dart';

CartItem _item({int harga = 25000, int jumlah = 2, String nama = 'Kopi'}) =>
    CartItem(nama: nama, harga: harga, jumlah: jumlah);

const _persen20 =
    Voucher('KOPIKITA20', 'Diskon 20%', nilai: 20, minBelanja: 50000);
const _potong5k = Voucher('HEMAT5RB', 'Potongan Rp5.000',
    tipe: 'potongan', nilai: 5000);

void main() {
  group('Total tanpa voucher', () {
    test('subtotal + pajak 10%', () {
      final c = CartProvider()..addItem(_item()); // 50.000
      expect(c.subtotal, 50000);
      expect(c.diskon, 0);
      expect(c.pajak, 5000);
      expect(c.total, 55000);
    });

    test('tarif pajak mengikuti config (pecahan)', () {
      final c = CartProvider()
        ..tarifPajak = 0.11
        ..addItem(_item()); // 50.000 × 11% = 5.500
      expect(c.pajak, 5500);
      expect(c.total, 55500);
    });
  });

  group('Voucher', () {
    test('persen: diskon dihitung dari subtotal, pajak setelah diskon', () {
      final c = CartProvider()
        ..addItem(_item())
        ..pasangVoucher(_persen20);
      expect(c.diskon, 10000);
      expect(c.pajak, 4000); // (50.000 − 10.000) × 10%
      expect(c.total, 44000);
    });

    test('potongan rupiah', () {
      final c = CartProvider()
        ..addItem(_item())
        ..pasangVoucher(_potong5k);
      expect(c.diskon, 5000);
      expect(c.pajak, 4500);
      expect(c.total, 49500);
    });

    test('potongan tidak melebihi subtotal', () {
      const besar =
          Voucher('BESAR', 'x', tipe: 'potongan', nilai: 100000);
      final c = CartProvider()
        ..addItem(_item())
        ..pasangVoucher(besar);
      expect(c.diskon, 50000);
      expect(c.total, 0);
    });

    test('di bawah minBelanja: diskon 0 dan ada alasan', () {
      final c = CartProvider()
        ..addItem(_item(harga: 20000, jumlah: 1))
        ..pasangVoucher(_persen20);
      expect(c.diskon, 0);
      expect(c.alasanVoucher, contains('Minimal belanja Rp50.000'));
    });

    test('voucher tidak aktif ditolak', () {
      const mati = Voucher('MATI', 'x', nilai: 10, aktif: false);
      expect(mati.alasanTidakBerlaku(100000), isNotNull);
    });

    test('voucher kedaluwarsa ditolak, belum kedaluwarsa diterima', () {
      final v = Voucher('EXP', 'x',
          nilai: 10, berlakuSampai: DateTime(2026, 10, 31));
      expect(v.alasanTidakBerlaku(1000, sekarang: DateTime(2026, 11, 1)),
          contains('kedaluwarsa'));
      expect(v.alasanTidakBerlaku(1000, sekarang: DateTime(2026, 10, 20)),
          isNull);
    });

    test('lepasVoucher mengembalikan diskon ke 0', () {
      final c = CartProvider()
        ..addItem(_item())
        ..pasangVoucher(_persen20)
        ..lepasVoucher();
      expect(c.voucher, isNull);
      expect(c.diskon, 0);
    });
  });

  group('Keranjang & validasi', () {
    test('item dengan kunci sama digabung', () {
      final c = CartProvider()
        ..addItem(_item(jumlah: 1))
        ..addItem(_item(jumlah: 2));
      expect(c.items.length, 1);
      expect(c.totalItems, 3);
    });

    test('Makan di tempat wajib nomor meja', () {
      final c = CartProvider()..setMakanDiTempat(true);
      expect(c.kesalahanMeja, isNotNull);
      c.setNomorMeja(7);
      expect(c.kesalahanMeja, isNull);
      c.setMakanDiTempat(false);
      c.setNomorMeja(null);
      expect(c.kesalahanMeja, isNull); // Ambil sendiri: meja tidak wajib
    });

    test('checkout keranjang kosong: tidak melakukan apa-apa', () async {
      final c = CartProvider();
      await c.checkout(); // tidak melempar, tidak menyentuh Firebase
      expect(c.items, isEmpty);
    });

    test('checkout makan di tempat tanpa meja → CheckoutException', () {
      final c = CartProvider()
        ..addItem(_item())
        ..setMakanDiTempat(true);
      expect(() => c.checkout(), throwsA(isA<CheckoutException>()));
    });
  });
}