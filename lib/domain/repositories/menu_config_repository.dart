import '../entities/menu_config.dart';

/// MenuConfigRepository: KONTRAK pengaturan harga (pajak, Large, add-on).
abstract class MenuConfigRepository {
  /// Tidak pernah gagal: bila tidak terbaca, kembalikan MenuConfig bawaan.
  Future<MenuConfig> ambil();
}
