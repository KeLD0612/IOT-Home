import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LocalStorageService {
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    print('✅ LocalStorage: Initialized');
  }

  // ════════════════════════════════════════════════════════
  // THEME SETTINGS
  // ════════════════════════════════════════════════════════

  bool getDarkMode() {
    return _prefs.getBool('dark_mode') ?? false;
  }

  Future<void> setDarkMode(bool value) async {
    await _prefs.setBool('dark_mode', value);
    print('💾 Saved dark_mode: $value');
  }

  // ════════════════════════════════════════════════════════
  // SENSOR DATA HISTORY
  // ════════════════════════════════════════════════════════

  List<Map<String, dynamic>> getSensorHistory(String sensorType) {
    final String? jsonString = _prefs.getString('history_$sensorType');
    if (jsonString == null) return [];

    try {
      final List<dynamic> decoded = json.decode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      print('❌ Error loading sensor history: $e');
      return [];
    }
  }

  Future<void> saveSensorHistory(
    String sensorType,
    List<Map<String, dynamic>> history,
  ) async {
    try {
      final String jsonString = json.encode(history);
      await _prefs.setString('history_$sensorType', jsonString);
    } catch (e) {
      print('❌ Error saving sensor history: $e');
    }
  }

  Future<void> clearSensorHistory(String sensorType) async {
    await _prefs.remove('history_$sensorType');
    print('🗑️ Cleared history for $sensorType');
  }

  // ════════════════════════════════════════════════════════
  // AUTOMATION RULES
  // ════════════════════════════════════════════════════════

  List<Map<String, dynamic>> getAutomationRules() {
    final String? jsonString = _prefs.getString('automation_rules');
    if (jsonString == null) return [];

    try {
      final List<dynamic> decoded = json.decode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      print('❌ Error loading automation rules: $e');
      return [];
    }
  }

  Future<void> saveAutomationRules(List<Map<String, dynamic>> rules) async {
    try {
      final String jsonString = json.encode(rules);
      await _prefs.setString('automation_rules', jsonString);
      print('💾 Saved ${rules.length} automation rules');
    } catch (e) {
      print('❌ Error saving automation rules: $e');
    }
  }

  // ════════════════════════════════════════════════════════
  // DEVICE STATES
  // ════════════════════════════════════════════════════════

  Map<String, dynamic> getDeviceStates() {
    final String? jsonString = _prefs.getString('device_states');
    if (jsonString == null) return {};

    try {
      return json.decode(jsonString);
    } catch (e) {
      print('❌ Error loading device states: $e');
      return {};
    }
  }

  Future<void> saveDeviceStates(Map<String, dynamic> states) async {
    try {
      final String jsonString = json.encode(states);
      await _prefs.setString('device_states', jsonString);
    } catch (e) {
      print('❌ Error saving device states: $e');
    }
  }

  // ════════════════════════════════════════════════════════
  // GENERAL SETTINGS
  // ════════════════════════════════════════════════════════

  Future<void> saveSetting(String key, dynamic value) async {
    try {
      if (value is bool) {
        await _prefs.setBool(key, value);
      } else if (value is int) {
        await _prefs.setInt(key, value);
      } else if (value is double) {
        await _prefs.setDouble(key, value);
      } else if (value is String) {
        await _prefs.setString(key, value);
      } else if (value is List<String>) {
        await _prefs.setStringList(key, value);
      } else {
        // Save as JSON string
        await _prefs.setString(key, json.encode(value));
      }
      print('💾 Saved $key: $value');
    } catch (e) {
      print('❌ Error saving setting: $e');
    }
  }

  T? getSetting<T>(String key, {T? defaultValue}) {
    try {
      final value = _prefs.get(key);
      if (value == null) return defaultValue;

      if (T == String && value is! String) {
        return defaultValue;
      }

      return value as T?;
    } catch (e) {
      print('❌ Error getting setting: $e');
      return defaultValue;
    }
  }

  Future<void> removeSetting(String key) async {
    await _prefs.remove(key);
    print('🗑️ Removed setting: $key');
  }

  Future<void> clearAll() async {
    await _prefs.clear();
    print('🗑️ Cleared all storage');
  }

  // ════════════════════════════════════════════════════════
  // NOTIFICATIONS SETTINGS
  // ════════════════════════════════════════════════════════

  bool getNotificationsEnabled() {
    return _prefs.getBool('notifications_enabled') ?? true;
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await _prefs.setBool('notifications_enabled', value);
  }

  bool getGasAlertEnabled() {
    return _prefs.getBool('gas_alert_enabled') ?? true;
  }

  Future<void> setGasAlertEnabled(bool value) async {
    await _prefs.setBool('gas_alert_enabled', value);
  }

  bool getRainAlertEnabled() {
    return _prefs.getBool('rain_alert_enabled') ?? true;
  }

  Future<void> setRainAlertEnabled(bool value) async {
    await _prefs.setBool('rain_alert_enabled', value);
  }

  // ════════════════════════════════════════════════════════
  // THRESHOLDS
  // ════════════════════════════════════════════════════════

  int getGasThreshold() {
    return _prefs.getInt('gas_threshold') ?? 1500;
  }

  Future<void> setGasThreshold(int value) async {
    await _prefs.setInt('gas_threshold', value);
  }

  int getDustThreshold() {
    return _prefs.getInt('dust_threshold') ?? 150;
  }

  Future<void> setDustThreshold(int value) async {
    await _prefs.setInt('dust_threshold', value);
  }

  double getSoilThreshold() {
    return _prefs.getDouble('soil_threshold') ?? 30.0;
  }

  Future<void> setSoilThreshold(double value) async {
    await _prefs.setDouble('soil_threshold', value);
  }

  // ════════════════════════════════════════════════════════
  // USER SETTINGS
  // ════════════════════════════════════════════════════════

  Map<String, dynamic>? getUserSettings() {
    final String? jsonString = _prefs.getString('user_settings');
    if (jsonString == null) return null;

    try {
      return json.decode(jsonString);
    } catch (e) {
      print('❌ Error loading user settings: $e');
      return null;
    }
  }

  Future<void> saveUserSettings(Map<String, dynamic> settings) async {
    try {
      final String jsonString = json.encode(settings);
      await _prefs.setString('user_settings', jsonString);
      print('💾 Saved user settings');
    } catch (e) {
      print('❌ Error saving user settings: $e');
    }
  }

  // ════════════════════════════════════════════════════════
  // MQTT CONFIGURATION
  // ════════════════════════════════════════════════════════

  Map<String, dynamic>? getMqttConfig({String? userId}) {
    final key = userId != null ? 'mqtt_config_$userId' : 'mqtt_config';
    final String? jsonString = _prefs.getString(key);
    if (jsonString == null) return null;

    try {
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('❌ Error loading MQTT config: $e');
      return null;
    }
  }

  Future<void> saveMqttConfig(
    Map<String, dynamic> config, {
    String? userId,
  }) async {
    try {
      final key = userId != null ? 'mqtt_config_$userId' : 'mqtt_config';
      final String jsonString = json.encode(config);
      await _prefs.setString(key, jsonString);
      print('💾 Saved MQTT config');
    } catch (e) {
      print('❌ Error saving MQTT config: $e');
    }
  }
}
