// KartuJarakKedai: jarak dari pengguna ke kedai + tombol "Buka di peta".
// Alur izin sopan (Pertemuan 13, Bagian 7): lokasi TIDAK diminta saat aplikasi
// dibuka, hanya saat pengguna mengetuk tombol, dan aplikasi tetap bisa dipakai
// penuh jika izin ditolak.
// View murni: keadaan & aksi ada di JarakKedaiViewModel.
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/entities/lokasi.dart';
import '../theme/app_theme.dart';
import '../viewmodels/jarak_kedai_view_model.dart';

class KartuJarakKedai extends StatefulWidget {
  const KartuJarakKedai({super.key});

  @override
  State<KartuJarakKedai> createState() => _KartuJarakKedaiState();
}

class _KartuJarakKedaiState extends State<KartuJarakKedai> {
  late final AppLifecycleListener _pendengar;

  @override
  void initState() {
    super.initState();
    // Setelah pengguna kembali dari Pengaturan, ViewModel memeriksa ulang.
    _pendengar = AppLifecycleListener(
      onResume: () => context.read<JarakKedaiViewModel>().saatKembali(),
    );
  }

  @override
  void dispose() {
    _pendengar.dispose();
    super.dispose();
  }

  void _cari() => context.read<JarakKedaiViewModel>().cari();

  Future<void> _bukaPeta() async {
    final Uri alamat = context.read<JarakKedaiViewModel>().alamatPeta;
    bool berhasil = false;
    try {
      berhasil = await launchUrl(alamat, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!berhasil && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Tidak ada aplikasi peta yang bisa dibuka.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<JarakKedaiViewModel>();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline),
      ),
      child: switch (vm.keadaan) {
        BelumDiminta() => _isiAwal(),
        Mencari() => _isiMencari(),
        Ditemukan(:final jarak) => _isiDitemukan(jarak),
        final GagalLokasi g => _isiGagal(vm, g),
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
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: AppColors.primary,
        ),
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
            const Icon(
              Icons.warning_amber_rounded,
              size: 16,
              color: AppColors.danger,
            ),
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

  Widget _isiGagal(JarakKedaiViewModel vm, GagalLokasi g) {
    // Tombol menyesuaikan jenis kegagalannya.
    final Widget tombol = switch (g) {
      GagalLokasi(layananMati: true) => OutlinedButton.icon(
        onPressed: kIsWeb ? null : vm.bukaPengaturanLokasi,
        icon: const Icon(Icons.location_on_outlined, size: 18),
        label: const Text('Nyalakan Lokasi'),
      ),
      GagalLokasi(diblokir: true) =>
        kIsWeb
            // Browser mengatur izinnya sendiri, tidak ada halaman Pengaturan.
            ? _isi(
                'Klik ikon di sebelah kiri alamat situs, lalu izinkan Lokasi.',
              )
            : OutlinedButton.icon(
                onPressed: vm.bukaPengaturanAplikasi,
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
        _isi(g.pesan),
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
