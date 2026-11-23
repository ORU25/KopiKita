// Data palsu (fake) untuk kontrak OrderRepository: bekerja di memori, tanpa
// Firebase. Juga berperan sebagai mata-mata (spy): mencatat id yang dibatalkan.
import 'package:kopikita/domain/hasil.dart';
import 'package:kopikita/domain/repositories/order_repository.dart';
import 'package:kopikita/models/pesanan.dart';

class FakeOrderRepository implements OrderRepository {
  FakeOrderRepository({this.hasilBatalkan = const Berhasil<void>(null)});

  // Hasil yang dikembalikan batalkan(); ganti ke Gagal(...) untuk pura-pura error.
  Hasil<void> hasilBatalkan;

  // Spy: id pesanan yang diminta dibatalkan, berurutan.
  final List<String> dibatalkan = [];

  @override
  Stream<List<Pesanan>> streamAktif() => Stream.value(const <Pesanan>[]);

  @override
  Stream<List<Pesanan>> streamRiwayat() => Stream.value(const <Pesanan>[]);

  @override
  Future<Hasil<void>> batalkan(String orderId) async {
    dibatalkan.add(orderId);
    return hasilBatalkan;
  }
}
