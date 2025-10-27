import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kpass/core/constants/campus_constants.dart';
import 'package:kpass/core/utils/period_calculator.dart';

class SettingsProvider extends ChangeNotifier {
  SharedPreferences? _prefs;

  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('ja', ''); // Default to Japanese
  bool _notificationsEnabled = true;
  bool _calendarSyncEnabled = true;
  int _upcomingAssignmentsDays = 7; // デフォルトは7日以内
  KeioCampus _selectedCampus = KeioCampus.hiyoshi; // デフォルトは日吉キャンパス
  bool _showWeekendsInTimetable = false; // デフォルトは土日を非表示

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get calendarSyncEnabled => _calendarSyncEnabled;
  int get upcomingAssignmentsDays => _upcomingAssignmentsDays;
  KeioCampus get selectedCampus => _selectedCampus;
  bool get showWeekendsInTimetable => _showWeekendsInTimetable;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      _prefs = await SharedPreferences.getInstance();

      // テーマモードの読み込み
      final themeString = _prefs?.getString('theme_mode');
      if (themeString != null) {
        switch (themeString) {
          case 'light':
            _themeMode = ThemeMode.light;
            break;
          case 'dark':
            _themeMode = ThemeMode.dark;
            break;
          default:
            _themeMode = ThemeMode.system;
        }
      }

      // ロケールの読み込み
      final localeString = _prefs?.getString('locale');
      if (localeString != null) {
        if (localeString == 'en') {
          _locale = const Locale('en', '');
        } else {
          _locale = const Locale('ja', '');
        }
      }

      // 通知設定の読み込み
      final notificationsEnabled = _prefs?.getBool('notifications_enabled');
      if (notificationsEnabled != null) {
        _notificationsEnabled = notificationsEnabled;
      }

      // カレンダー同期設定の読み込み
      final calendarSyncEnabled = _prefs?.getBool('calendar_sync_enabled');
      if (calendarSyncEnabled != null) {
        _calendarSyncEnabled = calendarSyncEnabled;
      }

      // 課題表示範囲の読み込み
      final days = _prefs?.getInt('upcoming_assignments_days');
      if (days != null && days > 0) {
        _upcomingAssignmentsDays = days;
      }

      // キャンパス設定の読み込み
      final campusString = _prefs?.getString('selected_campus');
      if (campusString != null) {
        switch (campusString) {
          case 'hiyoshi':
            _selectedCampus = KeioCampus.hiyoshi;
            break;
          case 'mita':
            _selectedCampus = KeioCampus.mita;
            break;
          case 'sfc':
            _selectedCampus = KeioCampus.sfc;
            break;
          case 'shinanomachi':
            _selectedCampus = KeioCampus.shinanomachi;
            break;
          default:
            _selectedCampus = KeioCampus.hiyoshi;
        }
      }

      // 土日表示設定の読み込み
      final showWeekends = _prefs?.getBool('show_weekends_in_timetable');
      if (showWeekends != null) {
        _showWeekendsInTimetable = showWeekends;
      }

      // PeriodCalculatorにキャンパス設定を反映
      PeriodCalculator.setCampus(_selectedCampus);

      notifyListeners();
    } catch (e) {
      // エラーが発生してもデフォルト値を使用
      notifyListeners();
    }
  }

  Future<void> _saveSettings() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }

    await _prefs!.setString(
      'theme_mode',
      _themeMode == ThemeMode.light
          ? 'light'
          : _themeMode == ThemeMode.dark
          ? 'dark'
          : 'system',
    );

    await _prefs!.setString('locale', _locale.languageCode);
    await _prefs!.setBool('notifications_enabled', _notificationsEnabled);
    await _prefs!.setBool('calendar_sync_enabled', _calendarSyncEnabled);
    await _prefs!.setInt('upcoming_assignments_days', _upcomingAssignmentsDays);
    await _prefs!.setBool(
      'show_weekends_in_timetable',
      _showWeekendsInTimetable,
    );

    // キャンパス設定の保存
    String campusString;
    switch (_selectedCampus) {
      case KeioCampus.hiyoshi:
        campusString = 'hiyoshi';
        break;
      case KeioCampus.mita:
        campusString = 'mita';
        break;
      case KeioCampus.sfc:
        campusString = 'sfc';
        break;
      case KeioCampus.shinanomachi:
        campusString = 'shinanomachi';
        break;
    }
    await _prefs!.setString('selected_campus', campusString);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setCalendarSyncEnabled(bool enabled) async {
    _calendarSyncEnabled = enabled;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setUpcomingAssignmentsDays(int days) async {
    _upcomingAssignmentsDays = days;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setSelectedCampus(KeioCampus campus) async {
    _selectedCampus = campus;
    // PeriodCalculatorにキャンパス設定を反映
    PeriodCalculator.setCampus(campus);
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setShowWeekendsInTimetable(bool show) async {
    _showWeekendsInTimetable = show;
    notifyListeners();
    await _saveSettings();
  }
}
