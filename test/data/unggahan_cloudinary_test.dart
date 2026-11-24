// Uji model JSON UnggahanCloudinary (fromJson / toJson).
import 'package:flutter_test/flutter_test.dart';

import 'package:kopikita/data/models/unggahan_cloudinary.dart';

void main() {
  test('fromJson membaca secure_url dan public_id', () {
    final m = UnggahanCloudinary.fromJson({
      'secure_url': 'https://cdn/x.jpg',
      'public_id': 'foto-profil/x',
    });
    expect(m.secureUrl, 'https://cdn/x.jpg');
    expect(m.publicId, 'foto-profil/x');
  });

  test('fromJson tanpa public_id tetap valid', () {
    final m = UnggahanCloudinary.fromJson({'secure_url': 'https://cdn/x.jpg'});
    expect(m.publicId, isNull);
  });

  test('fromJson tanpa secure_url melempar FormatException', () {
    expect(
      () => UnggahanCloudinary.fromJson({'public_id': 'x'}),
      throwsFormatException,
    );
  });

  test('toJson lalu fromJson menghasilkan nilai yang sama', () {
    const asli = UnggahanCloudinary(
      secureUrl: 'https://cdn/x.jpg',
      publicId: 'foto-profil/x',
    );
    final salinan = UnggahanCloudinary.fromJson(asli.toJson());
    expect(salinan.secureUrl, asli.secureUrl);
    expect(salinan.publicId, asli.publicId);
  });
}