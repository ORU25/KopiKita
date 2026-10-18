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
    final p = daftar.first;
    final lama = _statusTerakhir[p.id];
    _statusTerakhir[p.id] = p.status;

    // Pertama kali lihat pesanan ini → jangan notif (bukan perubahan)
    if (lama == null) return;
    if (lama == p.status) return;

    // Notifikasi untuk "Dibayar" (1), "Diproses" (2), dan "Siap diambil" (3).
    // "Menunggu bayar" (0) tidak — itu status awal saat pesanan baru dibuat.
    if (p.status != 1 && p.status != 2 && p.status != 3) return;

    final data = await UserRepo.ambil();
    if (!UserRepo.notifikasiDari(data)) return;

    final messenger = _messengerKey.currentState;
    if (messenger == null) return;

    // Pesan berbeda per status
    final pesan = switch (p.status) {
      1 => 'Pembayaran pesananmu sudah dikonfirmasi kasir.',
      2 => 'Barista sedang membuat pesananmu.',
      3 => 'Pesananmu siap diambil. Silakan ke kasir.',
      _ => '',
    };
    if (pesan.isEmpty) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(pesan)));
  }
}
