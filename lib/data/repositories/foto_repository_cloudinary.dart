import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../domain/hasil.dart';
import '../../domain/repositories/foto_repository.dart';

/// FotoRepositoryCloudinary: unggah gambar ke Cloudinary (REST, unsigned preset).
/// Konstanta harus sama dengan repo `kopikita-web` (lihat .env di sana).
class FotoRepositoryCloudinary implements FotoRepository {
  FotoRepositoryCloudinary({http.Client? klien, this.folder = 'foto-profil'})
    : _klien = klien ?? http.Client();

  final http.Client _klien; // Bisa diganti MockClient saat tes
  final String folder; // Unsigned preset wajib mengizinkan folder ini

  // Samakan dengan VITE_CLOUDINARY_CLOUD_NAME di kopikita-web/.env
  static const _cloudName = 'djdz9inbp';
  // Samakan dengan VITE_CLOUDINARY_UPLOAD_PRESET di kopikita-web/.env
  static const _uploadPreset = 'kopikita_menu';

  @override
  Future<Hasil<String>> unggah(Uint8List bytes) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );
    final req = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = folder
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: 'foto.jpg'),
      );
    try {
      final res = await http.Response.fromStream(await _klien.send(req));
      if (res.statusCode != 200) {
        return Gagal(LayananBermasalah('cloudinary-${res.statusCode}'));
      }
      final url = (jsonDecode(res.body) as Map<String, dynamic>)['secure_url'];
      if (url is! String || url.isEmpty) {
        return const Gagal(LayananBermasalah('cloudinary-tanpa-url'));
      }
      return Berhasil(url);
    } on http.ClientException {
      return const Gagal(TanpaKoneksi());
    } on FormatException {
      return const Gagal(LayananBermasalah('cloudinary-json'));
    }
  }
}
