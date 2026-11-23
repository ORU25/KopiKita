import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/entities/voucher.dart';
import '../domain/repositories/profil_repository.dart';
import '../domain/repositories/voucher_repository.dart';
import 'stream_view_model.dart';

// VoucherSayaViewModel: voucher milik user (kode di profil × katalog voucher).
// Saat daftar kode di profil berubah, langganan katalog diganti (switch).
class VoucherSayaViewModel extends StreamViewModel<List<Voucher>> {
  VoucherSayaViewModel(this._profil, this._voucher) {
    muatUlang();
  }

  final ProfilRepository _profil;
  final VoucherRepository _voucher;

  @override
  Stream<List<Voucher>> buatStream() {
    StreamSubscription<List<String>>? luar;
    StreamSubscription<List<Voucher>>? dalam;
    late final StreamController<List<Voucher>> c;
    c = StreamController<List<Voucher>>(
      onListen: () {
        luar = _profil
            .stream()
            .map((p) => p.voucher)
            .distinct(listEquals)
            .listen((kode) {
              dalam?.cancel();
              dalam = _voucher
                  .streamKode(kode)
                  .listen(c.add, onError: c.addError);
            }, onError: c.addError);
      },
      onCancel: () async {
        await dalam?.cancel();
        await luar?.cancel();
      },
    );
    return c.stream;
  }
}
