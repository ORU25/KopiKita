// Unit test use case BatalkanPesanan dengan OrderRepository palsu:
// tanpa Firebase, tanpa internet, tanpa layar.
import 'package:flutter_test/flutter_test.dart';

import 'package:kopikita/domain/hasil.dart';
import 'package:kopikita/domain/use_cases/batalkan_pesanan.dart';
import 'package:kopikita/models/pesanan.dart';

import '../../fakes/fake_order_repository.dart';

// status: index statusKode (0 menunggu_bayar, 1 dibayar, 2 diproses,
// 3 siap, 4 selesai, 5 batal)
Pesanan _pesanan(int status) => Pesanan(
      id: 'ord-1',
      nomor: 'A-001',
      makanDiTempat: false,
      nomorMeja: 0,
      status: status,
      items: const [],
      total: 10000,
    );

void main() {
  test('menunggu_bayar: dibatalkan dan repository dipanggil sekali', () async {
    final repo = FakeOrderRepository();
    final hasil = await BatalkanPesanan(repo).jalankan(_pesanan(0));

    expect(hasil, isA<Berhasil<void>>());
    expect(repo.dibatalkan, ['ord-1']);
  });

  test('status selain menunggu_bayar ditolak dan TIDAK menyentuh repository',
      () async {
    for (final status in [1, 2, 3, 4, 5]) {
      final repo = FakeOrderRepository();
      final hasil = await BatalkanPesanan(repo).jalankan(_pesanan(status));

      expect(hasil, isA<Gagal<void>>(), reason: 'status $status');
      final kegagalan = (hasil as Gagal<void>).kegagalan;
      expect(kegagalan, isA<AturanDilanggar>());
      expect((kegagalan as AturanDilanggar).alasan,
          alasanPesananSudahDiproses);
      expect(repo.dibatalkan, isEmpty, reason: 'status $status');
    }
  });

  test('kegagalan dari repository diteruskan apa adanya', () async {
    final repo = FakeOrderRepository(
      hasilBatalkan: const Gagal<void>(TanpaKoneksi()),
    );
    final hasil = await BatalkanPesanan(repo).jalankan(_pesanan(0));

    expect(hasil, isA<Gagal<void>>());
    expect((hasil as Gagal<void>).kegagalan, isA<TanpaKoneksi>());
    expect(repo.dibatalkan, ['ord-1']);
  });
}
