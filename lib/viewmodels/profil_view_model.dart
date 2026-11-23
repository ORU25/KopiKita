import 'dart:typed_data';

import '../domain/entities/foto_dipilih.dart';
import '../domain/entities/profil.dart';
import '../domain/hasil.dart';
import '../domain/repositories/perangkat_repository.dart';
import '../domain/repositories/profil_repository.dart';
import '../domain/repositories/push_repository.dart';
import '../domain/use_cases/ubah_profil.dart';
import 'pesan_kegagalan.dart';
import 'stream_view_model.dart';

/// Hasil memilih foto untuk View: [foto] terisi bila berhasil; [pesan] berisi
/// kalimat galat; [diblokir] = tampilkan tombol "Buka Pengaturan".
typedef HasilPilihFoto = ({Uint8List? foto, String? pesan, bool diblokir});

/// Hasil menyalakan notifikasi: [izinDitolak] = izin sistem tidak diberikan
/// (notifikasi di dalam aplikasi tetap berjalan).
typedef HasilNotifikasi = ({String? pesan, bool izinDitolak});

// ProfilViewModel: profil user (sapaan Beranda, layar Akun) + aksi ubah,
// termasuk fitur perangkat: kamera/galeri untuk foto dan izin notifikasi.
class ProfilViewModel extends StreamViewModel<Profil> {
  ProfilViewModel(
    this._repo,
    this._ubahProfil,
    this._push,
    this._pemilihFoto,
    this._pengaturan,
  ) {
    muatUlang();
  }

  final ProfilRepository _repo;
  final UbahProfil _ubahProfil;
  final PushRepository _push;
  final PemilihFoto _pemilihFoto;
  final PengaturanPerangkat _pengaturan;

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

  // ---------- Notifikasi (izin diminta saat fitur dinyalakan) ----------
  Future<HasilNotifikasi> setNotifikasi(bool aktif) async {
    var izinDitolak = false;
    if (aktif) izinDitolak = !await _push.mintaIzin();
    final pesan = pesanDari(await _repo.setNotifikasi(aktif));
    return (pesan: pesan, izinDitolak: izinDitolak);
  }

  // ---------- Foto profil (kamera / galeri) ----------
  bool get kameraTersedia => _pemilihFoto.kameraTersedia;

  /// pilihFoto: ambil dari kamera/galeri lalu periksa format & ukuran.
  Future<HasilPilihFoto> pilihFoto({required bool dariKamera}) async =>
      _olah(await _pemilihFoto.ambil(dariKamera: dariKamera));

  /// fotoHilang: Android memulihkan foto bila aplikasi sempat dimatikan
  /// saat kamera terbuka. null = tidak ada yang perlu dipulihkan.
  Future<HasilPilihFoto?> fotoHilang() async {
    final h = await _pemilihFoto.fotoHilang();
    return h == null ? null : _olah(h);
  }

  HasilPilihFoto _olah(Hasil<FotoDipilih> h) => switch (h) {
    Berhasil(:final nilai) => switch (nilai.alasanDitolak(
      maksBytes: maksFotoBytes,
    )) {
      null => (foto: nilai.bita, pesan: null, diblokir: false),
      final alasan => (foto: null, pesan: alasan, diblokir: false),
    },
    Gagal(:final kegagalan) => (
      foto: null,
      pesan: pesanKegagalan(kegagalan),
      diblokir: kegagalan is IzinDiblokir,
    ),
  };

  Future<void> bukaPengaturanAplikasi() => _pengaturan.bukaPengaturanAplikasi();

  Future<String?> simpanProfil({
    required String nama,
    Uint8List? fotoBaru,
  }) async =>
      pesanDari(await _ubahProfil.jalankan(nama: nama, fotoBaru: fotoBaru));
}
