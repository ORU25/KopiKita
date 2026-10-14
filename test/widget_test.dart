import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:kopikita/data/dummy_data.dart';
import 'package:kopikita/main.dart';
import 'package:kopikita/models/cart_item.dart';
import 'package:kopikita/providers/cart_provider.dart';

void main() {
  // Hitungan keranjang sesuai contoh DESIGN.md 3.5:
  // Subtotal 87.000 − diskon 20% 17.400 + pajak 10% 6.960 = 76.560
  test('CartProvider menghitung total sesuai desain', () {
    final cart = CartProvider()
      ..addItem(const CartItem(nama: 'Kopi Susu Kita', harga: 31000, ukuran: 'Large', addOn: ['Extra shot']))
      ..addItem(const CartItem(nama: 'Caramel Latte', harga: 28000, suhu: 'Panas', gula: 'Sedikit', jumlah: 2));
    expect(cart.subtotal, 87000);
    expect(cart.diskon, 17400);
    expect(cart.pajak, 6960);
    expect(cart.total, 76560);
    expect(cart.totalItems, 3);

    // Opsi sama → digabung; opsi beda → item baru
    cart.addItem(const CartItem(nama: 'Caramel Latte', harga: 28000, suhu: 'Panas', gula: 'Sedikit'));
    expect(cart.items.length, 2);
    cart.addItem(const CartItem(nama: 'Caramel Latte', harga: 28000));
    expect(cart.items.length, 3);
  });

  // Model ↔ Firestore: toMap lalu fromMap harus menghasilkan data yang sama
  test('Pesanan & CartItem toMap/fromMap', () {
    final p = Pesanan.fromMap('x', contohPesananAktif.toMap());
    expect(p.nomor, 'A-014');
    expect(p.status, 2); // "diproses"
    expect(p.toMap()['status'], 'diproses');
    expect(p.items.first.labelOpsi, contohPesananAktif.items.first.labelOpsi);
    expect(p.items[1].jumlah, 2);
    expect(Pesanan.fromMap('y', {'status': 'batal'}).batal, isTrue);
    expect(Produk.fromMap('a', daftarMenu[3].toMap()).habis, isTrue);
  });

  testWidgets('Login → Beranda', (tester) async {
    // Ukuran frame desain 390×844
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ChangeNotifierProvider(create: (_) => CartProvider(), child: const MainApp()),
    );
    // Masuk → Daftar → kembali ke Masuk
    await tester.tap(find.text('Daftar'));
    await tester.pumpAndSettle();
    expect(find.text('Buat akun untuk mulai memesan.'), findsOneWidget);
    expect(find.text('Lanjutkan dengan Google'), findsNothing);
    await tester.tap(find.text('Masuk').last); // Link "Masuk" di bawah
    await tester.pumpAndSettle();

    await tester.tap(find.text('Masuk').last); // Tombol Masuk (bukan judul)
    await tester.pumpAndSettle();
    expect(find.text('Hai, Rina'), findsOneWidget);

    // Beranda → Menu lewat aksi "Makan di Tempat"
    await tester.tap(find.text('Makan di Tempat'));
    await tester.pumpAndSettle();
    expect(find.text('Rekomendasi'), findsWidgets);

    // Menu → Kustomisasi → Tambah → strip keranjang muncul
    await tester.tap(find.text('Americano'));
    await tester.pumpAndSettle();
    expect(find.text('Level gula'), findsOneWidget);
    await tester.tap(find.text('Panas'));
    await tester.pump();
    expect(find.text('Level es'), findsNothing); // Disembunyikan saat Panas
    await tester.tap(find.textContaining('Tambah ·'));
    await tester.pumpAndSettle();
    expect(find.text('Lihat keranjang'), findsOneWidget);

    // Strip → Keranjang → Pesan → tab Pesanan
    await tester.tap(find.text('Lihat keranjang'));
    await tester.pumpAndSettle();
    expect(find.text('Nomor meja'), findsOneWidget);
    await tester.tap(find.textContaining('Pesan ·'));
    await tester.pumpAndSettle();
    expect(find.text('A-015'), findsOneWidget);

    // Riwayat & Akun
    await tester.tap(find.text('Riwayat'));
    await tester.pumpAndSettle();
    expect(find.text('Oktober 2026'), findsOneWidget);
    await tester.tap(find.text('Akun'));
    await tester.pumpAndSettle();
    expect(find.text('Voucher saya'), findsOneWidget);
  });
}
