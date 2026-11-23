import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/repositories/product_repository.dart';
import '../../domain/entities/produk.dart';
import '../firebase_kegagalan.dart';

/// ProductRepositoryFirestore: implementasi ProductRepository di atas koleksi
/// products/{id} (realtime).
/// Menu, Beranda (Paling laris), Cari, dan Favorit memakai stream ini lewat
/// StreamBuilder. Perubahan dari web Staf/Admin (mis. toggle Habis) langsung
/// sampai ke layar.
class ProductRepositoryFirestore implements ProductRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// ponytail: diurutkan di klien (bukan orderBy) supaya dokumen tanpa
  /// field `urutan` tetap tampil; katalog kecil jadi aman.
  @override
  Stream<List<Produk>> stream() {
    return _db.collection('products').snapshots().map((snap) {
      final daftar = <Produk>[];
      for (final d in snap.docs) {
        try {
          daftar.add(Produk.fromMap(d.id, d.data()));
        } catch (_) {
          // Dokumen rusak (tipe field salah) dilewati, tidak menjatuhkan menu
        }
      }
      daftar.sort((a, b) {
        final u = a.urutan.compareTo(b.urutan);
        return u != 0 ? u : a.nama.compareTo(b.nama);
      });
      return daftar;
    }).terjemahkanGalat();
  }
}
