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
  // Kustomisasi per produk (diatur admin di dasbor web):
  final List<String> suhu; // Pilihan suhu: ["Panas","Es"] / ["Es"] / ["Panas"] / [] (makanan)
  final bool bisaLarge; // true = ada pilihan ukuran Large
  final List<String>? addOn; // Nama add-on minuman dari config/menu yang boleh dipilih; null = semua (data lama)

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
    List<String>? suhu,
    bool? bisaLarge,
    this.addOn,
  })  : suhu = suhu ?? (kategori == 'Makanan' ? const [] : const ['Panas', 'Es']),
        bisaLarge = bisaLarge ?? kategori != 'Makanan';

  // makanan: true bila produk termasuk kategori Makanan
  bool get makanan => kategori == 'Makanan';

  // addOnBerlaku: add-on yang ditampilkan di Kustomisasi, dari katalog config/menu.
  // Makanan tidak punya add-on. Minuman lama tanpa field addOn: semua add-on katalog.
  List<String> addOnBerlaku(Iterable<String> katalog) => [
        for (final a in katalog)
          if (!makanan && (addOn?.contains(a) ?? true)) a,
      ];

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
        suhu: (m['suhu'] as List?)?.cast<String>(),
        bisaLarge: m['bisaLarge'] as bool?,
        addOn: (m['addOn'] as List?)?.cast<String>(),
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
        'suhu': suhu,
        'bisaLarge': bisaLarge,
        'addOn': addOn,
      };
}

// kategoriMenu: urutan kategori pada chip filter Menu
const kategoriMenu = ['Rekomendasi', 'Kopi', 'Non-Kopi', 'Makanan'];
