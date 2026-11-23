// Implementasi ASLI fitur perangkat. Hanya file ini yang mengenal paket
// geolocator dan image_picker, sekaligus menjadi "penerjemah" exception-nya
// menjadi Kegagalan (Pertemuan 13, Bagian 9.4).
import 'dart:async';

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/services.dart' show PlatformException;
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import 'perangkat.dart';

class LayananLokasiGeolocator implements LayananLokasi {
  const LayananLokasiGeolocator();

  @override
  Future<Hasil<Posisi>> posisiSekarang() async {
    // 1. Layanan (sakelar Lokasi). Di web selalu true.
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const Gagal(LayananLokasiMati());
    }

    // 2. Izin. check tidak memunculkan dialog; request hanya jika masih boleh.
    final Kegagalan? masalahIzin = await _periksaIzin();
    if (masalahIzin != null) return Gagal(masalahIzin);

    // 3. Posisi, dengan batas waktu agar tidak menunggu tanpa akhir.
    try {
      final Position p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return Berhasil(_kePosisi(p));
    } on TimeoutException {
      return const Gagal(WaktuHabis());
    } on LocationServiceDisabledException {
      return const Gagal(LayananLokasiMati());
    } on PermissionDeniedException {
      return const Gagal(IzinDitolak(Fitur.lokasi));
    } on PositionUpdateException catch (e) {
      return Gagal(GangguanPerangkat(e.toString()));
    }
  }

  @override
  Stream<Hasil<Posisi>> ikutiPosisi({int jarakMinimumMeter = 10}) async* {
    if (!await Geolocator.isLocationServiceEnabled()) {
      yield const Gagal(LayananLokasiMati());
      return;
    }
    final Kegagalan? masalahIzin = await _periksaIzin();
    if (masalahIzin != null) {
      yield Gagal(masalahIzin);
      return;
    }
    // Langganan langsung diteruskan; pemanggil wajib cancel() di dispose().
    yield* Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: jarakMinimumMeter,
      ),
    ).transform(
      StreamTransformer<Position, Hasil<Posisi>>.fromHandlers(
        handleData: (p, sink) => sink.add(Berhasil(_kePosisi(p))),
        handleError: (e, st, sink) {
          if (e is LocationServiceDisabledException) {
            sink.add(const Gagal(LayananLokasiMati()));
          } else if (e is PermissionDeniedException) {
            sink.add(const Gagal(IzinDitolak(Fitur.lokasi)));
          } else {
            sink.add(Gagal(GangguanPerangkat(e.toString())));
          }
          sink.close();
        },
      ),
    );
  }

  /// null = izin siap dipakai. Selain itu, kegagalan yang harus dikembalikan.
  Future<Kegagalan?> _periksaIzin() async {
    LocationPermission izin = await Geolocator.checkPermission();
    if (izin == LocationPermission.denied ||
        izin == LocationPermission.unableToDetermine) {
      izin = await Geolocator.requestPermission();
    }
    return switch (izin) {
      LocationPermission.denied => const IzinDitolak(Fitur.lokasi),
      LocationPermission.deniedForever => const IzinDiblokir(Fitur.lokasi),
      LocationPermission.whileInUse ||
      LocationPermission.always ||
      LocationPermission.unableToDetermine => null,
    };
  }

  Posisi _kePosisi(Position p) => Posisi(
    lintang: p.latitude,
    bujur: p.longitude,
    akurasiMeter: p.accuracy,
    waktu: p.timestamp.toLocal(),
    palsu: p.isMocked,
  );
}

class PemilihFotoImagePicker implements PemilihFoto {
  PemilihFotoImagePicker({this.lebarMaks = 512, this.kualitas = 85});

  final double lebarMaks;
  final int kualitas;

  // Cukup satu objek, dan penjaga agar pemilih tidak terbuka dua kali.
  final ImagePicker _pemilih = ImagePicker();
  bool _sibuk = false;

  @override
  bool get kameraTersedia => _pemilih.supportsImageSource(ImageSource.camera);

  @override
  Future<Hasil<FotoDipilih>> ambil({required bool dariKamera}) async {
    if (_sibuk) return const Gagal(PemilihSibuk());
    _sibuk = true;
    try {
      final XFile? berkas = await _pemilih.pickImage(
        source: dariKamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: lebarMaks,
        imageQuality: kualitas,
        preferredCameraDevice: CameraDevice.front,
        // Metadata lengkap (mis. lokasi pemotretan) tidak kita perlukan.
        requestFullMetadata: false,
      );
      if (berkas == null) return const Gagal(Dibatalkan());
      return Berhasil(
        FotoDipilih(nama: berkas.name, bita: await berkas.readAsBytes()),
      );
    } on PlatformException catch (e) {
      return Gagal(_terjemahkan(e));
    } finally {
      _sibuk = false;
    }
  }

  @override
  Future<Hasil<FotoDipilih>?> fotoHilang() async {
    // retrieveLostData() hanya tersedia di Android.
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      final LostDataResponse r = await _pemilih.retrieveLostData();
      final XFile? berkas = r.file;
      if (berkas == null) return null;
      return Berhasil(
        FotoDipilih(nama: berkas.name, bita: await berkas.readAsBytes()),
      );
    } on PlatformException catch (e) {
      return Gagal(_terjemahkan(e));
    }
  }

  Kegagalan _terjemahkan(PlatformException e) {
    return switch (e.code) {
      'camera_access_denied' => const IzinDiblokir(Fitur.kamera),
      'photo_access_denied' => const IzinDiblokir(Fitur.galeri),
      'camera_access_restricted' => const IzinDiblokir(Fitur.kamera),
      'photo_access_restricted' => const IzinDiblokir(Fitur.galeri),
      'no_available_camera' => const PerangkatTidakMendukung(Fitur.kamera),
      'already_active' || 'multiple_request' => const PemilihSibuk(),
      _ => GangguanPerangkat(e.code),
    };
  }
}

class PengaturanPerangkatAsli implements PengaturanPerangkat {
  const PengaturanPerangkatAsli();

  // Di web kedua fungsi ini melempar UnsupportedError, jadi dilewati.
  @override
  Future<void> bukaPengaturanAplikasi() async {
    if (kIsWeb) return;
    await Geolocator.openAppSettings();
  }

  @override
  Future<void> bukaPengaturanLokasi() async {
    if (kIsWeb) return;
    await Geolocator.openLocationSettings();
  }
}