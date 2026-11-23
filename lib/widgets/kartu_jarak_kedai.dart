// KartuJarakKedai: jarak dari pengguna ke kedai + tombol "Buka di peta".
// Alur izin sopan (Pertemuan 13, Bagian 7): lokasi TIDAK diminta saat aplikasi
// dibuka, hanya saat pengguna mengetuk tombol, dan aplikasi tetap bisa dipakai
// penuh jika izin ditolak.
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/perangkat.dart';
import '../services/perangkat_asli.dart';
import '../theme/app_theme.dart';

/// Empat keadaan kartu, seperti Hasil di Pertemuan 12.
sealed class _Keadaan {
  const _Keadaan();
}

class _BelumDiminta extends _Keadaan {
  const _BelumDiminta();
}

class _Mencari extends _Keadaan {
  const _Mencari();
}

class _Ditemukan extends _Keadaan {
  const _Ditemukan(this.jarak);
  final JarakKedai jarak;
}

class _Gagal extends _Keadaan {
  const _Gagal(this.kegagalan);
  final Kegagalan kegagalan;
}

class KartuJarakKedai extends StatefulWidget {
  const KartuJarakKedai({
    super.key,
    this.layanan = const LayananLokasiGeolocator(),
    this.pengaturan = const PengaturanPerangkatAsli(),
  });

  /// Bisa diganti LayananLokasiPalsu untuk pengembangan dan uji.
  final LayananLokasi layanan;
  final PengaturanPerangkat pengaturan;

  @override
  State<KartuJarakKedai> createState() => _KartuJarakKedaiState();
}

class _KartuJarakKedaiState extends State<KartuJarakKedai> {
  _Keadaan _keadaan = const _BelumDiminta();
  late final AppLifecycleListener _pendengar;

  @override
  void initState() {
    super.initState();
    // Setelah pengguna kembali dari Pengaturan, periksa ulang otomatis.
    _pendengar = AppLifecycleListener(onResume: _saatKembali);
  }

  @override
  void dispose() {
    _pendengar.dispose();
    super.dispose();
  }

  void _saatKembali() {
    final _Keadaan k = _keadaan;
    if (k is _Gagal &&
        (k.kegagalan is LayananLokasiMati || k.kegagalan is IzinDiblokir)) {
      _cari();
    }
  }

  Future<void> _cari() async {
    if (_keadaan is _Mencari) return; // cegah ketukan ganda
    setState(() => _keadaan = const _Mencari());
    final Hasil<Posisi> hasil = await widget.layanan.posisiSekarang();
    if (!mounted) return;
    setState(() {
      _keadaan = switch (hasil) {
        Berhasil(:final nilai) => _Ditemukan(JarakKedai.dari(nilai)),
        Gagal(:final kegagalan) => _Gagal(kegagalan),
      };
    });
  }

  Future<void> _bukaPeta() async {
    final Uri alamat = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': '$lintangKedai,$bujurKedai',
    });
    bool berhasil = false;
    try {
      berhasil = await launchUrl(alamat, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!berhasil && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Tidak ada aplikasi peta yang bisa dibuka.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline),
      ),
      child: switch (_keadaan) {
        _BelumDiminta() => _isiAwal(),
        _Mencari() => _isiMencari(),
        _Ditemukan(:final jarak) => _isiDitemukan(jarak),
        _Gagal(:final kegagalan) => _isiGagal(kegagalan),
      },
    );
  }

  Widget _judul(String teks) => Text(teks, style: ts(15, 800));

  Widget _isi(String teks) =>
      Text(teks, style: ts(13, 500, color: AppColors.muted, height: 1.4));

  // Penjelasan SEBELUM dialog sistem: apa manfaatnya, ke mana datanya pergi.
  Widget _isiAwal() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _judul('Seberapa jauh kedai dari kamu?'),
      const SizedBox(height: 6),
      _isi(
        'Izinkan akses lokasi untuk melihat jarak ke kedai. Lokasimu hanya '
        'dipakai di perangkat ini dan tidak disimpan atau dikirim ke mana pun. '
        'Kamu tetap bisa memesan tanpa ini.',
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          FilledButton.icon(
            onPressed: _cari,
            icon: const Icon(Icons.my_location, size: 18),
            label: const Text('Cek jarak ke kedai'),
          ),
          TextButton.icon(
            onPressed: _bukaPeta,
            icon: const Icon(Icons.map_outlined, size: 18),
            label: const Text('Buka di peta'),
          ),
        ],
      ),
    ],
  );

  Widget _isiMencari() => Row(
    children: [
      const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary),
      ),
      const SizedBox(width: 12),
      Expanded(child: _isi('Mencari lokasimu…')),
    ],
  );

  Widget _isiDitemukan(JarakKedai j) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _judul('Jarak ke kedai'),
      const SizedBox(height: 4),
      Text(formatJarak(j.meter), style: ts(24, 800, color: AppColors.primary)),
      const SizedBox(height: 2),
      _isi('Arah ${j.arah} · akurasi ± ${j.akurasiMeter.round()} m'),
      if (j.palsu) ...[
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                size: 16, color: AppColors.danger),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Lokasi terdeteksi berasal dari aplikasi pemalsu GPS.',
                style: ts(12, 600, color: AppColors.danger),
              ),
            ),
          ],
        ),
      ],
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          FilledButton.icon(
            onPressed: _bukaPeta,
            icon: const Icon(Icons.map_outlined, size: 18),
            label: const Text('Buka di peta'),
          ),
          TextButton.icon(
            onPressed: _cari,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Perbarui'),
          ),
        ],
      ),
    ],
  );

  Widget _isiGagal(Kegagalan k) {
    // Tombol menyesuaikan jenis kegagalannya.
    final Widget tombol = switch (k) {
      LayananLokasiMati() => OutlinedButton.icon(
        onPressed: kIsWeb ? null : widget.pengaturan.bukaPengaturanLokasi,
        icon: const Icon(Icons.location_on_outlined, size: 18),
        label: const Text('Nyalakan Lokasi'),
      ),
      IzinDiblokir() =>
        kIsWeb
            // Browser mengatur izinnya sendiri, tidak ada halaman Pengaturan.
            ? _isi('Klik ikon di sebelah kiri alamat situs, lalu izinkan Lokasi.')
            : OutlinedButton.icon(
                onPressed: widget.pengaturan.bukaPengaturanAplikasi,
                icon: const Icon(Icons.settings_outlined, size: 18),
                label: const Text('Buka Pengaturan'),
              ),
      _ => OutlinedButton.icon(
        onPressed: _cari,
        icon: const Icon(Icons.refresh, size: 18),
        label: const Text('Coba lagi'),
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _judul('Jarak belum bisa ditampilkan'),
        const SizedBox(height: 6),
        _isi(pesanKegagalan(k) ?? 'Coba lagi.'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            tombol,
            TextButton.icon(
              onPressed: _bukaPeta,
              icon: const Icon(Icons.map_outlined, size: 18),
              label: const Text('Buka di peta'),
            ),
          ],
        ),
      ],
    );
  }
}