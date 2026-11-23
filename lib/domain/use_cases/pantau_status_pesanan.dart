import 'dart:async';

import '../entities/pesanan.dart';
import '../repositories/notifikasi_repository.dart';
import '../repositories/order_repository.dart';

// USE CASE: pantau pesanan aktif; setiap status naik ke Dibayar / Diproses /
// Siap, catat satu notifikasi (lonceng Beranda). Status pertama yang terlihat
// hanya dicatat sebagai titik awal, tidak memicu notifikasi.
class PantauStatusPesanan {
  PantauStatusPesanan(this._pesanan, this._notif);

  final OrderRepository _pesanan;
  final NotifikasiRepository _notif;

  final Map<String, int> _statusTerakhir = {};
  StreamSubscription<List<Pesanan>>? _sub;

  /// Idempoten: pemanggilan kedua diabaikan sampai [berhenti].
  void mulai() {
    if (_sub != null) return;
    _statusTerakhir.clear();
    _sub = _pesanan.streamAktif().listen(_onData, onError: (_) {});
  }

  /// Batalkan langganan agar stream user lama tidak menulis ke akun berikutnya.
  Future<void> berhenti() async {
    await _sub?.cancel();
    _sub = null;
    _statusTerakhir.clear();
  }

  /// pesanUntuk: kalimat notifikasi untuk status [status]; null = tanpa notifikasi.
  static String? pesanUntuk(Pesanan p) => switch (p.status) {
    1 => 'Pembayaran ${p.nomor} dikonfirmasi.',
    2 => 'Pesanan ${p.nomor} sedang dibuat barista.',
    3 => 'Pesanan ${p.nomor} siap diambil. Silakan ke kasir.',
    _ => null,
  };

  Future<void> _onData(List<Pesanan> daftar) async {
    for (final p in daftar) {
      final lama = _statusTerakhir[p.id];
      _statusTerakhir[p.id] = p.status;
      if (lama == null || lama == p.status) continue;
      final pesan = pesanUntuk(p);
      if (pesan == null) continue;
      // Selalu dicatat (daftar lonceng & titik merah), apa pun toggle notifikasi
      await _notif.tambah(
        judul: 'Pesanan ${p.nomor}',
        pesan: pesan,
        orderId: p.id,
      );
    }
  }
}
