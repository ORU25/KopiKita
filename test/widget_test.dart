import 'package:flutter_test/flutter_test.dart';

import 'package:kopikita/models/cart_item.dart';
import 'package:kopikita/models/pesanan.dart';
import 'package:kopikita/models/produk.dart';
import 'package:kopikita/providers/cart_provider.dart';

void main() {
  // Hitungan keranjang sesuai contoh DESIGN.md 3.5:
  // Subtotal 87.000 + pajak 10% 8.700 = 95.700 (tanpa voucher).
  test('CartProvider menghitung total', () {
    final cart = CartProvider()
      ..addItem(const CartItem(
          nama: 'Kopi Susu Kita',
          harga: 31000,
          ukuran: 'Large',
          addOn: ['Extra shot']))
      ..addItem(const CartItem(
          nama: 'Caramel Latte',
          harga: 28000,
          suhu: 'Panas',
          gula: 'Sedikit',
          jumlah: 2));
    expect(cart.subtotal, 87000);
    expect(cart.diskon, 0);
    expect(cart.pajak, 8700);
    expect(cart.total, 95700);
    expect(cart.totalItems, 3);

    // Opsi sama → digabung; opsi beda → item baru
    cart.addItem(const CartItem(
        nama: 'Caramel Latte', harga: 28000, suhu: 'Panas', gula: 'Sedikit'));
    expect(cart.items.length, 2);
    cart.addItem(const CartItem(nama: 'Caramel Latte', harga: 28000));
    expect(cart.items.length, 3);
  });

  // Model ↔ Firestore: toMap lalu fromMap harus menghasilkan data yang sama
  test('Pesanan & CartItem toMap/fromMap', () {
    const contoh = Pesanan(
      nomor: 'A-014',
      makanDiTempat: true,
      nomorMeja: 7,
      status: 2, // "Diproses"
      items: [
        CartItem(
            nama: 'Kopi Susu Kita',
            harga: 31000,
            ukuran: 'Large',
            addOn: ['Extra shot']),
        CartItem(
            nama: 'Caramel Latte',
            harga: 28000,
            suhu: 'Panas',
            gula: 'Sedikit',
            jumlah: 2),
      ],
      total: 76560,
    );
    final p = Pesanan.fromMap('x', contoh.toMap());
    expect(p.nomor, 'A-014');
    expect(p.status, 2);
    expect(p.toMap()['status'], 'diproses');
    expect(p.items.first.labelOpsi, contoh.items.first.labelOpsi);
    expect(p.items[1].jumlah, 2);
    expect(Pesanan.fromMap('y', {'status': 'batal'}).batal, isTrue);
  });

  // Filter status untuk OrderRepository (aktif vs riwayat)
  test('Pesanan status aktif/riwayat', () {
    final aktif = Pesanan.fromMap('a', {
      'nomor': 'A-001',
      'makanDiTempat': false,
      'nomorMeja': null,
      'status': 'menunggu_bayar',
      'items': <Map<String, dynamic>>[],
      'subtotal': 0,
      'diskon': 0,
      'pajak': 0,
      'total': 10000,
    });
    expect(aktif.batal, isFalse);
    expect(statusKode[aktif.status], 'menunggu_bayar');

    final selesai = Pesanan.fromMap('b', {'status': 'selesai'});
    expect(statusKode[selesai.status], 'selesai');

    final batal = Pesanan.fromMap('c', {'status': 'batal'});
    expect(batal.batal, isTrue);
  });

  // Produk.fromMap membaca field kategori & habis
  test('Produk.fromMap', () {
    final p = Produk.fromMap('a', {
      'nama': 'Matcha Latte',
      'deskripsi': 'Matcha dan susu',
      'harga': 26000,
      'kategori': 'Non-Kopi',
      'habis': true,
    });
    expect(p.habis, isTrue);
    expect(p.makanan, isFalse);
  });
}