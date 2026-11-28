import 'dart:async';

import 'package:flutter/widgets.dart';

// StreamViewModel: ViewModel yang menampung SATU stream dari repository dan
// menyajikannya sebagai `keadaan` (memuat / data / galat) untuk View.
// View cukup `context.watch<...>().keadaan` lalu memanggil `muatUlang()`
// saat tombol "Coba lagi" ditekan; View tidak pernah memegang Stream.
abstract class StreamViewModel<T> extends ChangeNotifier {
  /// Stream sumber (dari repository / use case). Dipanggil ulang tiap muatUlang.
  @protected
  Stream<T> buatStream();

  AsyncSnapshot<T> _keadaan = const AsyncSnapshot.waiting();
  AsyncSnapshot<T> get keadaan => _keadaan;

  /// Data terakhir, atau null bila belum ada / sedang galat.
  T? get data => _keadaan.data;

  StreamSubscription<T>? _sub;
  bool _dibuang = false;

  /// Berlangganan (ulang). Subclass memanggilnya sekali di constructor.
  void muatUlang() {
    _sub?.cancel();
    _ubah(const AsyncSnapshot.waiting());
    _sub = buatStream().listen(
      (d) => _ubah(AsyncSnapshot.withData(ConnectionState.active, d)),
      onError: (Object e, StackTrace st) =>
          _ubah(AsyncSnapshot.withError(ConnectionState.active, e, st)),
    );
  }

  /// Memperbarui state secara manual (untuk subclass, mis. load dari cache).
  /// Dipakai oleh subclass yang perlu meng-set state tanpa stream.
  @protected
  void setState(AsyncSnapshot<T> snapshot) {
    _ubah(snapshot);
  }

  void _ubah(AsyncSnapshot<T> k) {
    if (_dibuang) return;
    _keadaan = k;
    notifyListeners();
  }

  @override
  void dispose() {
    _dibuang = true;
    _sub?.cancel();
    super.dispose();
  }
}
