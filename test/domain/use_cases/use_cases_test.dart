// Unit test use case BuatPesanan, UbahProfil, PantauStatusPesanan dengan
// repository palsu: tanpa Firebase, tanpa internet, tanpa layar.
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:kopikita/domain/entities/cart_item.dart';
import 'package:kopikita/domain/entities/pesanan.dart';
import 'package:kopikita/domain/hasil.dart';
import 'package:kopikita/domain/use_cases/buat_pesanan.dart';
import 'package:kopikita/domain/use_cases/pantau_status_pesanan.dart';
import 'package:kopikita/domain/use_cases/ubah_profil.dart';

import '../../fakes/fake_order_repository.dart';
import '../../fakes/fakes.dart';

Pesanan _pesanan({int status = 0, List<CartItem> items = const []}) =>
    Pesanan(
      id: 'ord-1',
      nomor: 'A-007',
      makanDiTempat: false,
      nomorMeja: 0,
      status: status,
      items: items,
      subtotal: 25000,
      total: 27500,
    );

void main() {
  group('BuatPesanan', () {
    test('keranjang kosong ditolak tanpa memanggil repository', () async {
      final repo = FakeOrderRepository();
      final h = await BuatPesanan(repo).jalankan(_pesanan());
      expect(h, isA<Gagal<String>>());
      expect(repo.dibuat, isEmpty);
    });

    test('isi keranjang diteruskan; hasil = nomor antrean', () async {
      final repo = FakeOrderRepository(hasilBuat: const Berhasil('A-014'));
      final h = await BuatPesanan(repo).jalankan(
        _pesanan(items: const [CartItem(nama: 'Kopi', harga: 25000)]),
      );
      expect(h, isA<Berhasil<String>>().having((b) => b.nilai, 'nomor', 'A-014'));
      expect(repo.dibuat, hasLength(1));
    });
  });

  group('UbahProfil', () {
    test('nama terlalu pendek ditolak, foto tidak diunggah', () async {
      final foto = FakeFotoRepository();
      final h = await UbahProfil(FakeProfilRepository(), foto)
          .jalankan(nama: ' B ', fotoBaru: Uint8List(10));
      expect(h, isA<Gagal<void>>());
      expect(foto.dipanggil, 0);
    });

    test('foto diunggah dulu, URL-nya ikut disimpan', () async {
      final profil = FakeProfilRepository();
      final h = await UbahProfil(profil, FakeFotoRepository())
          .jalankan(nama: '  Budi ', fotoBaru: Uint8List(10));
      expect(h, isA<Berhasil<void>>());
      expect(profil.namaTersimpan, 'Budi');
      expect(profil.fotoTersimpan, 'https://foto/1.jpg');
    });

    test('unggah gagal: profil tidak disimpan', () async {
      final profil = FakeProfilRepository();
      final h = await UbahProfil(
        profil,
        FakeFotoRepository(const Gagal(TanpaKoneksi())),
      ).jalankan(nama: 'Budi', fotoBaru: Uint8List(10));
      expect(h, isA<Gagal<void>>());
      expect(profil.namaTersimpan, isNull);
    });
  });

  test('PantauStatusPesanan: status awal diabaikan, perubahan dicatat',
      () async {
    final pesanan = FakeOrderRepository();
    final notif = FakeNotifikasiRepository();
    final pantau = PantauStatusPesanan(pesanan, notif)..mulai();

    pesanan.aktif.add([_pesanan(status: 0)]); // titik awal
    await pumpEventQueue();
    expect(notif.pesan, isEmpty);

    pesanan.aktif.add([_pesanan(status: 3)]); // siap diambil
    await pumpEventQueue();
    expect(notif.pesan, ['Pesanan A-007 siap diambil. Silakan ke kasir.']);

    await pantau.berhenti();
    pesanan.aktif.add([_pesanan(status: 1)]);
    await pumpEventQueue();
    expect(notif.pesan, hasLength(1)); // sudah berhenti
  });
}
