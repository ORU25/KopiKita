import 'dart:convert';

import '../../domain/entities/cart_item.dart';
import '../../domain/hasil.dart';
import 'database_service.dart';

/// CartLocalRepository: menyimpan keranjang ke SQLite lokal.
/// Digunakan untuk persistensi keranjang antar restart aplikasi.
class CartLocalRepository {
  CartLocalRepository(this._dbService);

  final DatabaseService _dbService;

  static const String _tabel = 'cart_items';

  /// Mengubah CartItem menjadi Map untuk database.
  Map<String, Object?> _keBaris(CartItem item, {required int createdAt, required int updatedAt}) {
    return {
      'product_id': item.productId,
      'nama': item.nama,
      'harga': item.harga,
      'makanan': item.makanan ? 1 : 0,
      'ukuran': item.ukuran,
      'suhu': item.suhu,
      'gula': item.gula,
      'es': item.es,
      'add_on': jsonEncode(item.addOn),
      'catatan': item.catatan,
      'jumlah': item.jumlah,
      'gambar_url': item.gambarUrl,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Mengubah baris database menjadi CartItem.
  CartItem _dariBaris(Map<String, Object?> baris) {
    return CartItem(
      productId: baris['product_id'] as String,
      gambarUrl: baris['gambar_url'] as String,
      nama: baris['nama'] as String,
      harga: baris['harga'] as int,
      makanan: (baris['makanan'] as int) == 1,
      ukuran: baris['ukuran'] as String,
      suhu: baris['suhu'] as String,
      gula: baris['gula'] as String,
      es: baris['es'] as String,
      addOn: List<String>.from(jsonDecode(baris['add_on'] as String)),
      catatan: baris['catatan'] as String,
      jumlah: baris['jumlah'] as int,
    );
  }

  /// Menyimpan seluruh isi keranjang (replace all).
  Future<Hasil<void>> simpanSemua(List<CartItem> items) async {
    try {
      final db = await _dbService.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.transaction((txn) async {
        // Hapus semua item lama
        await txn.delete(_tabel);

        // Insert item baru
        if (items.isNotEmpty) {
          final batch = txn.batch();
          for (var i = 0; i < items.length; i++) {
            batch.insert(_tabel, _keBaris(items[i], createdAt: now, updatedAt: now));
          }
          await batch.commit(noResult: true);
        }
      });
      return const Berhasil(null);
    } catch (e) {
      return Gagal(LayananBermasalah('simpan_keranjang: $e'));
    }
  }

  /// Memuat seluruh isi keranjang dari database.
  Future<Hasil<List<CartItem>>> muatSemua() async {
    try {
      final db = await _dbService.database;
      final baris = await db.query(_tabel, orderBy: 'created_at ASC');
      final items = baris.map(_dariBaris).toList();
      return Berhasil(items);
    } catch (e) {
      return Gagal(LayananBermasalah('muat_keranjang: $e'));
    }
  }

  /// Menghapus semua item keranjang (setelah checkout berhasil).
  Future<Hasil<void>> hapusSemua() async {
    try {
      final db = await _dbService.database;
      await db.delete(_tabel);
      return const Berhasil(null);
    } catch (e) {
      return Gagal(LayananBermasalah('hapus_keranjang: $e'));
    }
  }
}