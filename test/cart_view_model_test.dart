// Unit test logika murni CartViewModel & aturan voucher (tanpa Firebase).
import 'package:flutter_test/flutter_test.dart';

import 'package:kopikita/domain/entities/cart_item.dart';
import 'package:kopikita/domain/entities/voucher.dart';
import 'package:kopikita/domain/entities/voucher_rules.dart';
import 'package:kopikita/domain/entities/menu_config.dart';
import 'package:kopikita/domain/hasil.dart';
import 'package:kopikita/viewmodels/cart_view_model.dart';

import 'fakes/fake_order_repository.dart';
import 'fakes/fakes.dart';

CartItem _item({int harga = 25000, int jumlah = 2, String nama = 'Kopi'}) =>
    CartItem(nama: nama, harga: harga, jumlah: jumlah);

const _persen20 = Voucher(
  'KOPIKITA20',
  'Diskon 20%',
  nilai: 20,
  minBelanja: 50000,
);
const _potong5k = Voucher(
  'HEMAT5RB',
  'Potongan Rp5.000',
  tipe: 'potongan',
  nilai: 5000,
);

void main() {
  group('Total tanpa voucher', () {
    test('subtotal + pajak 10%', () {
      final c = buatCart()..addItem(_item()); // 50.000
      expect(c.subtotal, 50000);
      expect(c.diskon, 0);
      expect(c.pajak, 5000);
      expect(c.total, 55000);
    });

    test('tarif pajak mengikuti config (pecahan)', () {
      final c = buatCart()
        ..tarifPajak = 0.11
        ..addItem(_item()); // 50.000 × 11% = 5.500
      expect(c.pajak, 5500);
      expect(c.total, 55500);
    });
  });

  group('Voucher', () {
    test('persen: diskon dihitung dari subtotal, pajak setelah diskon', () {
      final c = buatCart()
        ..addItem(_item())
        ..pasangVoucher(_persen20);
      expect(c.diskon, 10000);
      expect(c.pajak, 4000); // (50.000 − 10.000) × 10%
      expect(c.total, 44000);
    });

    test('potongan rupiah', () {
      final c = buatCart()
        ..addItem(_item())
        ..pasangVoucher(_potong5k);
      expect(c.diskon, 5000);
      expect(c.pajak, 4500);
      expect(c.total, 49500);
    });

    test('potongan tidak melebihi subtotal', () {
      const besar = Voucher('BESAR', 'x', tipe: 'potongan', nilai: 100000);
      final c = buatCart()
        ..addItem(_item())
        ..pasangVoucher(besar);
      expect(c.diskon, 50000);
      expect(c.total, 0);
    });

    test('di bawah minBelanja: diskon 0 dan ada alasan', () {
      final c = buatCart()
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
      final v = Voucher(
        'EXP',
        'x',
        nilai: 10,
        berlakuSampai: DateTime(2026, 10, 31),
      );
      expect(
        v.alasanTidakBerlaku(1000, sekarang: DateTime(2026, 11, 1)),
        contains('kedaluwarsa'),
      );
      expect(
        v.alasanTidakBerlaku(1000, sekarang: DateTime(2026, 10, 20)),
        isNull,
      );
    });

    test('lepasVoucher mengembalikan diskon ke 0', () {
      final c = buatCart()
        ..addItem(_item())
        ..pasangVoucher(_persen20)
        ..lepasVoucher();
      expect(c.voucher, isNull);
      expect(c.diskon, 0);
    });
  });

  group('Keranjang & validasi', () {
    test('item dengan kunci sama digabung', () {
      final c = buatCart()
        ..addItem(_item(jumlah: 1))
        ..addItem(_item(jumlah: 2));
      expect(c.items.length, 1);
      expect(c.totalItems, 3);
    });

    test('checkout keranjang kosong: tidak melakukan apa-apa', () async {
      final c = buatCart();
      await c.checkout(); // tidak melempar, tidak menyentuh Firebase
      expect(c.items, isEmpty);
    });
  });

  group('Dengan repository palsu', () {
    test('checkout sukses: draf berisi rincian harga, keranjang dikosongkan',
        () async {
      final repo = FakeOrderRepository();
      final c = buatCart(pesanan: repo)
        ..addItem(_item())
        ..setMakanDiTempat(true)
        ..pasangVoucher(_potong5k);
      await c.checkout();

      final draf = repo.dibuat.single;
      expect(draf.subtotal, 50000);
      expect(draf.diskon, 5000);
      expect(draf.total, 49500);
      expect(draf.voucher, 'HEMAT5RB');
      expect(draf.makanDiTempat, isTrue);
      expect(c.items, isEmpty);
      expect(c.voucher, isNull);
      expect(c.memproses, isFalse);
    });

    test('checkout gagal: CheckoutException, keranjang tetap utuh', () async {
      final repo = FakeOrderRepository(
        hasilBuat: const Gagal(AturanDilanggar('Kopi sedang habis.')),
      );
      final c = buatCart(pesanan: repo)..addItem(_item());
      await expectLater(
        c.checkout(),
        throwsA(isA<CheckoutException>()
            .having((e) => e.pesan, 'pesan', 'Kopi sedang habis.')),
      );
      expect(c.items, hasLength(1));
      expect(c.memproses, isFalse);
    });

    test('terapkanVoucher: tidak ditemukan / berhasil / tanpa koneksi',
        () async {
      final repo = FakeVoucherRepository({'HEMAT5RB': _potong5k});
      final c = buatCart(voucher: repo)..addItem(_item());

      expect(await c.terapkanVoucher('ASAL'), 'Kode voucher tidak ditemukan.');
      expect(await c.terapkanVoucher('hemat5rb'), isNull);
      expect(c.voucher, 'HEMAT5RB');

      repo.gagal = const TanpaKoneksi();
      expect(await c.terapkanVoucher('HEMAT5RB'), 'Tidak ada koneksi internet.');
    });

    test('muatConfig: tarif pajak & harga Large dari repository', () async {
      final c = buatCart(
        config: const MenuConfig(tarifPajak: 0.11, hargaLarge: 5000),
      )..addItem(_item());
      await c.muatConfig();
      expect(c.pajak, 5500);
      expect(c.config.hargaLarge, 5000);
    });
  });

  test('MenuConfig.fromMap: pajak persen dan nilai rusak', () {
    expect(MenuConfig.fromMap({'pajak': 10}).tarifPajak, 0.10);
    expect(MenuConfig.fromMap({'pajak': 0.11}).tarifPajak, 0.11);
    final rusak = MenuConfig.fromMap({'hargaLarge': 'x', 'addOn': 3});
    expect(rusak.hargaLarge, 4000);
    expect(rusak.addOn, isEmpty);
    expect(MenuConfig.fromMap({'addOn': {'Extra shot': 6000}}).addOn,
        {'Extra shot': 6000});
  });
}
