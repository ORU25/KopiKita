// Data dummy statis untuk UI (sementara, nanti diganti Firestore)
// Isi data mengikuti contoh di kopikita-design/design/source/*.dc.html
import '../models/cart_item.dart';

// Produk: model data satu menu
class Produk {
  final String nama; // Nama menu
  final String deskripsi; // Deskripsi singkat
  final int harga; // Harga dasar
  final String kategori; // "Kopi" / "Non-Kopi" / "Makanan"
  final bool habis; // true = stok habis

  const Produk({
    required this.nama,
    required this.deskripsi,
    required this.harga,
    required this.kategori,
    this.habis = false,
  });

  // makanan: true bila produk termasuk kategori Makanan
  bool get makanan => kategori == 'Makanan';
}

// kategoriMenu: urutan kategori pada chip filter Menu
const kategoriMenu = ['Rekomendasi', 'Kopi', 'Non-Kopi', 'Makanan'];

// daftarMenu: katalog menu lengkap
const daftarMenu = [
  Produk(nama: 'Kopi Susu Kita', deskripsi: 'Espresso, susu segar, dan gula aren', harga: 22000, kategori: 'Kopi'),
  Produk(nama: 'Caramel Latte', deskripsi: 'Espresso, susu, dan sirup karamel', harga: 28000, kategori: 'Kopi'),
  Produk(nama: 'Americano', deskripsi: 'Espresso dan air, tegas dan bersih', harga: 18000, kategori: 'Kopi'),
  Produk(nama: 'Matcha Latte', deskripsi: 'Matcha dan susu yang lembut', harga: 26000, kategori: 'Non-Kopi', habis: true),
  Produk(nama: 'Cokelat Panas', deskripsi: 'Cokelat pekat dengan susu hangat', harga: 24000, kategori: 'Non-Kopi'),
  Produk(nama: 'Croissant Butter', deskripsi: 'Renyah, beraroma mentega, disajikan hangat', harga: 20000, kategori: 'Makanan'),
  Produk(nama: 'Roti Bakar Cokelat', deskripsi: 'Roti tebal dengan cokelat leleh', harga: 18000, kategori: 'Makanan'),
];

// rekomendasi: kartu horizontal di bagian atas Menu
const rekomendasi = [
  Produk(nama: 'Kopi Susu Kita', deskripsi: 'Paling sering dipesan', harga: 22000, kategori: 'Kopi'),
  Produk(nama: 'Es Kopi Gula Aren', deskripsi: 'Segar dan manis alami', harga: 24000, kategori: 'Kopi'),
  Produk(nama: 'Caramel Latte', deskripsi: 'Hangat, lembut, dan manis', harga: 28000, kategori: 'Kopi'),
  Produk(nama: 'Cappuccino', deskripsi: 'Busa susu tebal dan creamy', harga: 24000, kategori: 'Kopi'),
];

// gambarMenu: foto produk SEMENTARA dari assets/images (nanti Cloudinary).
// Produk tanpa entri (mis. Roti Bakar Cokelat) memakai placeholder ikon.
const gambarMenu = {
  'Kopi Susu Kita': 'assets/images/CoffeLatte.png',
  'Es Kopi Gula Aren': 'assets/images/CoffeLatte.png',
  'Caramel Latte': 'assets/images/CoffeLatte.png',
  'Cappuccino': 'assets/images/Cappucino.png',
  'Americano': 'assets/images/Espresso.png',
  'Matcha Latte': 'assets/images/MatchaLatte.png',
  'Cokelat Panas': 'assets/images/Chocolate.png',
  'Croissant Butter': 'assets/images/Croissant.png',
};

// addOnMenu: daftar add-on minuman beserta harganya (Kustomisasi)
const addOnMenu = {'Extra shot': 5000, 'Oat milk': 6000, 'Sirup karamel': 4000};

// hargaLarge: tambahan harga untuk ukuran Large
const hargaLarge = 4000;

// Voucher: model data voucher milik pengguna (Akun)
class Voucher {
  final String kode; // Kode voucher
  final String info; // Keterangan singkat
  const Voucher(this.kode, this.info);
}

const voucherSaya = [
  Voucher('KOPIKITA20', 'Diskon 20% · min. Rp50.000'),
  Voucher('HEMAT5RB', 'Potongan Rp5.000 · s.d. 31 Okt'),
];

// statusPesanan: 5 langkah status pesanan sesuai status Firestore
// Format: [label, catatan]
const statusPesanan = [
  ['Menunggu bayar', 'Bayar di kasir dengan tunai atau QRIS'],
  ['Dibayar', 'Pembayaran dikonfirmasi kasir'],
  ['Diproses', 'Barista sedang membuat pesananmu'],
  ['Siap diambil', 'Kami panggil nomor antreanmu'],
  ['Selesai', 'Terima kasih sudah mampir'],
];

// Pesanan: model data pesanan aktif
class Pesanan {
  final String nomor; // Nomor antrean, mis. "A-014"
  final bool makanDiTempat; // true = Makan di tempat, false = Ambil sendiri
  final int nomorMeja; // Nomor meja (bila makan di tempat)
  final int status; // Index langkah di statusPesanan (0–4)
  final List<CartItem> items; // Item yang dipesan
  final int total; // Total dibayar

  const Pesanan({
    required this.nomor,
    required this.makanDiTempat,
    required this.nomorMeja,
    required this.status,
    required this.items,
    required this.total,
  });
}

// contohPesananAktif: pesanan aktif awal agar layar Pesanan tidak kosong
const contohPesananAktif = Pesanan(
  nomor: 'A-014',
  makanDiTempat: true,
  nomorMeja: 7,
  status: 2, // "Diproses"
  items: [
    CartItem(nama: 'Kopi Susu Kita', harga: 31000, ukuran: 'Large', addOn: ['Extra shot']),
    CartItem(nama: 'Caramel Latte', harga: 28000, suhu: 'Panas', gula: 'Sedikit', jumlah: 2),
  ],
  total: 76560,
);

// RiwayatPesanan: model data satu baris riwayat
class RiwayatPesanan {
  final String ringkasan; // Ringkasan item, mis. "Americano, Croissant Butter"
  final String tanggal; // Tanggal singkat, mis. "8 Okt"
  final String status; // "Selesai" / "Dibatalkan"
  final int total; // Total pesanan
  const RiwayatPesanan(this.ringkasan, this.tanggal, this.status, this.total);
}

// riwayatPerBulan: riwayat pesanan dikelompokkan per bulan
const riwayatPerBulan = {
  'Oktober 2026': [
    RiwayatPesanan('Americano, Croissant Butter', '8 Okt', 'Selesai', 38000),
    RiwayatPesanan('Kopi Susu Kita ×2', '3 Okt', 'Selesai', 44000),
  ],
  'September 2026': [
    RiwayatPesanan('Caramel Latte', '28 Sep', 'Selesai', 28000),
    RiwayatPesanan('Cokelat Panas, Roti Bakar Cokelat', '21 Sep', 'Selesai', 42000),
    RiwayatPesanan('Matcha Latte', '14 Sep', 'Dibatalkan', 26000),
  ],
};
