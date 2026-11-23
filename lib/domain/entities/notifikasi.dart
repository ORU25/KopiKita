// Notifikasi: satu pemberitahuan status pesanan (users/{uid}/notifikasi/{id}).
class Notifikasi {
  final String id;
  final String judul;
  final String pesan;
  final String orderId;
  final DateTime? waktu;
  final bool dibaca;

  const Notifikasi({
    required this.id,
    required this.judul,
    required this.pesan,
    this.orderId = '',
    this.waktu,
    this.dibaca = false,
  });

  factory Notifikasi.fromMap(String id, Map<String, dynamic> m) => Notifikasi(
    id: id,
    judul: m['judul'] as String? ?? '',
    pesan: m['pesan'] as String? ?? '',
    orderId: m['orderId'] as String? ?? '',
    waktu: m['waktu'] as DateTime?,
    dibaca: m['dibaca'] as bool? ?? false,
  );
}
