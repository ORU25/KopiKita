import 'package:flutter/foundation.dart';

import '../domain/entities/cart_item.dart';
import '../domain/entities/menu_config.dart';
import '../domain/entities/pesanan.dart';
import '../domain/entities/voucher.dart';
import '../domain/entities/voucher_rules.dart';
import '../domain/hasil.dart';
import '../domain/repositories/menu_config_repository.dart';
import '../domain/repositories/voucher_repository.dart';
import '../domain/use_cases/buat_pesanan.dart';
import 'pesan_kegagalan.dart';

// CheckoutException: kegagalan checkout dengan pesan siap tampil (Bahasa Indonesia)
class CheckoutException implements Exception {
  final String pesan;
  const CheckoutException(this.pesan);

  @override
  String toString() => pesan;
}

// CartViewModel: state keranjang (item, metode, voucher, rincian harga) dan
// aksi checkout. Tidak mengenal Firebase: semua data lewat kontrak domain
// yang disuntikkan dari akar komposisi (config/dependensi.dart).
class CartViewModel extends ChangeNotifier {
  CartViewModel(this._voucherRepo, this._configRepo, this._buatPesanan);

  final VoucherRepository _voucherRepo;
  final MenuConfigRepository _configRepo;
  final BuatPesanan _buatPesanan;

  // STATE UTAMA: list item keranjang
  final List<CartItem> _items = [];
  List<CartItem> get items => List.unmodifiable(_items);

  // STATE: metode pesanan — true = Makan di Tempat, false = Ambil Sendiri
  bool makanDiTempat = false;
  // STATE: voucher yang diterapkan (null = tanpa voucher), sudah divalidasi
  Voucher? _voucher;
  // STATE: pengaturan harga dari config/menu (pajak, Large, add-on)
  MenuConfig _config = const MenuConfig();
  MenuConfig get config => _config;
  bool _configTermuat = false;
  bool get configTermuat => _configTermuat;

  double get tarifPajak => _config.tarifPajak;
  @visibleForTesting
  set tarifPajak(double t) => _config = MenuConfig(
    tarifPajak: t,
    hargaLarge: _config.hargaLarge,
    addOn: _config.addOn,
  );

  // STATE: true selama checkout berjalan (cegah tekan dua kali)
  bool _memproses = false;
  bool get memproses => _memproses;

  // ---------- DERIVED STATE ----------
  int get totalItems => _items.fold(0, (s, e) => s + e.jumlah);
  int get subtotal => _items.fold(0, (s, e) => s + e.totalHarga);
  String? get voucher => _voucher?.kode;
  Voucher? get voucherTerpasang => _voucher;
  // alasanVoucher: non-null bila voucher terpasang tapi tak lagi memenuhi syarat
  String? get alasanVoucher => _voucher?.alasanTidakBerlaku(subtotal);
  int get diskon {
    final v = _voucher;
    if (v == null || v.alasanTidakBerlaku(subtotal) != null) return 0;
    return v.hitungDiskon(subtotal);
  }

  int get persenPajak => (tarifPajak * 100).round(); // label UI, mis. 10
  int get pajak => ((subtotal - diskon) * tarifPajak).round();
  int get total => subtotal - diskon + pajak;

  // ---------- UTILITY ----------
  static String formatRupiah(int v) {
    final str = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return 'Rp$buf';
  }

  // muatConfig: baca pengaturan harga (Keranjang & Kustomisasi saat dibuka)
  Future<void> muatConfig() async {
    _config = await _configRepo.ambil();
    _configTermuat = true;
    notifyListeners();
  }

  // ---------- METODE PESANAN ----------
  void setMakanDiTempat(bool nilai) {
    makanDiTempat = nilai;
    notifyListeners();
  }

  // ---------- VOUCHER ----------
  // terapkanVoucher: null = berhasil, selain itu pesan galat.
  Future<String?> terapkanVoucher(String kode) async {
    switch (await _voucherRepo.ambil(kode)) {
      case Gagal(:final kegagalan):
        return kegagalan is TanpaKoneksi
            ? 'Tidak ada koneksi internet.'
            : 'Gagal memeriksa voucher.';
      case Berhasil(nilai: null):
        return 'Kode voucher tidak ditemukan.';
      case Berhasil(:final nilai?):
        final alasan = nilai.alasanTidakBerlaku(subtotal);
        if (alasan != null) return alasan;
        _voucher = nilai;
        notifyListeners();
        return null;
    }
  }

  void lepasVoucher() {
    _voucher = null;
    notifyListeners();
  }

  // Hanya untuk unit test (tanpa repository)
  @visibleForTesting
  void pasangVoucher(Voucher? v) {
    _voucher = v;
    notifyListeners();
  }

  // ---------- CRUD ----------
  void addItem(CartItem item) {
    final i = _items.indexWhere((e) => e.kunci == item.kunci);
    if (i >= 0) {
      _items[i] = _items[i].copyWith(jumlah: _items[i].jumlah + item.jumlah);
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  void changeQuantity(String kunci, int jumlah) {
    final i = _items.indexWhere((e) => e.kunci == kunci);
    if (i < 0) return;
    if (jumlah <= 0) {
      _items.removeAt(i);
    } else {
      _items[i] = _items[i].copyWith(jumlah: jumlah);
    }
    notifyListeners();
  }

  // ---------- CHECKOUT ----------
  // Kirim draf pesanan lewat use case BuatPesanan; sukses → kosongkan keranjang.
  // Melempar CheckoutException berisi pesan siap tampil bila gagal.
  Future<void> checkout() async {
    if (_items.isEmpty || _memproses) return;

    _memproses = true;
    notifyListeners();
    try {
      final draf = Pesanan(
        nomor: '', // Diisi repository (nomor antrean harian)
        makanDiTempat: makanDiTempat,
        nomorMeja: 0,
        status: 0,
        items: List<CartItem>.of(_items),
        subtotal: subtotal,
        diskon: diskon,
        pajak: pajak,
        total: total,
        voucher: voucher,
      );
      switch (await _buatPesanan.jalankan(draf)) {
        case Berhasil():
          _items.clear();
          _voucher = null;
        case Gagal(:final kegagalan):
          throw CheckoutException(switch (kegagalan) {
            TanpaKoneksi() =>
              'Koneksi lambat atau terputus. Periksa internet lalu coba lagi.',
            TanpaIzin() => 'Tidak punya izin membuat pesanan.',
            LayananBermasalah(:final kode) => 'Gagal membuat pesanan ($kode).',
            _ => pesanKegagalan(kegagalan),
          });
      }
    } finally {
      _memproses = false;
      notifyListeners();
    }
  }
}
