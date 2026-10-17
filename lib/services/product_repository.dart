import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/produk.dart';

/// ProductRepository: akses koleksi products/{id} (realtime).
/// Menu, Beranda (Paling laris), Cari, dan Favorit memakai stream ini lewat
/// StreamBuilder — tanpa provider baru. Perubahan dari web Staf/Admin
/// (mis. toggle Habis) langsung sampai ke layar.
class ProductRepository {
  static final _db = FirebaseFirestore.instance;

  /// Stream seluruh produk, terurut menurut `urutan` lalu nama.
  /// Setiap pemanggilan membuat stream BARU: simpan hasilnya di State
  /// (jangan panggil di build) agar StreamBuilder tidak berlangganan ulang.
  ///
  /// ponytail: diurutkan di klien (bukan orderBy) supaya dokumen tanpa
  /// field `urutan` tetap tampil; katalog kecil jadi aman.
  static Stream<List<Produk>> stream() {
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
    });
  }
}
