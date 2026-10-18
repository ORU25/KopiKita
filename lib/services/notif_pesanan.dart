import 'package:flutter/material.dart';

import '../models/pesanan.dart';
import 'order_repository.dart';
import 'user_repo.dart';

/// NotifPesanan: listener global status pesanan aktif user.
/// Dipasang sekali di main.dart (setelah login), dilepas saat keluar.
///
/// Saat status pesanan berubah (mis. staf mengubah ke "siap" di web),
/// tampilkan SnackBar lewat `navigatorKey` sehingga muncul di tab mana pun.
/// Hormati users/{uid}.notifikasi (bila false → tidak ada SnackBar).
class NotifPesanan {
  static final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();
  static GlobalKey<ScaffoldMessengerState> get messengerKey => _messengerKey;

  static final Map<String, int> _statusTerakhir = {};
  static bool _sudahPasang = false;

  // pasang: mulai mendengarkan pesanan aktif user. Aman dipanggil ulang.
  static void pasang() {
    if (_sudahPasang) return;
    _sudahPasang = true;
    _statusTerakhir.clear();
    OrderRepository.streamAktif().listen(_onData, onError: (_) {});
  }

  /// lepas: berhenti mendengarkan (dipanggil saat keluar).
  static void lepas() {
    _sudahPasang = false;
    _statusTerakhir.clear();
  }

  static Future<void> _onData(List<Pesanan> daftar) async {
    if (daftar.isEmpty) return;

    // Ambil data user sekali saja
    final data = await UserRepo.ambil();
    if (!UserRepo.notifikasiDari(data)) return;

    final messenger = _messengerKey.currentState;
    if (messenger == null) return;

    // Periksa SEMUA pesanan aktif
    for (final p in daftar) {
      final lama = _statusTerakhir[p.id];
      _statusTerakhir[p.id] = p.status;

      // Jika ini pertama kali kita melihat pesanan ini, jangan notif
      if (lama == null) continue;

      // Jika status tidak berubah, lewati
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
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(pesan)));
        }
      }
    }
  }
}
