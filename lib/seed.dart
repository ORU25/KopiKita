// seed.dart: mengisi Firestore dengan data awal + membuat 3 akun uji.
// Jalankan: flutter run -t lib/seed.dart -d chrome
// Aman dijalankan ulang (dokumen ditimpa, akun yang sudah ada dipakai lagi).
// ponytail: hanya untuk Firestore test mode; setelah rules final, jalankan dari akun admin
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'data/dummy_data.dart';
import 'firebase_options.dart';

// Akun uji: [email, nama, role]. Kata sandi semua akun: kataSandiUji
const akunUji = [
  ['admin@kopikita.test', 'Admin KopiKita', 'admin'],
  ['staf@kopikita.test', 'Staf KopiKita', 'staf'],
  ['pelanggan@kopikita.test', 'Rina', 'pelanggan'],
];
const kataSandiUji = 'kopikita123';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final log = ValueNotifier<String>('Mengisi data...');
  runApp(MaterialApp(
    home: Scaffold(
      body: Center(
        child: ValueListenableBuilder(
          valueListenable: log,
          builder: (_, teks, _) => Padding(
            padding: const EdgeInsets.all(24),
            child: Text(teks, style: const TextStyle(fontSize: 16)),
          ),
        ),
      ),
    ),
  ));
  try {
    log.value = await seed();
  } catch (e) {
    log.value = 'GAGAL: $e';
  }
}

// idDari: "Kopi Susu Kita" → "kopi-susu-kita"
String idDari(String nama) =>
    nama.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');

Future<String> seed() async {
  final db = FirebaseFirestore.instance;
  final batch = db.batch();

  // products: daftarMenu + item Rekomendasi yang belum ada di daftarMenu
  final namaRekomendasi = {for (final p in rekomendasi) p.nama};
  final semua = [
    ...daftarMenu,
    ...rekomendasi.where((r) => !daftarMenu.any((p) => p.nama == r.nama)),
  ];
  for (final (i, p) in semua.indexed) {
    batch.set(db.collection('products').doc(idDari(p.nama)), {
      ...p.toMap(),
      'rekomendasi': namaRekomendasi.contains(p.nama),
      'urutan': i,
    });
  }

  batch.set(db.doc('config/menu'), {
    'hargaLarge': hargaLarge,
    'addOn': addOnMenu,
    'pajak': 0.10,
  });

  batch.set(db.doc('vouchers/KOPIKITA20'), {
    ...voucherSaya[0].toMap(),
    'berlakuSampai': Timestamp.fromDate(DateTime(2026, 12, 31, 23, 59)),
  });
  batch.set(db.doc('vouchers/HEMAT5RB'), {
    ...voucherSaya[1].toMap(),
    'berlakuSampai': Timestamp.fromDate(DateTime(2026, 10, 31, 23, 59)),
  });

  batch.set(db.doc('counters/antrean'), {'tanggal': '', 'nomor': 0});
  await batch.commit();

  // Akun uji + dokumen users/{uid}
  final auth = FirebaseAuth.instance;
  for (final [email, nama, role] in akunUji) {
    UserCredential cred;
    try {
      cred = await auth.createUserWithEmailAndPassword(
          email: email, password: kataSandiUji);
    } on FirebaseAuthException catch (e) {
      if (e.code != 'email-already-in-use') rethrow;
      cred = await auth.signInWithEmailAndPassword(
          email: email, password: kataSandiUji);
    }
    await db.doc('users/${cred.user!.uid}').set({
      'nama': nama,
      'email': email,
      'role': role,
      'favorit': <String>[],
      'voucher': role == 'pelanggan' ? ['KOPIKITA20', 'HEMAT5RB'] : <String>[],
      'notifikasi': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
  await auth.signOut();

  return 'Selesai ✓\n'
      '${semua.length} produk, config/menu, 2 voucher, counters/antrean, '
      '${akunUji.length} akun uji (kata sandi: $kataSandiUji).\n'
      'Tutup jendela ini.';
}
