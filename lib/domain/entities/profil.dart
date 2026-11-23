// Profil: data akun pelanggan (users/{uid}) dalam bentuk Dart murni.
class Profil {
  final String nama;
  final String email;
  final String role;
  final String fotoUrl;
  final List<String> voucher; // Kode voucher milik user
  final bool notifikasi; // Toggle notifikasi pesanan

  const Profil({
    this.nama = '',
    this.email = '',
    this.role = 'pelanggan',
    this.fotoUrl = '',
    this.voucher = const [],
    this.notifikasi = true,
  });

  // fromMap: null-safe; field yang hilang/salah tipe memakai nilai bawaan.
  factory Profil.fromMap(Map<String, dynamic>? d, {String emailCadangan = ''}) {
    final v = d?['voucher'];
    return Profil(
      nama: d?['nama'] is String ? d!['nama'] as String : '',
      email: d?['email'] is String ? d!['email'] as String : emailCadangan,
      role: d?['role'] is String ? d!['role'] as String : 'pelanggan',
      fotoUrl: d?['fotoUrl'] is String ? d!['fotoUrl'] as String : '',
      voucher: v is List ? v.whereType<String>().toList() : const [],
      notifikasi: d?['notifikasi'] is bool ? d!['notifikasi'] as bool : true,
    );
  }
}
