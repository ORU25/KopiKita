import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// CloudinaryAccService: upload gambar ke Cloudinary (unsigned preset).
/// Konstanta harus sama dengan repo `kopikita-web` (lihat .env di sana).
class CloudinaryAccService {
  // Samakan dengan VITE_CLOUDINARY_CLOUD_NAME di kopikita-web/.env
  static const _cloudName = 'djdz9inbp';
  // Samakan dengan VITE_CLOUDINARY_UPLOAD_PRESET di kopikita-web/.env
  static const _uploadPreset = 'kopikita_menu';

  /// Upload bytes (hasil image_picker) ke Cloudinary.
  /// Mengembalikan `secure_url` (https) yang siap disimpan ke Firestore.
  static Future<String> uploadBytes(Uint8List bytes, {String folder = 'foto-profil'}) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');

    final req = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = folder // Cloudinary unsigned preset wajib izinkan folder ini
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: 'foto.jpg'));

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode != 200) {
      throw Exception('Upload gagal (${res.statusCode}): ${res.body}');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final url = json['secure_url'];
    if (url is! String || url.isEmpty) {
      throw Exception('Cloudinary tidak mengembalikan URL.');
    }
    return url;
  }
}