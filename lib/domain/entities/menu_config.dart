// MenuConfig: pengaturan harga dari web Admin (config/menu).
class MenuConfig {
  final double tarifPajak; // Pecahan, 0.10 = 10%
  final int hargaLarge; // Tambahan harga ukuran Large
  final Map<String, int> addOn; // Nama add-on → harga

  const MenuConfig({
    this.tarifPajak = 0.10,
    this.hargaLarge = 4000,
    this.addOn = const {},
  });

  // fromMap: pajak > 1 dianggap persen (10 → 0.10); nilai rusak → bawaan.
  factory MenuConfig.fromMap(Map<String, dynamic>? d) {
    final p = d?['pajak'];
    final pajak = p is num ? (p > 1 ? p / 100 : p.toDouble()) : 0.10;
    final l = d?['hargaLarge'];
    final a = d?['addOn'];
    return MenuConfig(
      tarifPajak: pajak,
      hargaLarge: l is num ? l.toInt() : 4000,
      addOn: a is Map
          ? {
              for (final e in a.entries)
                if (e.key is String && e.value is num)
                  e.key as String: (e.value as num).toInt(),
            }
          : const {},
    );
  }
}
