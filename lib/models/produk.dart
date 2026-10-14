// Produk: model data satu menu (koleksi Firestore `products/{id}`)
class Produk {
  final String id; // ID dokumen Firestore, mis. "kopi-susu-kita"
  final String nama; // Nama menu
  final String deskripsi; // Deskripsi singkat
  final int harga; // Harga dasar
  final String kategori; // "Kopi" / "Non-Kopi" / "Makanan"
  final bool habis; // true = stok habis
  final String gambarUrl; // URL foto Cloudinary ('' = belum ada)
  final bool rekomendasi; // true = tampil di Rekomendasi / Paling laris
  final int urutan; // Urutan tampil dalam kategori

  const Produk({
    this.id = '',
    required this.nama,
    required this.deskripsi,
    required this.harga,
    required this.kategori,
    this.habis = false,
    this.gambarUrl = '',
    this.rekomendasi = false,
    this.urutan = 0,
  });

  // makanan: true bila produk termasuk kategori Makanan
  bool get makanan => kategori == 'Makanan';

  // fromMap: membuat Produk dari dokumen Firestore
  factory Produk.fromMap(String id, Map<String, dynamic> m) => Produk(
        id: id,
        nama: m['nama'] ?? '',
        deskripsi: m['deskripsi'] ?? '',
        harga: (m['harga'] ?? 0) as int,
        kategori: m['kategori'] ?? 'Kopi',
        habis: m['habis'] ?? false,
        gambarUrl: m['gambarUrl'] ?? '',
        rekomendasi: m['rekomendasi'] ?? false,
        urutan: (m['urutan'] ?? 0) as int,
      );

  // toMap: data untuk disimpan ke Firestore (id = nama dokumen, tidak ikut disimpan)
  Map<String, dynamic> toMap() => {
        'nama': nama,
        'deskripsi': deskripsi,
        'harga': harga,
        'kategori': kategori,
        'habis': habis,
        'gambarUrl': gambarUrl,
        'rekomendasi': rekomendasi,
        'urutan': urutan,
      };
}

// kategoriMenu: urutan kategori pada chip filter Menu
const kategoriMenu = ['Rekomendasi', 'Kopi', 'Non-Kopi', 'Makanan'];
