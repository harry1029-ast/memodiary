import 'package:flutter/foundation.dart';

import '../services/editor_settings_service.dart';
import 'ink_choreography_config.dart';

/// The live Ink Choreography preferences of one entry editor, shared by the
/// Scholar's Stationery Chest (which changes them) and the Stationery Sheet
/// overlay (which writes with them). Notifies on every config change;
/// [sheetReplayRequests] notifies separately for 全页挥毫.
class InkChoreographyController extends ChangeNotifier {
  /// The app-wide preference store. Null keeps the controller memory-only.
  final EditorSettingsService? _settings;

  InkChoreographyController({EditorSettingsService? settings}) : _settings = settings;

  final ValueNotifier<int> _sheetReplayRequests = ValueNotifier<int>(0);
  InkChoreographyConfig _config = const InkChoreographyConfig();
  bool _hasChosenDeliveryMode = false;
  bool _hasChosenBristleStiffness = false;
  bool _hasChosenCadence = false;
  bool _hasChosenSound = false;
  bool _isDisposed = false;

  InkChoreographyConfig get config => _config;

  /// Ticks once per [requestSheetReplay]; the value counts the requests of
  /// this session.
  ValueListenable<int> get sheetReplayRequests => _sheetReplayRequests;

  void setDeliveryMode(InkDeliveryMode mode) {
    _hasChosenDeliveryMode = true;
    if (_apply(_config.copyWith(deliveryMode: mode))) _settings?.setInkDeliveryMode(mode);
  }

  void setBristleStiffness(BristleStiffness stiffness) {
    _hasChosenBristleStiffness = true;
    if (_apply(_config.copyWith(bristleStiffness: stiffness))) _settings?.setBristleStiffness(stiffness);
  }

  void setCadence(WritingCadence cadence) {
    _hasChosenCadence = true;
    if (_apply(_config.copyWith(cadence: cadence))) _settings?.setWritingCadence(cadence);
  }

  void setSoundEnabled(bool isEnabled) {
    _hasChosenSound = true;
    if (_apply(_config.copyWith(soundEnabled: isEnabled))) _settings?.setBrushSoundEnabled(isEnabled);
  }

  /// Applies the stored preferences, field by field, except those the diarist
  /// has already chosen in this session.
  Future<void> restorePreferences() async {
    final settings = _settings;
    if (settings == null) return;
    final stored = await settings.getInkChoreographyConfig();
    if (_isDisposed) return;
    _apply(
      _config.copyWith(
        deliveryMode: _hasChosenDeliveryMode ? null : stored.deliveryMode,
        bristleStiffness: _hasChosenBristleStiffness ? null : stored.bristleStiffness,
        cadence: _hasChosenCadence ? null : stored.cadence,
        soundEnabled: _hasChosenSound ? null : stored.soundEnabled,
      ),
    );
  }

  /// Asks the active Stationery Sheet to replay all of its characters
  /// (全页挥毫). The saved delivery mode is left untouched.
  void requestSheetReplay() {
    if (_isDisposed) return;
    _sheetReplayRequests.value++;
  }

  bool _apply(InkChoreographyConfig next) {
    if (next == _config) return false;
    _config = next;
    notifyListeners();
    return true;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _sheetReplayRequests.dispose();
    super.dispose();
  }
}
