import 'package:flutter/material.dart';
import '../data/dummy_data.dart';
import '../models/cart_item.dart';

class CartProvider extends ChangeNotifier {
  // STATE UTAMA: list item keranjang
  // _items: menyimpan semua item yang ada di keranjang
  final List<CartItem> _items = [];

  // items: getter untuk mengakses _items sebagai list yang tidak bisa diubah
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
  // totalItems: menghitung total jumlah semua item (sum dari e.jumlah)
  int get totalItems => _items.fold(0, (s, e) => s + e.jumlah);
  // subtotal: menghitung total harga sebelum diskon & pajak
  int get subtotal => _items.fold(0, (s, e) => s + e.totalHarga);
  // diskon: 20% dari subtotal bila voucher KOPIKITA20 diterapkan
  int get diskon => voucher == null ? 0 : (subtotal * 0.20).round();
  // pajak: 10% dari subtotal SETELAH diskon
  int get pajak => ((subtotal - diskon) * 0.10).round();
  // total: subtotal - diskon + pajak
  int get total => subtotal - diskon + pajak;

  // ---------- UTILITY ----------
  // formatRupiah: mengubah integer menjadi format "Rp1.234.567"
  static String formatRupiah(int v) {
    final str = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      // Tambahkan titik setiap 3 digit dari belakang
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return 'Rp$buf';
  }

  // ---------- METODE PESANAN ----------
  // setMakanDiTempat: mengubah metode pesanan (Ambil Sendiri / Makan di Tempat)
  void setMakanDiTempat(bool nilai) {
    makanDiTempat = nilai;
    notifyListeners(); // Beritahu listener bahwa state berubah
  }

  // ---------- CRUD ----------
  // addItem: menambahkan item ke keranjang, atau menambah jumlah jika
  // produk dengan opsi yang sama sudah ada (dicocokkan lewat kunci)
  void addItem(CartItem item) {
    final i = _items.indexWhere((e) => e.kunci == item.kunci); // Cek apakah sudah ada
    if (i >= 0) {
      // Jika sudah ada, tambahkan jumlahnya
      _items[i] = _items[i].copyWith(jumlah: _items[i].jumlah + item.jumlah);
    } else {
      // Jika belum ada, tambahkan item baru
      _items.add(item);
    }
    // Modul 5: notifyListeners() → widget yang listen akan rebuild
    notifyListeners();
  }

  // changeQuantity: mengubah jumlah item tertentu, hapus bila jumlah <= 0
  void changeQuantity(String kunci, int jumlah) {
    final i = _items.indexWhere((e) => e.kunci == kunci); // Cari index item
    if (i < 0) return; // Jika tidak ditemukan, keluar
    if (jumlah <= 0) {
      _items.removeAt(i); // Jika jumlah <= 0, hapus item
    } else {
      _items[i] = _items[i].copyWith(jumlah: jumlah);
    }
    notifyListeners(); // Beritahu listener bahwa state berubah
  }

  // checkout: membuat pesanan aktif dari isi keranjang lalu mengosongkan keranjang
  // ponytail: nomor antrean dibuat lokal, nanti dari Firestore (status menunggu_bayar)
  void checkout() {
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
