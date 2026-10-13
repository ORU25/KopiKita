// CartItem: model data untuk satu item di keranjang
// Menyimpan produk beserta pilihan kustomisasinya (ukuran, suhu, gula, es, add-on)
class CartItem {
  final String nama; // Nama produk
  final int harga; // Harga satuan SETELAH kustomisasi (dasar + Large + add-on)
  final bool makanan; // true = produk makanan (tanpa opsi minuman)
  final String ukuran; // "Regular" / "Large"
  final String suhu; // "Panas" / "Es"
  final String gula; // "Tanpa" / "Sedikit" / "Normal" / "Manis"
  final String es; // "Sedikit" / "Normal" / "Banyak" (hanya bila suhu Es)
  final List<String> addOn; // Daftar add-on terpilih, mis. ["Extra shot"]
  final String catatan; // Catatan untuk barista (opsional)

  // STATE: quantity di keranjang — satu-satunya field yang berubah
  final int jumlah;

  // Constructor: membuat instance CartItem
  // Parameter opsi memiliki nilai default sesuai pilihan default di Kustomisasi
  const CartItem({
    required this.nama,
    required this.harga,
    this.makanan = false,
    this.ukuran = 'Regular',
    this.suhu = 'Es',
    this.gula = 'Normal',
    this.es = 'Normal',
    this.addOn = const [],
    this.catatan = '',
    this.jumlah = 1,
  });

  // Getter totalHarga = DERIVED STATE (harga satuan x jumlah)
  int get totalHarga => harga * jumlah;

  // labelOpsi: teks ringkas opsi untuk Keranjang
  // Contoh: "Large · Es · Gula normal · Es normal · + Extra shot"
  String get labelOpsi {
    if (makanan) return catatan; // Makanan hanya menampilkan catatan
    final bagian = <String>[
      ukuran,
      suhu,
      'Gula ${gula.toLowerCase()}',
      if (suhu == 'Es') 'Es ${es.toLowerCase()}', // Level es hanya untuk minuman es
      ...addOn.map((a) => '+ $a'),
    ];
    return bagian.join(' · ');
  }

  // labelSingkat: teks pendek untuk detail pesanan, mis. "Kopi Susu Kita (Large, Es)"
  String get labelSingkat => makanan ? nama : '$nama ($ukuran, $suhu)';

  // kunci: identitas unik item di keranjang
  // Produk yang sama dengan opsi berbeda dianggap item berbeda
  String get kunci => '$nama|$labelOpsi|$catatan';

  // copyWith = pola immutable object
  // Kegunaan: buat salinan CartItem baru dengan jumlah diubah
  CartItem copyWith({int? jumlah}) {
    return CartItem(
      nama: nama,
      harga: harga,
      makanan: makanan,
      ukuran: ukuran,
      suhu: suhu,
      gula: gula,
      es: es,
      addOn: addOn,
      catatan: catatan,
      jumlah: jumlah ?? this.jumlah, // Gunakan jumlah baru atau lama
    );
  }
}
