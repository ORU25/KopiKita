import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/profil.dart';
import '../../domain/hasil.dart';
import '../../domain/repositories/profil_repository.dart';
import '../firebase_kegagalan.dart';

/// ProfilRepositoryFirestore: dokumen users/{uid} milik user yang login.
class ProfilRepositoryFirestore implements ProfilRepository {
  User? get _user => FirebaseAuth.instance.currentUser;

  DocumentReference<Map<String, dynamic>>? get _ref {
    final u = _user;
    return u == null
        ? null
        : FirebaseFirestore.instance.collection('users').doc(u.uid);
  }

  @override
  Stream<Profil> stream() {
    final ref = _ref;
    if (ref == null) return Stream.value(const Profil());
    final email = _user?.email ?? '';
    return ref
        .snapshots()
        .map((s) => Profil.fromMap(s.data(), emailCadangan: email))
        .terjemahkanGalat();
  }

  Future<Hasil<void>> _update(Map<String, dynamic> data) =>
      coba(() async => _ref?.update(data));

  @override
  Future<Hasil<void>> ubah({required String nama, String? fotoUrl}) =>
      _update({'nama': nama, 'fotoUrl': ?fotoUrl});

  @override
  Future<Hasil<void>> setNotifikasi(bool aktif) =>
      _update({'notifikasi': aktif});
}
