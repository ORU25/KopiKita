import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../domain/entities/produk.dart';
import '../../domain/hasil.dart';
import 'database_service.dart';

/// ProductCacheRepository: cache produk untuk akses offline dan loading cepat.
/// Mengikuti pola "local-first, then server" dari Pertemuan 11.
class ProductCacheRepository {
  ProductCacheRepository(this._dbService);

  final DatabaseService _dbService;

  static const String _tabel = 'cached_products';
  static const String _tabelRecent = 'recently_viewed';

  /// Mengubah Produk menjadi Map untuk database.
  Map<String, Object?> _keBaris(Produk produk) {
    return {
      'id': produk.id,
      'nama': produk.nama,
      'deskripsi': produk.deskripsi,
      'harga': produk.harga,
      'kategori': produk.kategori,
      'habis': produk.habis ? 1 : 0,
      'gambar_url': produk.gambarUrl,
      'rekomendasi': produk.rekomendasi ? 1 : 0,
      'urutan': produk.urutan,
      'suhu': jsonEncode(produk.suhu),
      'bisa_large': produk.bisaLarge ? 1 : 0,
      'add_on': produk.addOn != null ? jsonEncode(produk.addOn!) : null,
      'cached_at': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Mengubah baris database menjadi Produk.
  Produk _dariBaris(Map<String, Object?> baris) {
    return Produk.fromMap(
      baris['id'] as String,
      {
        'nama': baris['nama'],
        'deskripsi': baris['deskripsi'],
        'harga': baris['harga'],
        'kategori': baris['kategori'],
        'habis': (baris['habis'] as int) == 1,
        'gambarUrl': baris['gambar_url'],
        'rekomendasi': (baris['rekomendasi'] as int) == 1,
        'urutan': baris['urutan'],
        'suhu': List<String>.from(
          jsonDecode(baris['suhu'] as String) as List,
        ),
        'bisaLarge': (baris['bisa_large'] as int) == 1,
        'addOn': baris['add_on'] == null
            ? null
            : List<String>.from(
                jsonDecode(baris['add_on'] as String) as List,
              ),
      },
    );
  }

  /// Menyimpan daftar produk ke cache (replace all).
  Future<Hasil<void>> simpanSemua(List<Produk> produkList) async {
    try {
      final db = await _dbService.database;

      await db.transaction((txn) async {
        await txn.delete(_tabel);

        if (produkList.isNotEmpty) {
          final batch = txn.batch();
          for (final produk in produkList) {
            batch.insert(_tabel, _keBaris(produk));
          }
          await batch.commit(noResult: true);
        }
      });
      return const Berhasil(null);
    } catch (e) {
      return Gagal(LayananBermasalah('simpan_cache_produk: $e'));
    }
  }

  /// Memuat semua produk dari cache.
  Future<Hasil<List<Produk>>> muatSemua() async {
    try {
      final db = await _dbService.database;
      final baris = await db.query(_tabel, orderBy: 'urutan ASC, nama ASC');
      final produk = baris.map(_dariBaris).toList();
      return Berhasil(produk);
    } catch (e) {
      return Gagal(LayananBermasalah('muat_cache_produk: $e'));
    }
  }

  /// Memuat produk berdasarkan kategori dari cache.
  Future<Hasil<List<Produk>>> muatByKategori(String kategori) async {
    try {
      final db = await _dbService.database;
      final baris = await db.query(
        _tabel,
        where: 'kategori = ?',
        whereArgs: [kategori],
        orderBy: 'urutan ASC, nama ASC',
      );
      final produk = baris.map(_dariBaris).toList();
      return Berhasil(produk);
    } catch (e) {
      return Gagal(LayananBermasalah('muat_cache_kategori: $e'));
    }
  }

  /// Mencari produk dari cache.
  Future<Hasil<List<Produk>>> cari(String kataKunci) async {
    try {
      final db = await _dbService.database;
      final kunci = '%${kataKunci.toLowerCase()}%';
      final baris = await db.query(
        _tabel,
        where: 'LOWER(nama) LIKE ? OR LOWER(deskripsi) LIKE ?',
        whereArgs: [kunci, kunci],
        orderBy: 'urutan ASC, nama ASC',
      );
      final produk = baris.map(_dariBaris).toList();
      return Berhasil(produk);
    } catch (e) {
      return Gagal(LayananBermasalah('cari_cache_produk: $e'));
    }
  }

  /// Menandai produk sebagai baru dilihat (untuk recently viewed).
  Future<void> tandaiDilihat(String productId) async {
    try {
      final db = await _dbService.database;
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.insert(
        _tabelRecent,
        {'product_id': productId, 'viewed_at': now},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {
      // Abaikan error - recently viewed non-critical
    }
  }

  /// Mendapatkan produk yang baru dilihat (maksimal 10).
  Future<Hasil<List<Produk>>> getRecentlyViewed({int limit = 10}) async {
    try {
      final db = await _dbService.database;
      final baris = await db.rawQuery('''
        SELECT p.* FROM $_tabel p
        JOIN $_tabelRecent r ON p.id = r.product_id
        ORDER BY r.viewed_at DESC
        LIMIT ?
      ''', [limit]);
      final produk = baris.map(_dariBaris).toList();
      return Berhasil(produk);
    } catch (e) {
      return Gagal(LayananBermasalah('recently_viewed: $e'));
    }
  }

  /// Menghapus cache lama (lebih dari 7 hari).
  Future<void> bersihkanCacheLama() async {
    try {
      final db = await _dbService.database;
      final batas = DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch;
      await db.delete(_tabel, where: 'cached_at < ?', whereArgs: [batas]);
      await db.delete(_tabelRecent, where: 'viewed_at < ?', whereArgs: [batas]);
    } catch (_) {
      // Abaikan error
    }
  }
}