import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/voucher.dart';
import '../services/acc_cloud.dart';
import '../services/auth_service.dart';
import '../services/user_repo.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  Future<void> _keluar() => AuthService.keluar();

  Future<void> _sheetEditProfil(BuildContext context) async {
    final data = await UserRepo.ambil();
    final namaAwal = UserRepo.namaDari(data);
    final fotoAwal = (data?['fotoUrl'] as String?) ?? '';

    if (!context.mounted) return;
    final simpan = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _SheetEditProfil(
        namaAwal: namaAwal,
        fotoAwal: fotoAwal,
      ),
    );

    if (simpan != true) return;
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Profil diperbarui.')),
      );
  }

  Future<void> _sheetUbahSandi(BuildContext context) async {
    final simpan = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const _SheetUbahSandi(),
    );

    if (simpan != true) return;
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Kata sandi berhasil diubah.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: StreamBuilder(
        stream: UserRepo.stream(),
        builder: (context, snap) {
          final data = snap.data?.data();
          final nama = UserRepo.namaDari(data);
          final email = UserRepo.emailDari(data);
          final role = UserRepo.roleDari(data);
          final voucherKode = UserRepo.voucherDari(data);
          final fotoUrl = (data?['fotoUrl'] as String?) ?? '';

          final namaTampil = nama.isEmpty ? 'Pengguna' : nama;
          final inisial = namaTampil.trim().isEmpty
              ? '?'
              : namaTampil.trim().substring(0, 1).toUpperCase();

          return ListView(
            padding: const EdgeInsets.fromLTRB(0, 24, 0, 170),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Akun', style: ts(24, 800, ls: -0.4)),
                    const SizedBox(height: 16),
                    // Card profil hanya tampilan; edit lewat baris "Edit profil".
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          _Avatar(fotoUrl: fotoUrl, inisial: inisial),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(namaTampil, style: ts(16, 800)),
                                Text(
                                  email,
                                  style: ts(12, 500, color: AppColors.muted),
                                ),
                                if (role != 'pelanggan')
                                  Text(
                                    role == 'admin' ? 'Admin' : 'Staf',
                                    style: ts(12, 700,
                                        color: AppColors.primary),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Voucher saya', style: ts(16, 800)),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Blok voucher milik P4 — baca vouchers/{kode} dari Firestore.
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('vouchers')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox(height: 76);
                  }

                  final semuaVoucher = snapshot.data!.docs
                      .map((d) => Voucher.fromMap(
                          d.id, d.data() as Map<String, dynamic>))
                      .toList();

                  final voucher = <Voucher>[];
                  for (final kode in voucherKode) {
                    final match = semuaVoucher
                        .where((v) => v.kode == kode && v.aktif);
                    if (match.isNotEmpty) {
                      voucher.add(match.first);
                    }
                  }

                  return SizedBox(
                    height: 76,
                    child: voucher.isEmpty
                        ? Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'Belum ada voucher.',
                              style: ts(13, 500, color: AppColors.muted),
                            ),
                          )
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: voucher.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, i) =>
                                _KartuVoucher(voucher[i]),
                          ),
                  );
                },
              ),

              const SizedBox(height: 12),
              _barisPengaturan(
                Icons.notifications_none_rounded,
                'Notifikasi pesanan',
                () => _ubahNotifikasi(
                    context, !UserRepo.notifikasiDari(data)),
                trailing: Switch(
                  value: UserRepo.notifikasiDari(data),
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) => _ubahNotifikasi(context, v),
                ),
              ),
              _barisPengaturan(
                Icons.person_outline_rounded,
                'Edit profil',
                () => _sheetEditProfil(context),
              ),
              _barisPengaturan(
                Icons.lock_outline_rounded,
                'Ubah kata sandi',
                () => _sheetUbahSandi(context),
              ),
              // Keluar dipisah jarak 24 + warna danger, tanpa chevron.
              const SizedBox(height: 24),
              _barisPengaturan(
                Icons.logout_rounded,
                'Keluar',
                _keluar,
                warna: AppColors.danger,
                garisBawah: false,
                // Glyph logout lebih lebar (x 2–22 dari grid 24, ikon lain 4–20);
                // dikecilkan agar tepi kirinya sejajar ikon di atas.
                ukuranIkon: 19,
                trailing: const SizedBox.shrink(),
              ),
            ],
          );
        },
      ),
    );
  }

  // Tulis langsung; StreamBuilder ikut berubah seketika (cache lokal Firestore).
  Future<void> _ubahNotifikasi(BuildContext context, bool v) async {
    try {
      await UserRepo.update({'notifikasi': v});
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    }
  }

  Widget _barisPengaturan(
    IconData ikon,
    String label,
    VoidCallback onTap, {
    Color warna = AppColors.ink,
    Widget? trailing,
    bool garisBawah = true,
    double ukuranIkon = 22,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            border: garisBawah
                ? const Border(bottom: BorderSide(color: AppColors.divider))
                : null,
          ),
          child: Row(
            children: [
              // Kotak tetap 22 agar label selalu mulai di x yang sama.
              SizedBox(
                width: 22,
                child: Icon(ikon, size: ukuranIkon, color: warna),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: ts(14, 600, color: warna)),
              ),
              trailing ??
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

// _Avatar: bulat 48, foto bila ada, fallback inisial.
class _Avatar extends StatelessWidget {
  final String fotoUrl;
  final String inisial;
  const _Avatar({required this.fotoUrl, required this.inisial});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: 48,
        height: 48,
        child: fotoUrl.isEmpty
            ? Container(
                color: AppColors.tint,
                alignment: Alignment.center,
                child: Text(
                  inisial,
                  style: ts(16, 800, color: AppColors.primary),
                ),
              )
            : Image.network(
                fotoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: AppColors.tint,
                  alignment: Alignment.center,
                  child: Text(
                    inisial,
                    style: ts(16, 800, color: AppColors.primary),
                  ),
                ),
              ),
      ),
    );
  }
}

// _SheetEditProfil: avatar + ganti foto + field nama + simpan.
class _SheetEditProfil extends StatefulWidget {
  final String namaAwal;
  final String fotoAwal;
  const _SheetEditProfil({required this.namaAwal, required this.fotoAwal});

  @override
  State<_SheetEditProfil> createState() => _SheetEditProfilState();
}

class _SheetEditProfilState extends State<_SheetEditProfil> {
  late final TextEditingController _namaCtrl;
  late String _fotoUrl;
  Uint8List? _fotoBaru;
  bool _loading = false;
  String? _errNama;
  String? _errUmum;

  static const _maxFotoBytes = 2 * 1024 * 1024; // 2 MB setelah kompresi
  static const _formatFoto = {'jpg', 'jpeg', 'png', 'webp'};

  @override
  void initState() {
    super.initState();
    _namaCtrl = TextEditingController(text: widget.namaAwal);
    _fotoUrl = widget.fotoAwal;
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    super.dispose();
  }

  Future<void> _pilihFoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      imageQuality: 85,
    );
    if (picked == null) return;
    final ext = picked.name.split('.').last.toLowerCase();
    if (!_formatFoto.contains(ext)) {
      setState(() => _errUmum = 'Format foto harus JPG, PNG, atau WEBP.');
      return;
    }
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    if (bytes.length > _maxFotoBytes) {
      setState(() => _errUmum = 'Ukuran foto maksimal 2 MB.');
      return;
    }
    setState(() {
      _fotoBaru = bytes;
      _errUmum = null;
    });
  }

  Future<void> _simpan() async {
    final nama = _namaCtrl.text.trim();
    if (nama.length < 2) {
      setState(() => _errNama = 'Nama minimal 2 karakter.');
      return;
    }

    setState(() {
      _loading = true;
      _errUmum = null;
    });
    try {
      if (_fotoBaru != null) {
        _fotoUrl = await CloudinaryAccService.uploadBytes(_fotoBaru!);
      }

      final data = <String, dynamic>{'nama': nama};
      if (_fotoUrl.isNotEmpty && _fotoUrl != widget.fotoAwal) {
        data['fotoUrl'] = _fotoUrl;
      }
      await UserRepo.update(data);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errUmum = 'Gagal menyimpan: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final inisial = _namaCtrl.text.trim().isEmpty
        ? '?'
        : _namaCtrl.text.trim().substring(0, 1).toUpperCase();

    return _NaikKeyboard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Edit profil', style: ts(18, 800, ls: -0.3)),
          const SizedBox(height: 16),

          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipOval(
                  child: SizedBox(
                    width: 84,
                    height: 84,
                    child: _fotoBaru != null
                        ? Image.memory(_fotoBaru!, fit: BoxFit.cover)
                        : (_fotoUrl.isEmpty
                            ? Container(
                                color: AppColors.tint,
                                alignment: Alignment.center,
                                child: Text(inisial,
                                    style: ts(24, 800,
                                        color: AppColors.primary)),
                              )
                            : Image.network(_fotoUrl, fit: BoxFit.cover)),
                  ),
                ),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Material(
                    color: AppColors.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _loading ? null : _pilihFoto,
                      child: const SizedBox(
                        width: 32,
                        height: 32,
                        child: Icon(Icons.photo_camera_outlined,
                            size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text('Nama',
              style: ts(12, 700, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: _namaCtrl,
            enabled: !_loading,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            style: ts(14, 500),
            decoration: InputDecoration(
              hintText: 'Nama lengkap',
              errorText: _errNama,
            ),
            onChanged: (_) => setState(() => _errNama = null),
          ),
          _ErrorUmum(_errUmum),
          const SizedBox(height: 16),
          PrimaryButton(
            label: _loading ? 'Menyimpan...' : 'Simpan',
            onPressed: _loading ? null : _simpan,
          ),
        ],
      ),
    );
  }
}

// _NaikKeyboard: padding sheet 20 + naik setinggi keyboard.
// Hanya widget ini yang dibangun ulang tiap frame animasi keyboard (isi sheet
// tidak), dan AnimatedPadding menghaluskan inset keyboard yang datang patah-patah.
class _NaikKeyboard extends StatelessWidget {
  final Widget child;
  const _NaikKeyboard({required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    );
  }
}

// _ErrorUmum: teks error 12 danger di atas tombol sheet; kosong bila null.
class _ErrorUmum extends StatelessWidget {
  final String? pesan;
  const _ErrorUmum(this.pesan);

  @override
  Widget build(BuildContext context) {
    if (pesan == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(pesan!, style: ts(12, 600, color: AppColors.danger)),
    );
  }
}

// _SheetUbahSandi: field sandi lama + sandi baru + simpan.
class _SheetUbahSandi extends StatefulWidget {
  const _SheetUbahSandi();

  @override
  State<_SheetUbahSandi> createState() => _SheetUbahSandiState();
}

class _SheetUbahSandiState extends State<_SheetUbahSandi> {
  final _lamaCtrl = TextEditingController();
  final _baruCtrl = TextEditingController();
  final _konfirmasiCtrl = TextEditingController();
  bool _loading = false;
  String? _errLama;
  String? _errBaru;
  String? _errKonfirmasi;
  String? _errUmum;

  @override
  void dispose() {
    _lamaCtrl.dispose();
    _baruCtrl.dispose();
    _konfirmasiCtrl.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    // Validasi lokal dulu; error tampil di bawah field (SnackBar tertutup sheet).
    setState(() {
      _errLama = _lamaCtrl.text.isEmpty ? 'Wajib diisi.' : null;
      _errBaru = _baruCtrl.text.length < 6 ? 'Minimal 6 karakter.' : null;
      _errKonfirmasi = _konfirmasiCtrl.text != _baruCtrl.text
          ? 'Tidak sama dengan kata sandi baru.'
          : null;
      _errUmum = null;
    });
    if (_errLama != null || _errBaru != null || _errKonfirmasi != null) {
      return;
    }

    setState(() => _loading = true);
    try {
      await AuthService.ubahSandi(_lamaCtrl.text, _baruCtrl.text);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final sandiSalah = e is FirebaseAuthException &&
          (e.code == 'wrong-password' || e.code == 'invalid-credential');
      setState(() {
        _loading = false;
        if (sandiSalah) {
          _errLama = 'Kata sandi lama salah.';
        } else {
          _errUmum = AuthService.pesanError(e);
        }
      });
    }
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    String? error,
    VoidCallback hapusError, {
    String? hint,
    bool terakhir = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: ts(12, 700, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          enabled: !_loading,
          obscureText: true,
          textInputAction:
              terakhir ? TextInputAction.done : TextInputAction.next,
          style: ts(14, 500),
          decoration: InputDecoration(hintText: hint, errorText: error),
          onChanged: (_) {
            if (error != null) setState(hapusError);
          },
          onSubmitted: terakhir ? (_) => _simpan() : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _NaikKeyboard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ubah kata sandi', style: ts(18, 800, ls: -0.3)),
          const SizedBox(height: 16),
          _field('Kata sandi lama', _lamaCtrl, _errLama,
              () => _errLama = null),
          const SizedBox(height: 14),
          _field('Kata sandi baru', _baruCtrl, _errBaru,
              () => _errBaru = null,
              hint: 'Minimal 6 karakter'),
          const SizedBox(height: 14),
          _field('Konfirmasi kata sandi baru', _konfirmasiCtrl,
              _errKonfirmasi, () => _errKonfirmasi = null,
              hint: 'Ulangi kata sandi baru', terakhir: true),
          _ErrorUmum(_errUmum),
          const SizedBox(height: 16),
          PrimaryButton(
            label: _loading ? 'Menyimpan...' : 'Simpan',
            onPressed: _loading ? null : _simpan,
          ),
        ],
      ),
    );
  }
}

// _KartuVoucher: kartu 200×76 radius 18, latar tint, border putus-putus caramel
class _KartuVoucher extends StatelessWidget {
  final Voucher v;
  const _KartuVoucher(this.v);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedBorderPainter(),
      child: Container(
        width: 200,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.tint,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(v.kode, style: ts(14, 800, color: AppColors.primary)),
            Text(
              v.info,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ts(12, 500, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// _DashedBorderPainter: border 1.5 putus-putus caramel dengan radius 18
class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.caramel
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5),
          const Radius.circular(18),
        ),
      );
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 9) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}