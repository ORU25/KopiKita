import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../domain/hasil.dart';
import '../../domain/repositories/foto_repository.dart';
import '../models/unggahan_cloudinary.dart';

/// FotoRepositoryCloudinary: unggah gambar ke Cloudinary (REST, unsigned preset).
/// Konstanta harus sama dengan repo `kopikita-web` (lihat .env di sana).
class FotoRepositoryCloudinary implements FotoRepository {
  FotoRepositoryCloudinary({
    http.Client? klien,
    this.folder = 'foto-profil',
    Duration batasWaktu = const Duration(seconds: 15),
  }) : _klien = klien ?? http.Client(),
       _batasWaktu = batasWaktu;

  final http.Client _klien; // Bisa diganti MockClient saat tes
  final String folder; // Unsigned preset wajib mengizinkan folder ini
  final Duration _batasWaktu; // Lewat dari ini → TimeoutException

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
      final res = await _klien
          .send(req)
          .then(http.Response.fromStream)
          .timeout(_batasWaktu);
      if (res.statusCode != 200) {
        return Gagal(LayananBermasalah('cloudinary-${res.statusCode}'));
      }
      final body = jsonDecode(res.body);
      if (body is! Map<String, dynamic>) {
        throw const FormatException('respons bukan objek JSON');
      }
      return Berhasil(UnggahanCloudinary.fromJson(body).secureUrl);
    } on TimeoutException {
      return const Gagal(TanpaKoneksi());
    } on http.ClientException {
      return const Gagal(TanpaKoneksi());
    } on FormatException {
      return const Gagal(LayananBermasalah('cloudinary-json'));
    }
  }
}