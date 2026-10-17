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
import 'notification_page.dart';

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

  Future<void> _dialogUbahSandi(BuildContext context) async {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    if (email.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Email akun tidak ditemukan.')),
        );
      return;
    }

    final kirim = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text('Ubah kata sandi', style: ts(16, 800, ls: -0.3)),
        content: Text(
          'Kami akan mengirim tautan ubah kata sandi ke $email. '
          'Buka tautan dari inbox untuk mengatur sandi baru.',
          style: ts(13, 500, color: AppColors.muted, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: ts(13, 700, color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Kirim', style: ts(13, 700, color: AppColors.primary)),
          ),
        ],
      ),
    );

    if (kirim != true) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Tautan ubah sandi dikirim ke $email')),
        );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(AuthService.pesanError(e))),
        );
    }
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
                    Material(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _sheetEditProfil(context),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              _Avatar(fotoUrl: fotoUrl, inisial: inisial),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(namaTampil, style: ts(16, 800)),
                                    Text(
                                      email,
                                      style: ts(12, 500,
                                          color: AppColors.muted),
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
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.ink,
                              ),
                            ],
                          ),
                        ),
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
                'Edit profil',
                () => _sheetEditProfil(context),
              ),
              _barisPengaturan(
                'Ubah kata sandi',
                () => _dialogUbahSandi(context),
              ),
              _barisPengaturan(
                'Notifikasi',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationPage()),
                ),
              ),
              _barisPengaturan('Keluar', _keluar),
            ],
          );
        },
      ),
    );
  }

  Widget _barisPengaturan(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          height: 52,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            children: [
              Expanded(child: Text(label, style: ts(14, 600))),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
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
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() => _fotoBaru = bytes);
  }

  Future<void> _simpan() async {
    final nama = _namaCtrl.text.trim();
    if (nama.length < 2) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Nama terlalu pendek.')));
      return;
    }

    setState(() => _loading = true);
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
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final inisial = _namaCtrl.text.trim().isEmpty
        ? '?'
        : _namaCtrl.text.trim().substring(0, 1).toUpperCase();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
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
            decoration: const InputDecoration(hintText: 'Nama lengkap'),
            onChanged: (_) => setState(() {}),
          ),
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