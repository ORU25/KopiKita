// Versi PALSU untuk pengembangan dan pengujian: tanpa GPS, tanpa kamera.
import 'dart:typed_data';

import 'package:kopikita/domain/entities/foto_dipilih.dart';
import 'package:kopikita/domain/entities/lokasi.dart';
import 'package:kopikita/domain/hasil.dart';
import 'package:kopikita/domain/repositories/perangkat_repository.dart';

/// Skenario lokasi untuk chip pilihan di layar pengembangan
/// (Pertemuan 13, Bagian 9.5). Ubah saat runtime tanpa recompile.
enum SkenarioLokasi {
  berhasil('Berhasil'),
  layananMati('Layanan mati'),
  izinDitolak('Izin ditolak'),
  izinDiblokir('Izin diblokir'),
  waktuHabis('Waktu habis');

  const SkenarioLokasi(this.label);
  final String label;
}

class LayananLokasiPalsu implements LayananLokasi {
  LayananLokasiPalsu(this.hasil, {this.jeda = Duration.zero});

  /// Contoh: kedai + 0,001 derajat bujur (sekitar 111 m ke timur).
  factory LayananLokasiPalsu.dekatKedai() => LayananLokasiPalsu(
    Berhasil(
      Posisi(
        lintang: lintangKedai,
        bujur: bujurKedai + 0.001,
        akurasiMeter: 8,
        waktu: DateTime(2026, 11, 23, 10),
      ),
    ),
  );

  factory LayananLokasiPalsu.pemalsuGps() => LayananLokasiPalsu(
    Berhasil(
      Posisi(
        lintang: lintangKedai,
        bujur: bujurKedai,
        akurasiMeter: 5,
        waktu: DateTime(2026, 11, 23, 10),
        palsu: true,
      ),
    ),
  );

  /// Hasil yang dikembalikan saat [skenario] == berhasil.
  Hasil<Posisi> hasil;

  /// Bisa diubah kapan saja; jika bukan berhasil, mengalahkan [hasil].
  SkenarioLokasi skenario = SkenarioLokasi.berhasil;

  final Duration jeda;
  int dipanggil = 0;

  @override
  Future<Hasil<Posisi>> posisiSekarang() async {
    dipanggil++;
    if (jeda > Duration.zero) await Future<void>.delayed(jeda);
    return switch (skenario) {
      SkenarioLokasi.berhasil => hasil,
      SkenarioLokasi.layananMati => const Gagal(LayananLokasiMati()),
      SkenarioLokasi.izinDitolak => const Gagal(IzinDitolak(Fitur.lokasi)),
      SkenarioLokasi.izinDiblokir => const Gagal(IzinDiblokir(Fitur.lokasi)),
      SkenarioLokasi.waktuHabis => const Gagal(WaktuHabis()),
    };
  }

  @override
  Stream<Hasil<Posisi>> ikutiPosisi({int jarakMinimumMeter = 10}) async* {
    // Untuk uji: cukup satu emisi. Ganti dengan iterable bila perlu
    // mensimulasikan urutan posisi.
    yield await posisiSekarang();
  }
}

class PemilihFotoPalsu implements PemilihFoto {
  PemilihFotoPalsu(this.hasil, {this.kameraTersedia = true, this.hasilHilang});

  final Hasil<FotoDipilih> hasil;

  /// Hasil yang dipakai oleh [fotoHilang] (default: tidak ada foto hilang).
  final Hasil<FotoDipilih>? hasilHilang;

  @override
  final bool kameraTersedia;

  @override
  Future<Hasil<FotoDipilih>> ambil({required bool dariKamera}) async => hasil;

  @override
  Future<Hasil<FotoDipilih>?> fotoHilang() async => hasilHilang;
}

class PengaturanPerangkatPalsu implements PengaturanPerangkat {
  int bukaAplikasi = 0;
  int bukaLokasi = 0;

  @override
  Future<void> bukaPengaturanAplikasi() async => bukaAplikasi++;

  @override
  Future<void> bukaPengaturanLokasi() async => bukaLokasi++;
}

FotoDipilih fotoContoh() =>
    FotoDipilih(nama: 'contoh.jpg', bita: Uint8List.fromList([1, 2, 3]));
