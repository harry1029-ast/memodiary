import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../ink_choreography/ink_choreography_config.dart';

/// Persists the entry editor's app-wide preferences in the existing local
/// settings store. Never part of an entry.
class EditorSettingsService {
  static const String _keyWritingDockHidden = 'memodiary_editor_writing_dock_hidden';
  static const String _keyInkDeliveryMode = 'memodiary_editor_ink_delivery_mode';
  static const String _keyBristleStiffness = 'memodiary_editor_ink_bristle_stiffness';
  static const String _keyWritingCadence = 'memodiary_editor_ink_writing_cadence';
  static const String _keyBrushSound = 'memodiary_editor_ink_brush_sound';

  final FlutterSecureStorage _storage;

  EditorSettingsService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
            );

  /// Whether the diarist put the Writing Dock away. Defaults to `false`.
  Future<bool> getIsWritingDockHidden() async => await _read(_keyWritingDockHidden) == 'true';

  Future<void> setIsWritingDockHidden(bool isHidden) => _write(_keyWritingDockHidden, isHidden ? 'true' : 'false');

  /// The diarist's Ink Choreography preferences. A missing or unknown value
  /// reads back as that field's default.
  Future<InkChoreographyConfig> getInkChoreographyConfig() async {
    final stored = await Future.wait([
      _read(_keyInkDeliveryMode),
      _read(_keyBristleStiffness),
      _read(_keyWritingCadence),
      _read(_keyBrushSound),
    ]);
    return InkChoreographyConfig(
      deliveryMode: InkDeliveryMode.fromStorageId(stored[0]),
      bristleStiffness: BristleStiffness.fromStorageId(stored[1]),
      cadence: WritingCadence.fromStorageId(stored[2]),
      soundEnabled: stored[3] != 'false',
    );
  }

  Future<void> setInkDeliveryMode(InkDeliveryMode mode) => _write(_keyInkDeliveryMode, mode.storageId);

  Future<void> setBristleStiffness(BristleStiffness stiffness) => _write(_keyBristleStiffness, stiffness.storageId);

  Future<void> setWritingCadence(WritingCadence cadence) => _write(_keyWritingCadence, cadence.storageId);

  Future<void> setBrushSoundEnabled(bool isEnabled) => _write(_keyBrushSound, isEnabled ? 'true' : 'false');

  Future<String?> _read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return null;
    }
  }

  Future<void> _write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      // Storage errors in restricted environments are absorbed.
    }
  }
}
