import 'package:cloud_firestore/cloud_firestore.dart';

// Voucher: model data voucher (koleksi Firestore `vouchers/{kode}`)
class Voucher {
  final String kode; // Kode voucher = ID dokumen, mis. "KOPIKITA20"
  final String info; // Keterangan singkat
  final String tipe; // "persen" / "potongan"
  final int nilai; // 20 (persen) atau 5000 (rupiah)
  final int minBelanja; // Subtotal minimum agar voucher berlaku
  final DateTime? berlakuSampai; // null = tanpa batas
  final bool aktif;

  const Voucher(
    this.kode,
    this.info, {
    this.tipe = 'persen',
    this.nilai = 0,
    this.minBelanja = 0,
    this.berlakuSampai,
    this.aktif = true,
  });

  // fromMap: membuat Voucher dari dokumen Firestore
  factory Voucher.fromMap(String kode, Map<String, dynamic> m) => Voucher(
        kode,
        m['info'] ?? '',
        tipe: m['tipe'] ?? 'persen',
        nilai: (m['nilai'] ?? 0) as int,
        minBelanja: (m['minBelanja'] ?? 0) as int,
        berlakuSampai: (m['berlakuSampai'] as Timestamp?)?.toDate(),
        aktif: m['aktif'] ?? false,
      );

  // toMap: data untuk disimpan ke Firestore (kode = nama dokumen)
  Map<String, dynamic> toMap() => {
        'info': info,
        'tipe': tipe,
        'nilai': nilai,
        'minBelanja': minBelanja,
        'berlakuSampai':
            berlakuSampai == null ? null : Timestamp.fromDate(berlakuSampai!),
        'aktif': aktif,
      };
}
