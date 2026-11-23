import '../entities/notifikasi.dart';

/// NotifikasiRepository: KONTRAK kotak notifikasi milik user.
abstract class NotifikasiRepository {
  Future<void> tambah({
    required String judul,
    required String pesan,
    required String orderId,
  });

  /// Stream notifikasi terbaru di atas.
  Stream<List<Notifikasi>> stream();

  Future<void> tandaiSemuaDibaca();
}
