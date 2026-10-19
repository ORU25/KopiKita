import '../models/pesanan.dart';
import 'notif_repository.dart';
import 'order_repository.dart';

class NotifPesanan {
  static final Map<String, int> _statusTerakhir = {};
  static bool _sudahPasang = false;

  static void pasang() {
    if (_sudahPasang) return;
    _sudahPasang = true;
    _statusTerakhir.clear();
    OrderRepository.streamAktif().listen(_onData, onError: (_) {});
  }

  static void lepas() {
    _sudahPasang = false;
    _statusTerakhir.clear();
  }

  static Future<void> _onData(List<Pesanan> daftar) async {
    if (daftar.isEmpty) return;

    for (final p in daftar) {
      final lama = _statusTerakhir[p.id];
      _statusTerakhir[p.id] = p.status;

      if (lama == null) continue;
      if (lama == p.status) continue;

      // Notifikasi hanya untuk status: 1 (Dibayar), 2 (Diproses), 3 (Siap)
      if (p.status == 1 || p.status == 2 || p.status == 3) {
        final pesan = switch (p.status) {
          1 => 'Pembayaran ${p.nomor} dikonfirmasi.',
          2 => 'Pesanan ${p.nomor} sedang dibuat barista.',
          3 => 'Pesanan ${p.nomor} siap diambil. Silakan ke kasir.',
          _ => '',
        };
        
        if (pesan.isNotEmpty) {
          // Selalu simpan ke Firestore (untuk daftar lonceng & titik merah)
          // Tidak peduli toggle ON atau OFF
          await NotifRepository.tambah(
            judul: 'Pesanan ${p.nomor}',
            pesan: pesan,
            orderId: p.id,
          );
        }
      }
    }
  }
}