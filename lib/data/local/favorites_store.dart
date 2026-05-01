import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/wallpaper.dart';

/// Local-only favorites store backed by SharedPreferences (good enough for
/// phase 1 — no account needed). Migrate to Hive/Isar if list grows large.
class FavoritesStore extends ChangeNotifier {
  FavoritesStore(this._prefs) {
    _load();
  }

  static const _key = 'wolwo.favorites.v1';
  final SharedPreferences _prefs;

  final Map<String, Wallpaper> _items = {};

  List<Wallpaper> get items => _items.values.toList();
  int get count => _items.length;

  bool isFavorite(Wallpaper w) => _items.containsKey(w.globalKey);

  Future<void> toggle(Wallpaper w) async {
    if (_items.remove(w.globalKey) == null) {
      _items[w.globalKey] = w;
    }
    await _save();
    notifyListeners();
  }

  Future<void> remove(Wallpaper w) async {
    if (_items.remove(w.globalKey) != null) {
      await _save();
      notifyListeners();
    }
  }

  void _load() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      for (final j in list) {
        final w = Wallpaper.fromJson(j);
        _items[w.globalKey] = w;
      }
    } catch (_) {
      // corrupted blob — start fresh
    }
  }

  Future<void> _save() async {
    final list = _items.values.map((w) => w.toJson()).toList();
    await _prefs.setString(_key, jsonEncode(list));
  }
}
