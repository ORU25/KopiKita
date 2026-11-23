import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/hasil.dart';
import '../../domain/repositories/auth_repository.dart';
import '../firebase_kegagalan.dart';

/// AuthRepositoryFirebase: Firebase Auth + dokumen users/{uid}.
class AuthRepositoryFirebase implements AuthRepository {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  String? get uid => _auth.currentUser?.uid;

  @override
  Stream<String?> perubahanUid() => _auth.authStateChanges().map((u) => u?.uid);

  Map<String, dynamic> _profilBaru(
    String nama,
    String email,
    List<String> voucher,
  ) => {
    'nama': nama,
    'email': email,
    'role': 'pelanggan',
    'favorit': <String>[],
    'voucher': voucher,
    'notifikasi': true,
    'createdAt': FieldValue.serverTimestamp(),
  };

  @override
  Future<Hasil<void>> masuk({required String email, required String sandi}) =>
      coba(() async {
        final cred = await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: sandi,
        );
        final user = cred.user!;
        final ref = _db.collection('users').doc(user.uid);
        // Cadangan: user Auth ada tapi dokumen Firestore hilang.
        if (!(await ref.get()).exists) {
          await ref.set(
            _profilBaru(
              user.displayName ?? email.trim().split('@').first,
              user.email ?? email.trim(),
              const [],
            ),
          );
        }
      });

  @override
  Future<Hasil<void>> daftar({
    required String nama,
    required String email,
    required String sandi,
  }) => coba(() async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: sandi,
    );
    final user = cred.user!;
    await user.updateDisplayName(nama.trim());
    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .set(
            _profilBaru(nama.trim(), user.email ?? email.trim(), const [
              'KOPIKITA20',
              'HEMAT5RB',
            ]),
          );
    } catch (_) {
      // Hindari akun Auth tanpa dokumen users jika Firestore gagal.
      try {
        await user.delete();
      } catch (_) {
        await _auth.signOut();
      }
      rethrow;
    }
  });

  @override
  Future<Hasil<void>> kirimResetSandi(String email) =>
      coba(() => _auth.sendPasswordResetEmail(email: email.trim()));

  @override
  Future<Hasil<void>> ubahSandi({required String lama, required String baru}) =>
      coba(() async {
        final user = _auth.currentUser!;
        await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: user.email!, password: lama),
        );
        await user.updatePassword(baru);
      });

  @override
  Future<void> keluar() => _auth.signOut();
}
