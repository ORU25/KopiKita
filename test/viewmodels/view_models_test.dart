// Unit test ViewModel (tanpa layar) dengan repository palsu.
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:kopikita/domain/entities/foto_dipilih.dart';
import 'package:kopikita/domain/hasil.dart';
import 'package:kopikita/viewmodels/jarak_kedai_view_model.dart';

import '../fakes/perangkat_palsu.dart';
import 'package:kopikita/domain/use_cases/pantau_status_pesanan.dart';
import 'package:kopikita/domain/use_cases/ubah_profil.dart';
import 'package:kopikita/viewmodels/auth_view_model.dart';
import 'package:kopikita/viewmodels/profil_view_model.dart';

import '../fakes/fake_order_repository.dart';
import '../fakes/fakes.dart';

AuthViewModel _auth(FakeAuthRepository repo) => AuthViewModel(
  repo,
  FakePushRepository(),
  PantauStatusPesanan(FakeOrderRepository(), FakeNotifikasiRepository()),
);

void main() {
  group('AuthViewModel', () {
    test('reset sandi: email tidak valid ditolak sebelum ke repository',
        () async {
      final repo = FakeAuthRepository();
      final vm = _auth(repo);
      expect(await vm.kirimResetSandi('bukan-email'), 'Masukkan email yang valid.');
      expect(repo.resetDikirim, isEmpty);
      expect(await vm.kirimResetSandi(' a@b.co '), isNull);
      expect(repo.resetDikirim, ['a@b.co']);
    });

    test('masuk gagal: pesan ramah, memproses kembali false', () async {
      final repo = FakeAuthRepository()..hasil = const Gagal(KredensialSalah());
      final vm = _auth(repo);
      expect(await vm.masuk('a@b.co', 'salah'), 'Email atau kata sandi salah.');
      expect(vm.memproses, isFalse);
    });

    test('ubah sandi: sandi lama salah ditandai untuk field-nya', () async {
      final repo = FakeAuthRepository()..hasil = const Gagal(KredensialSalah());
      final h = await _auth(repo).ubahSandi('lama', 'baru123');
      expect(h.sandiLamaSalah, isTrue);
      expect(h.pesan, 'Kata sandi lama salah.');
    });

    test('status awal: belum login → keluar', () async {
      final vm = _auth(FakeAuthRepository());
      expect(vm.status, StatusAuth.memeriksa);
      await pumpEventQueue();
      expect(vm.status, StatusAuth.keluar);
    });
  });

  group('ProfilViewModel', () {
    test('keadaan memuat → data, nama depan & inisial', () async {
      final vm = _profil();
      expect(vm.keadaan.hasData, isFalse);
      expect(vm.namaTampil, 'Pengguna');
      await pumpEventQueue();
      expect(vm.namaDepan, 'Budi');
      expect(vm.inisial, 'B');
    });

    test('menyalakan notifikasi meminta izin; ditolak ditandai', () async {
      final push = FakePushRepository(izin: false);
      final h = await _profil(push: push).setNotifikasi(true);
      expect(push.dimintaIzin, 1);
      expect(h.izinDitolak, isTrue);
      expect(h.pesan, isNull);
    });

    test('mematikan notifikasi tidak meminta izin', () async {
      final push = FakePushRepository();
      final h = await _profil(push: push).setNotifikasi(false);
      expect(push.dimintaIzin, 0);
      expect(h.izinDitolak, isFalse);
    });

    test('foto valid dari kamera diterima', () async {
      final h = await _profil(
        foto: PemilihFotoPalsu(Berhasil(fotoContoh())),
      ).pilihFoto(dariKamera: true);
      expect(h.foto, isNotNull);
      expect(h.pesan, isNull);
    });

    test('format foto salah ditolak', () async {
      final h = await _profil(
        foto: PemilihFotoPalsu(
          Berhasil(FotoDipilih(nama: 'x.gif', bita: Uint8List(3))),
        ),
      ).pilihFoto(dariKamera: false);
      expect(h.foto, isNull);
      expect(h.pesan, contains('JPG'));
    });

    test('kamera diblokir → tombol Pengaturan; batal → tanpa pesan', () async {
      final blok = await _profil(
        foto: PemilihFotoPalsu(const Gagal(IzinDiblokir(Fitur.kamera))),
      ).pilihFoto(dariKamera: true);
      expect(blok.diblokir, isTrue);
      expect(blok.pesan, contains('diblokir'));

      final batal = await _profil(
        foto: PemilihFotoPalsu(const Gagal(Dibatalkan())),
      ).pilihFoto(dariKamera: true);
      expect(batal.foto, isNull);
      expect(batal.pesan, isNull);
    });
  });

  group('JarakKedaiViewModel', () {
    test('belum diminta → berhasil → Ditemukan (~111 m)', () async {
      final lokasi = LayananLokasiPalsu.dekatKedai();
      final vm = JarakKedaiViewModel(lokasi, PengaturanPerangkatPalsu());
      expect(vm.keadaan, isA<BelumDiminta>());
      expect(lokasi.dipanggil, 0); // izin tidak diminta saat dibuka
      await vm.cari();
      final k = vm.keadaan as Ditemukan;
      expect(k.jarak.meter, closeTo(111, 2));
    });

    test('izin diblokir → GagalLokasi; kembali dari Pengaturan cek ulang',
        () async {
      final lokasi = LayananLokasiPalsu.dekatKedai()
        ..skenario = SkenarioLokasi.izinDiblokir;
      final vm = JarakKedaiViewModel(lokasi, PengaturanPerangkatPalsu());
      await vm.cari();
      expect((vm.keadaan as GagalLokasi).diblokir, isTrue);

      lokasi.skenario = SkenarioLokasi.berhasil; // pengguna mengizinkan
      vm.saatKembali();
      await pumpEventQueue();
      expect(vm.keadaan, isA<Ditemukan>());
      expect(lokasi.dipanggil, 2);
    });

    test('izin ditolak biasa: saatKembali tidak memanggil ulang', () async {
      final lokasi = LayananLokasiPalsu.dekatKedai()
        ..skenario = SkenarioLokasi.izinDitolak;
      final vm = JarakKedaiViewModel(lokasi, PengaturanPerangkatPalsu());
      await vm.cari();
      vm.saatKembali();
      await pumpEventQueue();
      expect(lokasi.dipanggil, 1);
    });
  });
}

ProfilViewModel _profil({FakePushRepository? push, PemilihFotoPalsu? foto}) =>
    ProfilViewModel(
      FakeProfilRepository(),
      UbahProfil(FakeProfilRepository(), FakeFotoRepository()),
      push ?? FakePushRepository(),
      foto ?? PemilihFotoPalsu(Berhasil(fotoContoh())),
      PengaturanPerangkatPalsu(),
    );
