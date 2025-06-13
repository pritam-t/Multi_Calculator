import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'vault_media.dart';

class VaultService {
  static const String _mediaBoxName = 'vault_media_box';
  static const _pinBoxName = 'vault_pin';
  static const _pinKey = 'user_pin';


  Future<void> addMedia(VaultMedia media) async {
    final box = Hive.box<String>(_mediaBoxName);
    final allMedia = await getAllMedia();
    allMedia.add(media);
    await box.put('media', jsonEncode(allMedia.map((m) => m.toJson()).toList()));
  }

  Future<List<VaultMedia>> getAllMedia() async {
    final box = Hive.box<String>(_mediaBoxName);
    final data = box.get('media');
    if (data == null) return [];
    final decoded = jsonDecode(data) as List<dynamic>;
    return decoded.map((json) => VaultMedia.fromJson(json)).toList();
  }

  Future<void> deleteMedia(List<VaultMedia> toDelete) async {
    final box = Hive.box<String>(_mediaBoxName);
    final current = await getAllMedia();

    final toDeletePaths = toDelete.map((m) => m.path).toSet();

    final updated = current.where((m) => !toDeletePaths.contains(m.path)).toList();

    await box.put('media', jsonEncode(updated.map((m) => m.toJson()).toList()));
  }


  Future<void> init() async {
    await Hive.initFlutter(); // Only if not already called in main()
    await Hive.openBox('vault_media');
    await Hive.openBox('vault_pin');
    await Hive.openBox<String>(_mediaBoxName);

  }

  Future<void> setPin(String pin) async {
    final box = Hive.box(_pinBoxName);
    await box.put(_pinKey, pin);
  }

  Future<bool> validatePin(String inputPin) async {
    final box = Hive.box(_pinBoxName);
    final savedPin = box.get(_pinKey);
    return savedPin == inputPin;
  }

  Future<bool> hasPin() async {
    final box = Hive.box(_pinBoxName);
    return box.containsKey(_pinKey);
  }
}

