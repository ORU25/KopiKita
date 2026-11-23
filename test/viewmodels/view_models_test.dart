// Unit test ViewModel (tanpa layar) dengan repository palsu.
import 'package:flutter_test/flutter_test.dart';

import 'package:kopikita/domain/hasil.dart';
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

  test('ProfilViewModel: keadaan memuat → data, nama depan & inisial', () async {
    final vm = ProfilViewModel(
      FakeProfilRepository(),
      UbahProfil(FakeProfilRepository(), FakeFotoRepository()),
    );
    expect(vm.keadaan.hasData, isFalse);
    expect(vm.namaTampil, 'Pengguna');
    await pumpEventQueue();
    expect(vm.namaDepan, 'Budi');
    expect(vm.inisial, 'B');
  });
}
