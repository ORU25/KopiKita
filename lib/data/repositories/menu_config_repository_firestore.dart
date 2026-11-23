import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/menu_config.dart';
import '../../domain/repositories/menu_config_repository.dart';

/// MenuConfigRepositoryFirestore: dokumen config/menu (diatur web Admin).
class MenuConfigRepositoryFirestore implements MenuConfigRepository {
  @override
  Future<MenuConfig> ambil() async {
    try {
      final snap = await FirebaseFirestore.instance.doc('config/menu').get();
      return MenuConfig.fromMap(snap.data());
    } catch (_) {
      return const MenuConfig(); // Offline / belum ada: nilai bawaan aman
    }
  }
}
