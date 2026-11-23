// Repository palsu lainnya (di memori, tanpa Firebase) + perakit CartViewModel.
import 'dart:typed_data';

import 'package:kopikita/domain/entities/menu_config.dart';
import 'package:kopikita/domain/entities/notifikasi.dart';
import 'package:kopikita/domain/entities/profil.dart';
import 'package:kopikita/domain/entities/voucher.dart';
import 'package:kopikita/domain/hasil.dart';
import 'package:kopikita/domain/repositories/auth_repository.dart';
import 'package:kopikita/domain/repositories/foto_repository.dart';
import 'package:kopikita/domain/repositories/menu_config_repository.dart';
import 'package:kopikita/domain/repositories/notifikasi_repository.dart';
import 'package:kopikita/domain/repositories/profil_repository.dart';
import 'package:kopikita/domain/repositories/push_repository.dart';
import 'package:kopikita/domain/repositories/voucher_repository.dart';
import 'package:kopikita/domain/use_cases/buat_pesanan.dart';
import 'package:kopikita/viewmodels/cart_view_model.dart';

import 'fake_order_repository.dart';

class FakeVoucherRepository implements VoucherRepository {
  FakeVoucherRepository([this.katalog = const {}]);

  final Map<String, Voucher> katalog;
  Kegagalan? gagal; // Isi untuk pura-pura error

  @override
  Future<Hasil<Voucher?>> ambil(String kode) async {
    final g = gagal;
    if (g != null) return Gagal(g);
    return Berhasil(katalog[kode.trim().toUpperCase()]);
  }

  @override
  Stream<List<Voucher>> streamKode(List<String> kode) =>
      Stream.value([for (final k in kode) ?katalog[k]]);
}

class FakeMenuConfigRepository implements MenuConfigRepository {
  FakeMenuConfigRepository([this.config = const MenuConfig()]);
  final MenuConfig config;

  @override
  Future<MenuConfig> ambil() async => config;
}

class FakeNotifikasiRepository implements NotifikasiRepository {
  final List<String> pesan = []; // Spy: pesan yang ditambahkan

  @override
  Future<void> tambah({
    required String judul,
    required String pesan,
    required String orderId,
  }) async => this.pesan.add(pesan);

  @override
  Stream<List<Notifikasi>> stream() => Stream.value(const []);

  @override
  Future<void> tandaiSemuaDibaca() async {}
}

class FakeProfilRepository implements ProfilRepository {
  String? namaTersimpan;
  String? fotoTersimpan;

  @override
  Stream<Profil> stream() => Stream.value(const Profil(nama: 'Budi Santoso'));

  @override
  Future<Hasil<void>> ubah({required String nama, String? fotoUrl}) async {
    namaTersimpan = nama;
    fotoTersimpan = fotoUrl;
    return const Berhasil(null);
  }

  @override
  Future<Hasil<void>> setNotifikasi(bool aktif) async => const Berhasil(null);
}

class FakeFotoRepository implements FotoRepository {
  FakeFotoRepository([this.hasil = const Berhasil('https://foto/1.jpg')]);
  final Hasil<String> hasil;
  int dipanggil = 0;

  @override
  Future<Hasil<String>> unggah(Uint8List bytes) async {
    dipanggil++;
    return hasil;
  }
}

class FakeAuthRepository implements AuthRepository {
  Hasil<void> hasil = const Berhasil(null);
  final List<String> resetDikirim = [];

  @override
  String? get uid => null;

  @override
  Stream<String?> perubahanUid() => Stream.value(null);

  @override
  Future<Hasil<void>> masuk({required String email, required String sandi}) async =>
      hasil;

  @override
  Future<Hasil<void>> daftar({
    required String nama,
    required String email,
    required String sandi,
  }) async => hasil;

  @override
  Future<Hasil<void>> kirimResetSandi(String email) async {
    resetDikirim.add(email);
    return hasil;
  }

  @override
  Future<Hasil<void>> ubahSandi({required String lama, required String baru}) async =>
      hasil;

  @override
  Future<void> keluar() async {}
}

class FakePushRepository implements PushRepository {
  @override
  Future<void> daftar() async {}

  @override
  Future<void> lepas() async {}
}

/// buatCart: CartViewModel dengan repository palsu.
CartViewModel buatCart({
  FakeOrderRepository? pesanan,
  FakeVoucherRepository? voucher,
  MenuConfig config = const MenuConfig(),
}) => CartViewModel(
  voucher ?? FakeVoucherRepository(),
  FakeMenuConfigRepository(config),
  BuatPesanan(pesanan ?? FakeOrderRepository()),
);
