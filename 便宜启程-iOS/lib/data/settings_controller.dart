import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class SettingsController extends ChangeNotifier {
  SettingsController._();
  static final SettingsController instance = SettingsController._();

  AppSettings _settings = const AppSettings();
  SharedPreferences? _prefs;

  AppSettings get settings => _settings;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final prefs = _prefs!;
    _settings = AppSettings(
      reminderMasterOn: prefs.getBool('reminder_master') ?? true,
      vibrationOn: prefs.getBool('vibration') ?? true,
      defaultReminderTime: prefs.getString('default_reminder_time') ?? '09:00',
      fontColor: prefs.getInt('font_color') ?? 0xFFEAF6FF,
      fontScale: (prefs.getDouble('font_scale') ?? 1.0).clamp(0.85, 1.35),
      checkboxStyle: _parseEnum(
        prefs.getString('checkbox_style'),
        CheckboxStyle.values,
        CheckboxStyle.square,
      ),
      homeBackground: prefs.getString('home_background'),
      otherBackground: prefs.getString('other_background'),
      backgroundDim: prefs.getDouble('background_dim') ?? 0.42,
      logoPath: prefs.getString('logo_path'),
      notificationSound: prefs.getString('notification_sound') ?? 'default',
      playerSpeed: prefs.getDouble('player_speed') ?? 1.0,
      playerLoopMode: _parseEnum(
        prefs.getString('player_loop_mode'),
        PlayerLoopMode.values,
        PlayerLoopMode.off,
      ),
      selectedSongIds: (prefs.getStringList('selected_song_ids') ?? [])
          .map(int.tryParse)
          .whereType<int>()
          .toSet(),
    );
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setBool('reminder_master', _settings.reminderMasterOn);
    await prefs.setBool('vibration', _settings.vibrationOn);
    await prefs.setString('default_reminder_time', _settings.defaultReminderTime);
    await prefs.setInt('font_color', _settings.fontColor);
    await prefs.setDouble('font_scale', _settings.fontScale);
    await prefs.setString('checkbox_style', _settings.checkboxStyle.name);
    if (_settings.homeBackground == null) {
      await prefs.remove('home_background');
    } else {
      await prefs.setString('home_background', _settings.homeBackground!);
    }
    if (_settings.otherBackground == null) {
      await prefs.remove('other_background');
    } else {
      await prefs.setString('other_background', _settings.otherBackground!);
    }
    await prefs.setDouble('background_dim', _settings.backgroundDim);
    if (_settings.logoPath == null) {
      await prefs.remove('logo_path');
    } else {
      await prefs.setString('logo_path', _settings.logoPath!);
    }
    await prefs.setString('notification_sound', _settings.notificationSound);
    await prefs.setDouble('player_speed', _settings.playerSpeed);
    await prefs.setString('player_loop_mode', _settings.playerLoopMode.name);
    await prefs.setStringList(
      'selected_song_ids',
      _settings.selectedSongIds.map((id) => id.toString()).toList(),
    );
    notifyListeners();
  }

  Future<void> update(AppSettings Function(AppSettings current) transform) async {
    _settings = transform(_settings);
    await _save();
  }

  Future<void> setReminderMaster(bool value) =>
      update((current) => current.copyWith(reminderMasterOn: value));

  Future<void> setVibration(bool value) =>
      update((current) => current.copyWith(vibrationOn: value));

  Future<void> setDefaultReminderTime(String value) =>
      update((current) => current.copyWith(defaultReminderTime: value));

  Future<void> setFontColor(int value) =>
      update((current) => current.copyWith(fontColor: value));

  Future<void> setFontScale(double value) =>
      update((current) => current.copyWith(fontScale: value.clamp(0.85, 1.35)));

  Future<void> setCheckboxStyle(CheckboxStyle value) =>
      update((current) => current.copyWith(checkboxStyle: value));

  Future<void> setBackground({required bool home, String? path}) => update(
        (current) => home
            ? current.copyWith(
                homeBackground: path,
                clearHomeBackground: path == null,
              )
            : current.copyWith(
                otherBackground: path,
                clearOtherBackground: path == null,
              ),
      );

  Future<void> setBackgroundDim(double value) =>
      update((current) => current.copyWith(backgroundDim: value.clamp(0, 0.8)));

  Future<void> setLogo(String? path) => update(
        (current) => current.copyWith(logoPath: path, clearLogo: path == null),
      );

  Future<void> setNotificationSound(String value) =>
      update((current) => current.copyWith(notificationSound: value));

  Future<void> setPlayerSpeed(double value) =>
      update((current) => current.copyWith(playerSpeed: value.clamp(0.5, 2.0)));

  Future<void> setLoopMode(PlayerLoopMode value) =>
      update((current) => current.copyWith(playerLoopMode: value));

  Future<void> setSelectedSongIds(Set<int> value) =>
      update((current) => current.copyWith(selectedSongIds: value));

  Future<void> clear() async {
    _prefs = await SharedPreferences.getInstance();
    await _prefs!.clear();
    _settings = const AppSettings();
    notifyListeners();
  }

  T _parseEnum<T extends Enum>(String? name, List<T> values, T fallback) {
    if (name == null) return fallback;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }
}
