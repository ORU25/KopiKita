// Uji repository REST (Cloudinary) tanpa internet memakai MockClient.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:kopikita/data/repositories/foto_repository_cloudinary.dart';
import 'package:kopikita/domain/hasil.dart';

void main() {
  final bytes = Uint8List.fromList([1, 2, 3]);

  test('200 + secure_url → Berhasil(url)', () async {
    final klien = MockClient((req) async {
      expect(req.method, 'POST');
      expect(req.url.path, contains('/image/upload'));
      return http.Response(jsonEncode({'secure_url': 'https://cdn/x.jpg'}), 200);
    });
    final h = await FotoRepositoryCloudinary(klien: klien).unggah(bytes);
    expect(h, isA<Berhasil<String>>().having((b) => b.nilai, 'url', 'https://cdn/x.jpg'));
  });

  test('status bukan 200 → LayananBermasalah', () async {
    final klien = MockClient((_) async => http.Response('ditolak', 400));
    final h = await FotoRepositoryCloudinary(klien: klien).unggah(bytes);
    expect(h, isA<Gagal<String>>().having((g) => g.kegagalan, 'k', isA<LayananBermasalah>()));
  });

  test('putus koneksi → TanpaKoneksi', () async {
    final klien = MockClient((_) async => throw http.ClientException('offline'));
    final h = await FotoRepositoryCloudinary(klien: klien).unggah(bytes);
    expect(h, isA<Gagal<String>>().having((g) => g.kegagalan, 'k', isA<TanpaKoneksi>()));
  });
}
