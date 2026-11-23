import 'dart:typed_data';

// FotoDipilih: hasil kamera / galeri (nama berkas + isinya).
class FotoDipilih {
  const FotoDipilih({required this.nama, required this.bita});
  final String nama;
  final Uint8List bita;

  static const formatDiizinkan = {'jpg', 'jpeg', 'png', 'webp'};

  /// alasanDitolak: null = foto boleh dipakai sebagai foto profil.
  String? alasanDitolak({required int maksBytes}) {
    final ext = nama.split('.').last.toLowerCase();
    if (!formatDiizinkan.contains(ext)) {
      return 'Format foto harus JPG, PNG, atau WEBP.';
    }
    if (bita.length > maksBytes) return 'Ukuran foto maksimal 2 MB.';
    return null;
  }
}
