import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/dummy_data.dart';
import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

// bukaKustomisasi: tampilkan Kustomisasi sebagai sheet yang meluncur dari bawah;
// tarik turun atau tap di luar sheet = batal
void bukaKustomisasi(BuildContext context, Produk p) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Sheet boleh lebih tinggi dari setengah layar
    useSafeArea: true,
    backgroundColor: AppColors.bg, // Latar sheet putih (seperti halaman)
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.9,
      minChildSize: 0.5, // Ditarik sampai sini → sheet tertutup
      builder: (_, sc) => CustomizePage(produk: p, scrollController: sc),
    ),
  );
}

// CustomizePage: isi sheet Kustomisasi (DESIGN.md 3.4)
// Handle + daftar pilihan + footer stepper & tombol Tambah
class CustomizePage extends StatefulWidget {
  final Produk produk; // Produk yang sedang dikustomisasi
  final ScrollController? scrollController; // Dari DraggableScrollableSheet
  const CustomizePage({super.key, required this.produk, this.scrollController});

  @override
  State<CustomizePage> createState() => _CustomizePageState();
}

class _CustomizePageState extends State<CustomizePage> {
  // ---------- STATE PILIHAN ----------
  String _ukuran = 'Regular'; // Regular / Large
  String _suhu = 'Es'; // Panas / Es
  String _gula = 'Normal'; // Tanpa / Sedikit / Normal / Manis
  String _es = 'Normal'; // Sedikit / Normal / Banyak
  final Set<String> _addOn = {}; // Add-on terpilih
  int _jumlah = 1; // Jumlah pesanan
  final TextEditingController _catatanController = TextEditingController();

  // ---------- STATE CONFIG DARI WEB ----------
  bool _memuatConfig = true;
  int _hargaLarge = 0;
  Map<String, int> _addOnMenu = {};

  @override
  void initState() {
    super.initState();
    // Set default suhu sesuai pengaturan web. Jika kosong (makanan), abaikan.
    if (widget.produk.suhu.isNotEmpty) {
      _suhu = widget.produk.suhu.first;
    }
    _ambilConfig();
  }

  // _ambilConfig: Mengambil harga Large dan Add-on langsung dari Firestore
  Future<void> _ambilConfig() async {
    try {
      final snap = await FirebaseFirestore.instance.doc('config/menu').get();
      final data = snap.data();
      if (data != null) {
        _hargaLarge = (data['hargaLarge'] ?? 0) as int;
        final rawAddOn = data['addOn'] as Map<String, dynamic>? ?? {};
        _addOnMenu = rawAddOn.map((key, value) => MapEntry(key, (value as num).toInt()));
      }
    } catch (e) {
      // Jika gagal memuat dari web, fallback ke dummy_data.dart
      _hargaLarge = hargaLarge;
      _addOnMenu = Map<String, int>.from(addOnMenu);
    }
    
    if (mounted) {
      setState(() => _memuatConfig = false);
    }
  }

  // dispose: membersihkan controller saat widget dihancurkan
  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  // ---------- DERIVED STATE ----------
  // _hargaSatuan: harga dasar + Large (dari web) + total add-on (dari web)
  int get _hargaSatuan =>
      widget.produk.harga +
      (_ukuran == 'Large' ? _hargaLarge : 0) +
      _addOn.fold(0, (s, a) => s + (_addOnMenu[a] ?? 0));

  // _tambah: masukkan item ke keranjang lalu tutup layar
  void _tambah() {
    final p = widget.produk;
    context.read<CartProvider>().addItem(
      CartItem(
        productId: p.id,
        gambarUrl: p.gambarUrl,
        nama: p.nama,
        harga: _hargaSatuan,
        makanan: p.makanan,
        ukuran: _ukuran,
        suhu: _suhu,
        gula: _gula,
        es: _es,
        // Urutkan add-on sesuai urutan menu agar kunci item konsisten
        addOn: _addOnMenu.keys.where(_addOn.contains).toList(),
        catatan: _catatanController.text.trim(),
        jumlah: _jumlah,
      ),
    );
    Navigator.pop(context); // Tutup sheet, kembali ke Menu
  }

  @override
  Widget build(BuildContext context) {
    // Jika config dari web belum termuat, tampilkan loading
    if (_memuatConfig) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final p = widget.produk;
    // Padding viewInsets: footer naik di atas keyboard saat mengetik catatan
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        children: [
          // Handle 40×4 pending
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.pending,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Expanded: isi pilihan bisa di-scroll
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: _isiPilihan(p),
            ),
          ),
          _footer(),
        ],
      ),
    );
  }

  // _isiPilihan: daftar widget pilihan di dalam sheet
  List<Widget> _isiPilihan(Produk p) {
    // Ambil daftar add-on yang diizinkan dari pengaturan web & config
    final addOnTersedia = p.addOnBerlaku(_addOnMenu.keys);

    return [
      // Nama + deskripsi + gambar produk di kiri.
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductThumb(
              size: 64,
              makanan: p.makanan,
              nama: p.nama,
              url: p.gambarUrl,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.nama, style: ts(18, 700, ls: -0.3)),
                  const SizedBox(height: 2),
                  Text(
                    p.deskripsi,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: ts(12, 500, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                rp(p.harga),
                style: ts(15, 800, color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),

      // Opsi minuman hanya untuk produk non-makanan
      if (!p.makanan) ...[
        const SizedBox(height: 20),
        
        // Ukuran: Tampil jika `bisaLarge` true, memakai harga dari web
        if (p.bisaLarge) ...[
          _grup(
            'Ukuran',
            _chipPilihan(
              ['Regular', 'Large'],
              _ukuran,
              (v) => setState(() => _ukuran = v),
              label: ['Regular', 'Large +${rp(_hargaLarge)}'],
              ikon: [
                (Icons.coffee_outlined, 16.0),
                (Icons.coffee_outlined, 20.0),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Suhu: Tampil dinamis sesuai `suhu` dari web (misal hanya ['Es'])
        if (p.suhu.isNotEmpty) ...[
          _grup(
            'Suhu',
            _chipPilihan(
              p.suhu,
              _suhu,
              (v) => setState(() => _suhu = v),
              ikon: p.suhu.map((s) {
                return s == 'Panas'
                    ? (Icons.local_fire_department_outlined, 18.0)
                    : (Icons.ac_unit_rounded, 18.0);
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Level gula
        _grup(
          'Level gula',
          _chipPilihan(
            ['Tanpa', 'Sedikit', 'Normal', 'Manis'],
            _gula,
            (v) => setState(() => _gula = v),
          ),
        ),

        // Level es: disembunyikan bila suhu bukan 'Es'
        if (_suhu == 'Es') ...[
          const SizedBox(height: 14),
          _grup(
            'Level es',
            _chipPilihan(
              ['Sedikit', 'Normal', 'Banyak'],
              _es,
              (v) => setState(() => _es = v),
            ),
          ),
        ],

        // Add-on: Tampil dinamis dan memakai harga dari web
        if (addOnTersedia.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text('Add-on', style: ts(12, 600, color: AppColors.muted)),
          const SizedBox(height: 4),
          for (final a in addOnTersedia) _barisAddOn(a, _addOnMenu[a] ?? 0),
        ],
      ],
      const SizedBox(height: 14),

      // Field catatan untuk barista
      TextField(
        controller: _catatanController,
        style: ts(14, 500),
        decoration: const InputDecoration(
          hintText: 'Catatan untuk barista (opsional)',
          prefixIcon: Icon(Icons.edit_outlined, size: 20),
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    ];
  }

  // _grup: label grup 12/600 muted + isi
  Widget _grup(String label, Widget isi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: ts(12, 600, color: AppColors.muted)),
        const SizedBox(height: 8),
        isi,
      ],
    );
  }

  // _chipPilihan: chip sama lebar tinggi 44 radius 14
  Widget _chipPilihan(
    List<String> opsi,
    String terpilih,
    ValueChanged<String> onChanged, {
    List<String>? label,
    List<(IconData, double)>? ikon,
  }) {
    return Row(
      children: [
        for (var i = 0; i < opsi.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _chip(
              label?[i] ?? opsi[i],
              opsi[i] == terpilih,
              () => onChanged(opsi[i]),
              ikon: ikon?[i],
            ),
          ),
        ],
      ],
    );
  }

  // _chip: satu chip pilihan tinggi 44 radius 14, ikon opsional di kiri teks
  Widget _chip(
    String teks,
    bool aktif,
    VoidCallback onTap, {
    (IconData, double)? ikon,
  }) {
    final warna = aktif ? Colors.white : AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: aktif ? AppColors.primary : AppColors.fill,
          borderRadius: BorderRadius.circular(14),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (ikon != null) ...[
                Icon(ikon.$1, size: ikon.$2, color: warna),
                const SizedBox(width: 6),
              ],
              Text(teks, style: ts(13, 700, color: warna)),
            ],
          ),
        ),
      ),
    );
  }

  // _barisAddOn: baris 44 (target sentuh) dengan checkbox kecil 18 radius 5
  Widget _barisAddOn(String nama, int harga) {
    final aktif = _addOn.contains(nama);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () =>
          setState(() => aktif ? _addOn.remove(nama) : _addOn.add(nama)),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: aktif ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                border: aktif
                    ? null
                    : Border.all(color: AppColors.disabled, width: 1.5),
              ),
              child: aktif
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(nama, style: ts(13, 600))),
            Text('+${rp(harga)}', style: ts(12, 700, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }

  // _footer: stepper jumlah + tombol "Tambah · Rp..."
  Widget _footer() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          // Stepper jumlah: tinggi 52, radius 16, latar fill
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: AppColors.fill,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Kurangi',
                  onPressed: _jumlah > 1
                      ? () => setState(() => _jumlah--)
                      : null,
                  icon: const Icon(Icons.remove_rounded, color: AppColors.ink),
                ),
                SizedBox(
                  width: 24,
                  child: Text(
                    '$_jumlah',
                    textAlign: TextAlign.center,
                    style: ts(16, 700),
                  ),
                ),
                IconButton(
                  tooltip: 'Tambah jumlah',
                  onPressed: () => setState(() => _jumlah++),
                  icon: const Icon(Icons.add_rounded, color: AppColors.ink),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Tombol utama: harga = total pilihan × jumlah
          Expanded(
            child: PrimaryButton(
              label: 'Tambah · ${rp(_hargaSatuan * _jumlah)}',
              onPressed: _tambah,
            ),
          ),
        ],
      ),
    );
  }
}