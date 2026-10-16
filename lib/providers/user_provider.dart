import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? _user;
  Map<String, dynamic>? _profil;
  bool _loading = true;

  User? get user => _user;
  Map<String, dynamic>? get profil => _profil;
  bool get loading => _loading;

  String get uid => _user?.uid ?? '';
  String get nama => (_profil?['nama'] ?? _user?.displayName ?? '') as String;
  String get email => (_profil?['email'] ?? _user?.email ?? '') as String;
  String get role => (_profil?['role'] ?? 'pelanggan') as String;
  List<String> get voucher =>
      ((_profil?['voucher'] ?? []) as List).cast<String>();
  List<String> get favorit =>
      ((_profil?['favorit'] ?? []) as List).cast<String>();

  bool get isAdmin => role == 'admin';
  bool get isStaf => role == 'staf';
  bool get isPelanggan => role == 'pelanggan';

  UserProvider() {
    // Dengarkan perubahan status login
    _auth.authStateChanges().listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? u) async {
    _user = u;
    if (u == null) {
      _profil = null;
      _loading = false;
      notifyListeners();
      return;
    }

    _loading = true;
    notifyListeners();

    try {
      final snap = await _db.collection('users').doc(u.uid).get();
      _profil = snap.data();
    } catch (e) {
      debugPrint('Gagal memuat profil: $e');
      _profil = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Dipakai setelah login/register agar profil langsung segar
  Future<void> refresh() => _onAuthChanged(_auth.currentUser);

  /// Update profil lokal + Firestore (mis. ganti nama, toggle notifikasi)
  Future<void> updateProfil(Map<String, dynamic> data) async {
    if (_user == null) return;
    await _db.collection('users').doc(_user!.uid).update(data);
    _profil = {...?_profil, ...data};
    notifyListeners();
  }
}