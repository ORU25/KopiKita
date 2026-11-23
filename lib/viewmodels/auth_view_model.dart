import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/hasil.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/push_repository.dart';
import '../domain/use_cases/pantau_status_pesanan.dart';
import 'pesan_kegagalan.dart';

enum StatusAuth { memeriksa, masuk, keluar }

// AuthViewModel: status login + aksi akun (masuk, daftar, reset/ubah sandi,
// keluar). Saat login berubah, ia juga menyalakan/mematikan pemantau status
// pesanan dan pendaftaran push, sehingga View tidak punya efek samping.
class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._auth, this._push, this._pantau) {
    _sub = _auth.perubahanUid().listen(_onUid);
  }

  final AuthRepository _auth;
  final PushRepository _push;
  final PantauStatusPesanan _pantau;
  late final StreamSubscription<String?> _sub;

  StatusAuth _status = StatusAuth.memeriksa;
  StatusAuth get status => _status;

  String? _uid;
  String? get uid => _uid;

  bool _memproses = false;
  bool get memproses => _memproses;

  void _onUid(String? uid) {
    _uid = uid;
    _status = uid == null ? StatusAuth.keluar : StatusAuth.masuk;
    if (uid == null) {
      _pantau.berhenti();
    } else {
      _pantau.mulai();
      _push.daftar();
    }
    notifyListeners();
  }

  // _jalankan: tandai memproses selama aksi; kembalikan pesan galat atau null.
  Future<String?> _jalankan(Future<Hasil<void>> Function() aksi) async {
    if (_memproses) return null;
    _memproses = true;
    notifyListeners();
    try {
      return pesanDari(await aksi());
    } finally {
      _memproses = false;
      notifyListeners();
    }
  }

  Future<String?> masuk(String email, String sandi) =>
      _jalankan(() => _auth.masuk(email: email, sandi: sandi));

  Future<String?> daftar(String nama, String email, String sandi) =>
      _jalankan(() => _auth.daftar(nama: nama, email: email, sandi: sandi));

  /// Aturan format email ada di sini (bukan di View) agar bisa diuji.
  Future<String?> kirimResetSandi(String email) async {
    final e = email.trim();
    if (e.isEmpty || !e.contains('@') || !e.contains('.')) {
      return 'Masukkan email yang valid.';
    }
    return pesanDari(await _auth.kirimResetSandi(e));
  }

  /// ubahSandi: sandiLamaSalah = true bila galat milik field sandi lama.
  Future<({String? pesan, bool sandiLamaSalah})> ubahSandi(
    String lama,
    String baru,
  ) async {
    final h = await _auth.ubahSandi(lama: lama, baru: baru);
    return switch (h) {
      Berhasil() => (pesan: null, sandiLamaSalah: false),
      Gagal(kegagalan: KredensialSalah()) => (
        pesan: 'Kata sandi lama salah.',
        sandiLamaSalah: true,
      ),
      Gagal(:final kegagalan) => (
        pesan: pesanKegagalan(kegagalan),
        sandiLamaSalah: false,
      ),
    };
  }

  Future<void> keluar() async {
    await _push.lepas(); // Hapus token FCM selagi masih login
    await _auth.keluar();
  }

  @override
  void dispose() {
    _sub.cancel();
    _pantau.berhenti();
    super.dispose();
  }
}
