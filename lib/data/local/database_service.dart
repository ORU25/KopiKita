import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// DatabaseService: membuka database SQLite sekali saja (singleton pattern).
/// Mengelola tabel: cart_items, cached_products, recently_viewed.
class DatabaseService {
  static const String _namaBerkas = 'kopikita.db';

  DatabaseService._internal();

  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;

  Future<Database>? _database;

  /// Getter database: dibuka sekali, pemanggilan berikutnya mengembalikan Future yang sama.
  Future<Database> get database => _database ??= _buka();

  Future<Database> _buka() async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    }

    String path;
    if (kIsWeb) {
      path = _namaBerkas;
    } else {
      final docsDir = await getApplicationDocumentsDirectory();
      path = join(docsDir.path, _namaBerkas);
    }

    return openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        // Tabel keranjang lokal (persisten antar restart aplikasi)
        await db.execute('''
          CREATE TABLE cart_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            product_id TEXT NOT NULL,
            nama TEXT NOT NULL,
            harga INTEGER NOT NULL,
            makanan INTEGER NOT NULL DEFAULT 0,
            ukuran TEXT NOT NULL,
            suhu TEXT NOT NULL,
            gula TEXT NOT NULL,
            es TEXT NOT NULL,
            add_on TEXT NOT NULL, -- JSON array
            catatan TEXT NOT NULL DEFAULT '',
            jumlah INTEGER NOT NULL DEFAULT 1,
            gambar_url TEXT NOT NULL DEFAULT '',
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');

        // Tabel cache produk (untuk offline)
        await db.execute('''
          CREATE TABLE cached_products (
            id TEXT PRIMARY KEY,
            nama TEXT NOT NULL,
            deskripsi TEXT NOT NULL,
            harga INTEGER NOT NULL,
            kategori TEXT NOT NULL,
            habis INTEGER NOT NULL DEFAULT 0,
            gambar_url TEXT NOT NULL DEFAULT '',
            rekomendasi INTEGER NOT NULL DEFAULT 0,
            urutan INTEGER NOT NULL DEFAULT 0,
            suhu TEXT NOT NULL, -- JSON array
            bisa_large INTEGER NOT NULL DEFAULT 1,
            add_on TEXT, -- JSON array, nullable
            cached_at INTEGER NOT NULL
          )
        ''');

        // Tabel produk yang baru dilihat (recently viewed)
        await db.execute('''
          CREATE TABLE recently_viewed (
            product_id TEXT PRIMARY KEY,
            viewed_at INTEGER NOT NULL
          )
        ''');

        // Index untuk performa query
        await db.execute('CREATE INDEX idx_cached_products_kategori ON cached_products(kategori)');
        await db.execute('CREATE INDEX idx_recently_viewed_viewed_at ON recently_viewed(viewed_at DESC)');
      },
    );
  }

  Future<void> tutup() async {
    final db = _database;
    _database = null;
    if (db != null) {
      final database = await db;
      await database.close();
    }
  }
}