import 'dart:typed_data';

import '../hasil.dart';

/// FotoRepository: KONTRAK unggah gambar; Berhasil berisi URL https.
abstract class FotoRepository {
  Future<Hasil<String>> unggah(Uint8List bytes);
}
