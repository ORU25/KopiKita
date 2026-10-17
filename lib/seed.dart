// seed.dart: mengisi Firestore dengan data awal + membuat 3 akun uji.
// Jalankan: flutter run -t lib/seed.dart -d chrome
//
// AMAN dijalankan ulang:
// - Field hasil admin (gambarUrl, habis, suhu, bisaLarge, addOn) TIDAK ditimpa
//   bila dokumen produk sudah ada — hanya diisi saat dokumen baru dibuat.
// - Semua batch.set memakai SetOptions(merge: true) agar field lain tetap utuh.
// - Akun yang sudah ada dipakai lagi (tidak error email-already-in-use).
//
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

  // ---------- PRODUK ----------
  // daftarMenu + item Rekomendasi yang belum ada di daftarMenu
  final namaRekomendasi = {for (final p in rekomendasi) p.nama};
  final semua = [
    ...daftarMenu,
    ...rekomendasi.where((r) => !daftarMenu.any((p) => p.nama == r.nama)),
  ];

  // Batch dipakai untuk dokumen NON-produk (config, voucher, counter).
  // Produk ditulis satu per satu agar bisa membaca dokumen lama lebih dulu.
  final batch = db.batch();

  // Hitung statistik untuk pesan akhir
  var produkBaru = 0;
  var produkDilindungi = 0;

  for (final (i, p) in semua.indexed) {
    final ref = db.collection('products').doc(idDari(p.nama));

    // Baca dokumen yang sudah ada untuk MELINDUNGI field hasil upload admin.
    final lama = await ref.get();
    final sudahAda = lama.exists;
    final dataLama = lama.data() ?? <String, dynamic>{};

    // Field identitas selalu di-update dari dummy (isinya sama setiap kali seed).
    // Field kustomisasi: hanya diisi saat dokumen BARU; bila sudah ada,
    // nilai lama (hasil edit admin) dipertahankan apa adanya.
    final data = <String, dynamic>{
      'nama': p.nama,
      'deskripsi': p.deskripsi,
      'harga': p.harga,
      'kategori': p.kategori,
      'rekomendasi': namaRekomendasi.contains(p.nama),
      'urutan': i,

      // ⛔ JANGAN timpa field ini jika dokumen sudah ada:
      'gambarUrl': sudahAda ? (dataLama['gambarUrl'] ?? '') : p.gambarUrl,
      'habis':     sudahAda ? (dataLama['habis']     ?? false) : p.habis,
      'suhu':      sudahAda ? (dataLama['suhu']      ?? p.suhu) : p.suhu,
      'bisaLarge': sudahAda ? (dataLama['bisaLarge'] ?? p.bisaLarge) : p.bisaLarge,
      'addOn':     sudahAda ? (dataLama['addOn']     ?? p.addOn) : p.addOn,
    };

    // merge: true → field di luar `data` (mis. createdAt) tetap utuh.
    await ref.set(data, SetOptions(merge: true));
    if (sudahAda) {
      produkDilindungi++;
    } else {
      produkBaru++;
    }
  }

  // ---------- CONFIG / VOUCHER / COUNTER ----------
  // Semua pakai merge agar field tambahan dari admin (mis. pajak) tidak hilang.
  batch.set(
    db.doc('config/menu'),
    {
      'hargaLarge': hargaLarge,
      'addOn': addOnMenu,
      'pajak': 0.10,
    },
    SetOptions(merge: true),
  );

  batch.set(
    db.doc('vouchers/KOPIKITA20'),
    {
      ...voucherSaya[0].toMap(),
      'berlakuSampai': Timestamp.fromDate(DateTime(2026, 12, 31, 23, 59)),
    },
    SetOptions(merge: true),
  );
  batch.set(
    db.doc('vouchers/HEMAT5RB'),
    {
      ...voucherSaya[1].toMap(),
      'berlakuSampai': Timestamp.fromDate(DateTime(2026, 10, 31, 23, 59)),
    },
    SetOptions(merge: true),
  );

  batch.set(
    db.doc('counters/antrean'),
    {'tanggal': '', 'nomor': 0},
    SetOptions(merge: true),
  );

  await batch.commit();

  // ---------- AKUN UJI ----------
  final auth = FirebaseAuth.instance;
  for (final [email, nama, role] in akunUji) {
    UserCredential cred;
    try {
      cred = await auth.createUserWithEmailAndPassword(
        email: email,
        password: kataSandiUji,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code != 'email-already-in-use') rethrow;
      cred = await auth.signInWithEmailAndPassword(
        email: email,
        password: kataSandiUji,
      );
    }
    // merge: true → voucher/favorit/notifikasi milik user TIDAK ditimpa.
    await db.doc('users/${cred.user!.uid}').set(
      {
        'nama': nama,
        'email': email,
        'role': role,
        'favorit': <String>[],
        'voucher': role == 'pelanggan'
            ? ['KOPIKITA20', 'HEMAT5RB']
            : <String>[],
        'notifikasi': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
  await auth.signOut();

  return 'Selesai ✓\n'
    '$produkBaru produk baru, $produkDilindungi produk lama '
    '(gambar & pengaturan admin dipertahankan).\n'
    'config/menu, 2 voucher, counters/antrean, ${akunUji.length} akun uji '
    '(kata sandi: $kataSandiUji).\n'
    'Tutup jendela ini.';
}