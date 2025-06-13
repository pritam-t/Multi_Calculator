import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'vault_media.dart';

class VaultService {
  static const String _mediaBoxName = 'vault_media_box';
  static const _pinBoxName = 'vault_pin';
  static const _pinKey = 'user_pin';
  static const _lockKey = 'vault_locked';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late Box<String> _mediaBox;
  late Box _pinBox;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Initialize boxes only once
      _mediaBox = await Hive.openBox<String>(_mediaBoxName);
      _pinBox = await Hive.openBox(_pinBoxName);
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing VaultService: $e');
      rethrow;
    }
  }

  // Media Operations
  Future<void> addMedia(VaultMedia media) async {
    await init();
    final mediaList = await _getDecodedMediaList();
    mediaList.add(media);
    await _saveMediaList(mediaList);
  }

  Future<List<VaultMedia>> getAllMedia() async {
    await init();
    return _getDecodedMediaList();
  }

  Future<List<VaultMedia>> getMediaPaginated(int page, int limit) async {
    final allMedia = await getAllMedia();
    return allMedia.skip(page * limit).take(limit).toList();
  }

  Future<void> deleteMedia(List<VaultMedia> toDelete) async {
    await init();
    final mediaList = await _getDecodedMediaList();
    final toDeletePaths = toDelete.map((m) => m.path).toSet();

    await Future.wait(toDelete.map((m) => m.dispose()));

    final updatedList = mediaList.where((m) => !toDeletePaths.contains(m.path)).toList();
    await _saveMediaList(updatedList);
  }

  // PIN Operations
  Future<void> setPin(String pin) async {
    await init();
    final hashedPin = _hashPin(pin);
    await _pinBox.put(_pinKey, hashedPin);
  }

  Future<bool> validatePin(String inputPin) async {
    await init();
    final savedPin = _pinBox.get(_pinKey);
    return savedPin == _hashPin(inputPin);
  }

  Future<bool> hasPin() async {
    await init();
    return _pinBox.containsKey(_pinKey);
  }

  // Security Operations
  Future<void> toggleLock() async {
    final currentState = await _secureStorage.read(key: _lockKey);
    await _secureStorage.write(
      key: _lockKey,
      value: currentState == 'true' ? 'false' : 'true',
    );
  }

  Future<bool> isLocked() async {
    return await _secureStorage.read(key: _lockKey) == 'true';
  }

  // Private Helpers
  Future<List<VaultMedia>> _getDecodedMediaList() async {
    final data = _mediaBox.get('media');
    if (data == null) return [];
    try {
      final decoded = jsonDecode(data) as List<dynamic>;
      return decoded.map((json) => VaultMedia.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error decoding media: $e');
      return [];
    }
  }

  Future<void> _saveMediaList(List<VaultMedia> mediaList) async {
    await _mediaBox.put('media', jsonEncode(mediaList.map((m) => m.toJson()).toList()));
  }

  String _hashPin(String pin) {
    // Basic hashing - consider using package:crypto for stronger hashing
    return pin.codeUnits.join('');
  }

  // Cleanup
  Future<void> dispose() async {
    if (_isInitialized) {
      await Future.wait([
        _mediaBox.compact(),
        _pinBox.compact(),
      ]);
    }
  }

  Future<void> deleteAllMedia() async {
    await init();
    await _mediaBox.clear();
    await _mediaBox.compact();
  }
}