import 'voucher.dart';

// VoucherRules: aturan validasi & hitung diskon voucher (murni, tanpa Firebase)
// sehingga bisa dipakai Keranjang, sheet Ganti voucher, Akun, dan dites langsung.
extension VoucherRules on Voucher {
  // kedaluwarsa: true bila berlakuSampai sudah lewat (null = tanpa batas)
  bool kedaluwarsa({DateTime? sekarang}) {
    final batas = berlakuSampai;
    return batas != null && (sekarang ?? DateTime.now()).isAfter(batas);
  }

  // alasanTidakBerlaku: null = voucher bisa dipakai untuk subtotal ini,
  // selain itu pesan singkat untuk ditampilkan ke pengguna.
  String? alasanTidakBerlaku(int subtotal, {DateTime? sekarang}) {
    if (!aktif) return 'Voucher tidak aktif.';
    if (kedaluwarsa(sekarang: sekarang)) return 'Voucher sudah kedaluwarsa.';
    if (subtotal < minBelanja) {
      return 'Minimal belanja ${_rupiah(minBelanja)}.';
    }
    return null;
  }

  // hitungDiskon: "persen" = nilai% dari subtotal, selain itu potongan rupiah.
  // Diskon tidak pernah melebihi subtotal.
  int hitungDiskon(int subtotal) {
    final mentah =
        tipe == 'potongan' ? nilai : (subtotal * nilai / 100).round();
    return mentah.clamp(0, subtotal).toInt();
  }
}

String _rupiah(int v) {
  final s = v.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return 'Rp$buf';
}