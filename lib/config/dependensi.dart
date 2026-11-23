import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../data/repositories/order_repository_firestore.dart';
import '../data/repositories/product_repository_firestore.dart';
import '../domain/repositories/order_repository.dart';
import '../domain/repositories/product_repository.dart';
import '../domain/use_cases/batalkan_pesanan.dart';

// AKAR KOMPOSISI (composition root): SATU-SATUNYA tempat yang tahu repository
// mana yang dipakai. Jenis yang dititipkan ditulis sebagai KONTRAK
// (ProductRepository), bukan implementasinya, sehingga layar cukup
// `context.read<ProductRepository>()`. Untuk beralih ke data palsu cukup
// ganti implementasi di sini (atau di tes: Provider<...>.value(value: palsu)).
List<SingleChildWidget> buatPenyedia() {
  return [
    Provider<ProductRepository>(
      create: (_) => ProductRepositoryFirestore(),
    ),
    Provider<OrderRepository>(
      create: (_) => OrderRepositoryFirestore(),
    ),
    Provider<BatalkanPesanan>(
      create: (context) => BatalkanPesanan(context.read<OrderRepository>()),
    ),
  ];
}
