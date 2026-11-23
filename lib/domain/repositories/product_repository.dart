import '../entities/produk.dart';

/// ProductRepository: KONTRAK akses katalog produk (koleksi products).
/// Hanya menyebut APA yang tersedia, bukan dari mana datanya. Implementasi
/// sungguhan: data/repositories/product_repository_firestore.dart; saat tes
/// diganti repository palsu. Disuntikkan lewat Provider (config/dependensi.dart).
abstract class ProductRepository {
  /// Stream seluruh produk (realtime), terurut menurut `urutan` lalu nama.
  /// Setiap pemanggilan membuat stream BARU: simpan hasilnya di State
  /// (jangan panggil di build) agar StreamBuilder tidak berlangganan ulang.
  Stream<List<Produk>> stream();
}
