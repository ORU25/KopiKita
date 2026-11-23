// Uji domain perangkat dengan data palsu (Pertemuan 13, Bagian 9.7).
// Jalankan: flutter test test/perangkat_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kopikita/services/perangkat.dart';
import 'package:kopikita/services/perangkat_palsu.dart';

void main() {
  group('jarakMeter (haversine)', () {
    test('0,001° bujur di khatulistiwa ≈ 111 m', () {
      expect(jarakMeter(0, 0, 0, 0.001), closeTo(111, 2));
    });

    test('0,001° lintang di khatulistiwa ≈ 111 m', () {
      expect(jarakMeter(0, 0, 0.001, 0), closeTo(111, 2));
    });

    test('titik ke dirinya sendiri = 0', () {
      expect(
        jarakMeter(-0.467, 117.157, -0.467, 117.157),
        closeTo(0, 0.01),
      );
    });
  });

  group('namaArah (8 mata angin)', () {
    test('0° utara', () => expect(namaArah(0), 'utara'));
    test('45° timur laut', () => expect(namaArah(45), 'timur laut'));
    test('90° timur', () => expect(namaArah(90), 'timur'));
    test('180° selatan', () => expect(namaArah(180), 'selatan'));
    test('270° barat', () => expect(namaArah(270), 'barat'));
    test('350° tetap utara (pembulatan ke atas)', () {
      expect(namaArah(350), 'utara');
    });
  });

  group('formatJarak', () {
    test('di bawah 1000 m tetap meter', () {
      expect(formatJarak(85), '85 m');
      expect(formatJarak(999), '999 m');
    });
    test('1000 m ke atas jadi km dengan koma', () {
      expect(formatJarak(1234), '1,2 km');
      expect(formatJarak(2500), '2,5 km');
    });
  });

  group('JarakKedai.dari', () {
    test('posisi 0,001° bujur timur kedai → arah timur, ~111 m', () {
      final j = JarakKedai.dari(Posisi(
        lintang: lintangKedai,
        bujur: bujurKedai + 0.001,
        akurasiMeter: 8,
        waktu: DateTime(2026),
      ));
      expect(j.arah, 'timur');
      expect(j.meter, closeTo(111, 2));
      expect(j.palsu, isFalse);
    });

    test('flag palsu diteruskan ke JarakKedai', () {
      final j = JarakKedai.dari(Posisi(
        lintang: lintangKedai,
        bujur: bujurKedai,
        akurasiMeter: 8,
        waktu: DateTime(2026),
        palsu: true,
      ));
      expect(j.palsu, isTrue);
    });
  });

  group('pesanKegagalan', () {
    test('Dibatalkan → null (tanpa pesan)', () {
      expect(pesanKegagalan(const Dibatalkan()), isNull);
    });
    test('LayananLokasiMati menyebut mati', () {
      expect(pesanKegagalan(const LayananLokasiMati()), contains('mati'));
    });
    test('IzinDitolak menyebut nama fitur', () {
      expect(
        pesanKegagalan(const IzinDitolak(Fitur.lokasi)),
        contains('lokasi'),
      );
    });
    test('IzinDiblokir menyarankan Pengaturan', () {
      expect(
        pesanKegagalan(const IzinDiblokir(Fitur.kamera)),
        contains('Pengaturan'),
      );
    });
    test('PerangkatTidakMendukung menyebut nama fitur', () {
      expect(
        pesanKegagalan(const PerangkatTidakMendukung(Fitur.galeri)),
        contains('galeri'),
      );
    });
    test('WaktuHabis menyarankan dekat jendela', () {
      expect(pesanKegagalan(const WaktuHabis()), contains('jendela'));
    });
    test('PemilihSibuk menjelaskan pemilih masih terbuka', () {
      expect(pesanKegagalan(const PemilihSibuk()), contains('terbuka'));
    });
    test('GangguanPerangkat menampilkan kodenya', () {
      expect(
        pesanKegagalan(const GangguanPerangkat('xyz')),
        contains('xyz'),
      );
    });
  });

  group('LayananLokasiPalsu', () {
    test('menghitung berapa kali dipanggil', () async {
      final l = LayananLokasiPalsu(Berhasil(Posisi(
        lintang: lintangKedai,
        bujur: bujurKedai,
        akurasiMeter: 8,
        waktu: DateTime(2026),
      )));
      expect(l.dipanggil, 0);
      await l.posisiSekarang();
      await l.posisiSekarang();
      expect(l.dipanggil, 2);
    });

    test('skenario layananMati → Gagal(LayananLokasiMati)', () async {
      final l = LayananLokasiPalsu.dekatKedai();
      l.skenario = SkenarioLokasi.layananMati;
      final r = await l.posisiSekarang();
      expect(r, isA<Gagal<Posisi>>());
      expect((r as Gagal<Posisi>).kegagalan, isA<LayananLokasiMati>());
    });

    test('skenario izinDiblokir → Gagal(IzinDiblokir lokasi)', () async {
      final l = LayananLokasiPalsu.dekatKedai();
      l.skenario = SkenarioLokasi.izinDiblokir;
      final r = await l.posisiSekarang();
      final k = (r as Gagal<Posisi>).kegagalan;
      expect(k, isA<IzinDiblokir>());
      expect((k as IzinDiblokir).fitur, Fitur.lokasi);
    });

    test('ikutiPosisi memancarkan satu Hasil', () async {
      final l = LayananLokasiPalsu.dekatKedai();
      final hasil = await l.ikutiPosisi().toList();
      expect(hasil, hasLength(1));
      expect(hasil.first, isA<Berhasil<Posisi>>());
    });
  });

  group('PengaturanPerangkatPalsu', () {
    test('menghitung klik masing-masing tombol', () async {
      final p = PengaturanPerangkatPalsu();
      await p.bukaPengaturanAplikasi();
      await p.bukaPengaturanLokasi();
      await p.bukaPengaturanAplikasi();
      expect(p.bukaAplikasi, 2);
      expect(p.bukaLokasi, 1);
    });
  });

  group('PemilihFotoPalsu', () {
    test('mengembalikan hasil yang diberikan', () async {
      final f = PemilihFotoPalsu(Berhasil(fotoContoh()));
      final r = await f.ambil(dariKamera: false);
      expect(r, isA<Berhasil<FotoDipilih>>());
      expect((r as Berhasil<FotoDipilih>).nilai.nama, 'contoh.jpg');
    });

    test('fotoHilang null jika tidak ada', () async {
      final f = PemilihFotoPalsu(Berhasil(fotoContoh()));
      expect(await f.fotoHilang(), isNull);
    });

    test('fotoHilang mengembalikan hasil jika diisi', () async {
      final f = PemilihFotoPalsu(
        Berhasil(fotoContoh()),
        hasilHilang: Berhasil(fotoContoh()),
      );
      expect(await f.fotoHilang(), isA<Berhasil<FotoDipilih>>());
    });
  });
}