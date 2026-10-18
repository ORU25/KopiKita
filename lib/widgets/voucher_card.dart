import 'package:flutter/material.dart';

import '../models/voucher.dart';
import '../theme/app_theme.dart';

// KartuVoucherItem: baris voucher (kode, info, catatan status) untuk daftar vertikal.
// onTap null = tidak bisa dipilih (diredupkan).
class KartuVoucherItem extends StatelessWidget {
  final Voucher voucher;
  final String? catatan; // Alasan tidak berlaku / info tambahan
  final bool terpilih;
  final VoidCallback? onTap;
  final Widget? trailing;

  const KartuVoucherItem({
    super.key,
    required this.voucher,
    this.catatan,
    this.terpilih = false,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.55 : 1,
      child: Material(
        color: AppColors.tint,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: terpilih ? AppColors.primary : AppColors.outline,
                width: terpilih ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.sell_outlined,
                    size: 20, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(voucher.kode,
                          style: ts(14, 800, color: AppColors.primary)),
                      const SizedBox(height: 2),
                      Text(voucher.info,
                          style: ts(12, 500, color: AppColors.textSecondary)),
                      if (catatan != null && catatan!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(catatan!,
                            style: ts(12, 600, color: AppColors.promoLabel)),
                      ],
                    ],
                  ),
                ),
                if (trailing != null)
                  trailing!
                else if (terpilih)
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}