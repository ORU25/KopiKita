import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/hasil.dart';
import '../../domain/repositories/favorit_repository.dart';
import '../firebase_kegagalan.dart';

/// FavoritRepositoryFirestore: field users/{uid}.favorit ([productId]).
/// Menulis dengan arrayUnion/arrayRemove sehingga aman dari tulis-timpa
/// antar perangkat; stream langsung berubah dari cache lokal.
class FavoritRepositoryFirestore implements FavoritRepository {
  DocumentReference<Map<String, dynamic>>? get _ref {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid == null
        ? null
        : FirebaseFirestore.instance.collection('users').doc(uid);
  }

  @override
  Stream<Set<String>> stream() {
    final ref = _ref;
    if (ref == null) return Stream.value(const <String>{});
    return ref.snapshots().map((s) {
      final v = s.data()?['favorit'];
      return v is List ? v.whereType<String>().toSet() : const <String>{};
    }).terjemahkanGalat();
  }

  @override
  Future<Hasil<void>> set(String produkId, {required bool favorit}) =>
      coba(() async {
        final ref = _ref;
        if (ref == null || produkId.isEmpty) return;
        await ref.set({
          'favorit': favorit
              ? FieldValue.arrayUnion([produkId])
              : FieldValue.arrayRemove([produkId]),
        }, SetOptions(merge: true));
      });
}
