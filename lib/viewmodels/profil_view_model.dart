import 'dart:typed_data';

import '../domain/entities/profil.dart';
import '../domain/repositories/profil_repository.dart';
import '../domain/use_cases/ubah_profil.dart';
import 'pesan_kegagalan.dart';
import 'stream_view_model.dart';

// ProfilViewModel: profil user (sapaan Beranda, layar Akun) + aksi ubah.
class ProfilViewModel extends StreamViewModel<Profil> {
  ProfilViewModel(this._repo, this._ubahProfil) {
    muatUlang();
  }

  final ProfilRepository _repo;
  final UbahProfil _ubahProfil;

  /// Batas ukuran foto (sama dengan aturan use case UbahProfil).
  static const int maksFotoBytes = UbahProfil.maksFotoBytes;

  @override
  Stream<Profil> buatStream() => _repo.stream();

  Profil get profil => data ?? const Profil();

  /// namaTampil: "Pengguna" bila nama kosong.
  String get namaTampil =>
      profil.nama.trim().isEmpty ? 'Pengguna' : profil.nama;

  /// namaDepan: kata pertama nama agar sapaan muat satu baris.
  String get namaDepan => profil.nama.trim().split(RegExp(r'\s+')).first;

  String get inisial => namaTampil.trim().substring(0, 1).toUpperCase();

  /// null = berhasil, selain itu pesan galat.
  Future<String?> setNotifikasi(bool aktif) async =>
      pesanDari(await _repo.setNotifikasi(aktif));

  Future<String?> simpanProfil({
    required String nama,
    Uint8List? fotoBaru,
  }) async =>
      pesanDari(await _ubahProfil.jalankan(nama: nama, fotoBaru: fotoBaru));
}
