/// UnggahanCloudinary: model respons JSON dari API upload Cloudinary.
/// `fromJson` memvalidasi isi respons; bila tidak valid melempar FormatException
/// agar repository dapat menerjemahkannya menjadi Kegagalan.
class UnggahanCloudinary {
  const UnggahanCloudinary({required this.secureUrl, this.publicId});

  final String secureUrl;
  final String? publicId;

  factory UnggahanCloudinary.fromJson(Map<String, dynamic> json) {
    final url = json['secure_url'];
    if (url is! String || url.isEmpty) {
      throw const FormatException('secure_url kosong');
    }
    final id = json['public_id'];
    return UnggahanCloudinary(
      secureUrl: url,
      publicId: id is String ? id : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'secure_url': secureUrl,
    'public_id': publicId,
  };
}