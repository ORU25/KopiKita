import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/voucher.dart';
import '../models/voucher_rules.dart';
import '../providers/cart_provider.dart';
import '../services/user_repo.dart';
import '../services/voucher_repository.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import 'state_views.dart';
import 'voucher_card.dart';

// bukaGantiVoucher: sheet pilih voucher dari Keranjang (link "Ganti").
// Daftar = users/{uid}.voucher × vouchers/{kode}; ada juga input kode manual.
Future<void> bukaGantiVoucher(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.bg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const _GantiVoucherSheet(),
  );
}

class _GantiVoucherSheet extends StatefulWidget {
  const _GantiVoucherSheet();

  @override
  State<_GantiVoucherSheet> createState() => _GantiVoucherSheetState();
}

class _GantiVoucherSheetState extends State<_GantiVoucherSheet> {
  final TextEditingController _kode = TextEditingController();
  late Future<List<Voucher>> _daftar = _muat();
  String? _galat;
  bool _proses = false;

  @override
  void dispose() {
    _kode.dispose();
    super.dispose();
  }

  Future<List<Voucher>> _muat() async {
    final data = await UserRepo.ambil();
    return VoucherRepository.ambilBanyak(UserRepo.voucherDari(data));
  }

  void _muatUlang() => setState(() => _daftar = _muat());

  // _pilih: validasi lewat CartProvider; sukses → tutup sheet, gagal → tampilkan galat
  Future<void> _pilih(String kode) async {
    if (_proses) return;
    setState(() {
      _proses = true;
      _galat = null;
    });
    final galat = await context.read<CartProvider>().terapkanVoucher(kode);
    if (!mounted) return;
    if (galat == null) {
      Navigator.pop(context);
    } else {
      setState(() {
        _galat = galat;
        _proses = false;
      });
    }
  }

  void _tanpaVoucher() {
    context.read<CartProvider>().lepasVoucher();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Text('Pilih voucher', style: ts(18, 800, ls: -0.3)),
          ),
          // Input kode manual
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _kode,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.done,
                    style: ts(14, 500),
                    onSubmitted: (v) => _pilih(v),
                    decoration: const InputDecoration(
                      fillColor: AppColors.surface,
                      hintText: 'Masukkan kode voucher',
                      prefixIcon: Icon(Icons.confirmation_number_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _proses ? null : () => _pilih(_kode.text),
                  child:
                      Text('Pakai', style: ts(14, 700, color: AppColors.primary)),
                ),
              ],
            ),
          ),
          if (_galat != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 20, 0),
              child: Text(_galat!,
                  style: ts(12, 600, color: AppColors.promoLabel)),
            ),
          const SizedBox(height: 12),
          // Daftar voucher milik user
          Flexible(
            child: FutureBuilder<List<Voucher>>(
              future: _daftar,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.5,
                    child: const LoadingView(),
                  );
                }
                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text('Gagal memuat voucher.',
                            style: ts(13, 600, color: AppColors.muted)),
                        TextButton(
                          onPressed: _muatUlang,
                          child: Text('Coba lagi',
                              style: ts(14, 700, color: AppColors.primary)),
                        ),
                      ],
                    ),
                  );
                }
                final daftar = snap.data ?? const <Voucher>[];
                return ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    _TanpaVoucher(
                      terpilih: cart.voucher == null,
                      onTap: _tanpaVoucher,
                    ),
                    for (final v in daftar) ...[
                      const SizedBox(height: 10),
                      Builder(builder: (_) {
                        final alasan = v.alasanTidakBerlaku(cart.subtotal);
                        return KartuVoucherItem(
                          voucher: v,
                          catatan: alasan,
                          terpilih: cart.voucher == v.kode,
                          onTap: alasan == null && !_proses
                              ? () => _pilih(v.kode)
                              : null,
                        );
                      }),
                    ],
                    if (daftar.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text('Kamu belum punya voucher.',
                            textAlign: TextAlign.center,
                            style: ts(13, 500, color: AppColors.muted)),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// _TanpaVoucher: opsi untuk melepas voucher
class _TanpaVoucher extends StatelessWidget {
  final bool terpilih;
  final VoidCallback onTap;
  const _TanpaVoucher({required this.terpilih, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: terpilih ? AppColors.primary : AppColors.outline,
            width: terpilih ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.block_rounded, size: 20, color: AppColors.muted),
            const SizedBox(width: 12),
            Expanded(child: Text('Tanpa voucher', style: ts(14, 700))),
            if (terpilih)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}