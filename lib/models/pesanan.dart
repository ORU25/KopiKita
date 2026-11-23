import 'package:cloud_firestore/cloud_firestore.dart';

import 'cart_item.dart';

// statusPesanan: 5 langkah status pesanan untuk stepper (index 0–4)
// Format: [label, catatan]
const statusPesanan = [
  ['Menunggu bayar', 'Bayar di kasir dengan tunai atau QRIS'],
  ['Dibayar', 'Pembayaran dikonfirmasi kasir'],
  ['Diproses', 'Barista sedang membuat pesananmu'],
  ['Siap diambil', 'Kami panggil nomor antreanmu'],
  ['Selesai', 'Terima kasih sudah mampir'],
];

// statusKode: nilai field `status` di Firestore, index sama dengan statusPesanan.
// Index 5 = "batal" (tidak ada di stepper, hanya badge "Dibatalkan" di Riwayat)
const statusKode = ['menunggu_bayar', 'dibayar', 'diproses', 'siap', 'selesai', 'batal'];
const statusBatal = 5;

// Pesanan: model data pesanan (koleksi Firestore `orders/{id}`)
class Pesanan {
  final String id; // ID dokumen Firestore
  final String uid; // Pemilik pesanan (users/{uid})
  final String nomor; // Nomor antrean, mis. "A-014"
  final bool makanDiTempat; // true = Makan di tempat, false = Ambil sendiri
  final int nomorMeja; // Nomor meja (bila makan di tempat)
  final int status; // Index di statusKode (0–4 langkah, 5 = batal)
  final List<CartItem> items; // Item yang dipesan
  final int subtotal, diskon, pajak; // Rincian harga
  final int total; // Total dibayar
  final String? voucher; // Kode voucher yang dipakai
  final DateTime? createdAt; // Waktu dibuat (diisi server)

  const Pesanan({
    this.id = '',
    this.uid = '',
    required this.nomor,
    required this.makanDiTempat,
    required this.nomorMeja,
    required this.status,
    required this.items,
    this.subtotal = 0,
    this.diskon = 0,
    this.pajak = 0,
    required this.total,
    this.voucher,
    this.createdAt,
  });

  bool get batal => status == statusBatal;

  // fromMap: membuat Pesanan dari dokumen Firestore
  factory Pesanan.fromMap(String id, Map<String, dynamic> m) => Pesanan(
        id: id,
        uid: m['uid'] ?? '',
        nomor: m['nomor'] ?? '',
        makanDiTempat: m['makanDiTempat'] ?? false,
        nomorMeja: (m['nomorMeja'] ?? 0) as int,
        status: statusKode.indexOf(m['status'] ?? 'menunggu_bayar'),
        items: [
          for (final i in (m['items'] as List? ?? []))
            CartItem.fromMap(Map<String, dynamic>.from(i)),
        ],
        subtotal: (m['subtotal'] ?? 0) as int,
        diskon: (m['diskon'] ?? 0) as int,
        pajak: (m['pajak'] ?? 0) as int,
        total: (m['total'] ?? 0) as int,
        voucher: m['voucher'],
        createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
      );

  // toMap: data untuk disimpan ke Firestore.
  // createdAt/updatedAt tidak ikut — isi dengan FieldValue.serverTimestamp() saat menulis.
  Map<String, dynamic> toMap() => {
        'uid': uid,
        'nomor': nomor,
        'makanDiTempat': makanDiTempat,
        'nomorMeja': makanDiTempat ? nomorMeja : null,
        'items': [for (final i in items) i.toMap()],
        'subtotal': subtotal,
        'diskon': diskon,
        'pajak': pajak,
        'total': total,
        'voucher': voucher,
        'status': statusKode[status],
      };
}
