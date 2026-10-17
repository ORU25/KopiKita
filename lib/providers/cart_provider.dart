import 'package:flutter/material.dart';
import '../data/dummy_data.dart';
import '../models/cart_item.dart';

class CartProvider extends ChangeNotifier {
  // STATE UTAMA: list item keranjang
  final List<CartItem> _items = [];

  // items: getter untuk mengakses _items
  List<CartItem> get items => List.unmodifiable(_items);

  // STATE: metode pesanan — true = Makan di Tempat, false = Ambil Sendiri
  bool makanDiTempat = false;
  // STATE: nomor meja (bila makan di tempat)
  int nomorMeja = 7;
  // STATE: kode voucher yang diterapkan (null = tanpa voucher)
  String? voucher = 'KOPIKITA20';
  // STATE: pesanan aktif terakhir (ditampilkan di tab Pesanan)
  Pesanan? pesananAktif = contohPesananAktif;

  // ---------- DERIVED STATE ----------
  int get totalItems => _items.fold(0, (s, e) => s + e.jumlah);
  int get subtotal => _items.fold(0, (s, e) => s + e.totalHarga);
  int get diskon => voucher == null ? 0 : (subtotal * 0.20).round();
  int get pajak => ((subtotal - diskon) * 0.10).round();
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

  // ---------- METODE PESANAN ----------
  void setMakanDiTempat(bool nilai) {
    makanDiTempat = nilai;
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

  // PERBAIKAN: Mengubah void menjadi Future<void> async
  Future<void> checkout() async {
    if (_items.isEmpty) return;

    // Simulasi delay jaringan (opsional, bisa dihapus)
    // await Future.delayed(const Duration(milliseconds: 500));

    final nomorLama = int.parse(pesananAktif?.nomor.substring(2) ?? '13');
    pesananAktif = Pesanan(
      nomor: 'A-${(nomorLama + 1).toString().padLeft(3, '0')}',
      makanDiTempat: makanDiTempat,
      nomorMeja: nomorMeja,
      status: 0, // "Menunggu bayar"
      items: List.of(_items),
      total: total,
    );
    
    _items.clear(); // Kosongkan keranjang
    notifyListeners(); // Beritahu listener
  }
}