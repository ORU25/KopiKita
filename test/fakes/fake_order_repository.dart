// Data palsu (fake) untuk kontrak OrderRepository: bekerja di memori, tanpa
// Firebase. Juga berperan sebagai mata-mata (spy): mencatat panggilan.
import 'dart:async';

import 'package:kopikita/domain/hasil.dart';
import 'package:kopikita/domain/repositories/order_repository.dart';
import 'package:kopikita/domain/entities/pesanan.dart';

class FakeOrderRepository implements OrderRepository {
  FakeOrderRepository({
    this.hasilBatalkan = const Berhasil<void>(null),
    this.hasilBuat = const Berhasil<String>('A-001'),
  });

  // Hasil yang dikembalikan; ganti ke Gagal(...) untuk pura-pura error.
  Hasil<void> hasilBatalkan;
  Hasil<String> hasilBuat;

  // Spy: id pesanan yang diminta dibatalkan & draf yang dikirim, berurutan.
  final List<String> dibatalkan = [];
  final List<Pesanan> dibuat = [];

  // Stream aktif yang bisa "didorong" dari tes (mis. status berubah).
  final aktif = StreamController<List<Pesanan>>.broadcast();

  @override
  Stream<List<Pesanan>> streamAktif() => aktif.stream;

  @override
  Stream<List<Pesanan>> streamRiwayat() => Stream.value(const <Pesanan>[]);

  @override
  Future<Hasil<String>> buat(Pesanan draf) async {
    dibuat.add(draf);
    return hasilBuat;
  }

  @override
  Future<Hasil<void>> batalkan(String orderId) async {
    dibatalkan.add(orderId);
    return hasilBatalkan;
  }
}
