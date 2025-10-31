import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/sensor_data.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';
import '../config/constants.dart';

class SensorProvider extends ChangeNotifier {
  final LocalStorageService _storageService;
  final NotificationService _notificationService;

  SensorData _currentData = SensorData.empty();
  List<SensorData> _history = [];
  bool _gasAlertShown = false;
  bool _rainAlertShown = false;
  bool _soilAlertShown = false;
  bool _dustAlertShown = false;

  SensorData get currentData => _currentData;
  List<SensorData> get history => _history;

  // Individual sensor getters
  double get temperature => _currentData.temperature;
  double get humidity => _currentData.humidity;
  int get rain => _currentData.rain;
  int get light => _currentData.light;
  int get soilMoisture => _currentData.soilMoisture;
  int get gas => _currentData.gas;
  int get dust => _currentData.dust;
  bool get motionDetected => _currentData.motionDetected;

  SensorProvider(this._storageService, this._notificationService) {
    _loadHistory();
  }

  void updateSensorData(SensorData data) {
    _currentData = data;
    _addToHistory(data);
    _checkAlerts(data);
    _safeNotify();
  }

  void updateTemperature(double value) {
    _currentData = SensorData(
      temperature: value,
      humidity: _currentData.humidity,
      rain: _currentData.rain,
      light: _currentData.light,
      soilMoisture: _currentData.soilMoisture,
      gas: _currentData.gas,
      dust: _currentData.dust,
      motionDetected: _currentData.motionDetected,
      timestamp: DateTime.now(),
    );
    _addToHistory(_currentData);
    _safeNotify();
  }

  void updateHumidity(double value) {
    _currentData = SensorData(
      temperature: _currentData.temperature,
      humidity: value,
      rain: _currentData.rain,
      light: _currentData.light,
      soilMoisture: _currentData.soilMoisture,
      gas: _currentData.gas,
      dust: _currentData.dust,
      motionDetected: _currentData.motionDetected,
      timestamp: DateTime.now(),
    );
    _addToHistory(_currentData);
    _safeNotify();
  }

  void updateRain(int value) {
    _currentData = SensorData(
      temperature: _currentData.temperature,
      humidity: _currentData.humidity,
      rain: value,
      light: _currentData.light,
      soilMoisture: _currentData.soilMoisture,
      gas: _currentData.gas,
      dust: _currentData.dust,
      motionDetected: _currentData.motionDetected,
      timestamp: DateTime.now(),
    );

    // Rain alert
    if (value == 1 && !_rainAlertShown) {
      _notificationService.showRainAlert();
      _rainAlertShown = true;
    } else if (value == 0) {
      _rainAlertShown = false;
    }

    _addToHistory(_currentData);
    _safeNotify();
  }

  void updateLight(int value) {
    _currentData = SensorData(
      temperature: _currentData.temperature,
      humidity: _currentData.humidity,
      rain: _currentData.rain,
      light: value,
      soilMoisture: _currentData.soilMoisture,
      gas: _currentData.gas,
      dust: _currentData.dust,
      motionDetected: _currentData.motionDetected,
      timestamp: DateTime.now(),
    );
    _addToHistory(_currentData);
    _safeNotify();
  }

  void updateSoilMoisture(int value) {
    _currentData = SensorData(
      temperature: _currentData.temperature,
      humidity: _currentData.humidity,
      rain: _currentData.rain,
      light: _currentData.light,
      soilMoisture: value,
      gas: _currentData.gas,
      dust: _currentData.dust,
      motionDetected: _currentData.motionDetected,
      timestamp: DateTime.now(),
    );

    // Soil moisture alert
    if (value < AppConstants.lowSoilMoisture && !_soilAlertShown) {
      _notificationService.showLowSoilMoistureAlert();
      _soilAlertShown = true;
    } else if (value >= AppConstants.lowSoilMoisture) {
      _soilAlertShown = false;
    }

    _addToHistory(_currentData);
    _safeNotify();
  }

  void updateGas(int value) {
    _currentData = SensorData(
      temperature: _currentData.temperature,
      humidity: _currentData.humidity,
      rain: _currentData.rain,
      light: _currentData.light,
      soilMoisture: _currentData.soilMoisture,
      gas: value,
      dust: _currentData.dust,
      motionDetected: _currentData.motionDetected,
      timestamp: DateTime.now(),
    );

    // Gas alert
    if (value > AppConstants.gasWarningLevel && !_gasAlertShown) {
      _notificationService.showGasAlert(value);
      _gasAlertShown = true;
    } else if (value <= AppConstants.gasWarningLevel) {
      _gasAlertShown = false;
    }

    _addToHistory(_currentData);
    _safeNotify();
  }

  void updateDust(int value) {
    _currentData = SensorData(
      temperature: _currentData.temperature,
      humidity: _currentData.humidity,
      rain: _currentData.rain,
      light: _currentData.light,
      soilMoisture: _currentData.soilMoisture,
      gas: _currentData.gas,
      dust: value,
      motionDetected: _currentData.motionDetected,
      timestamp: DateTime.now(),
    );

    // Dust alert
    if (value > AppConstants.dustWarningLevel && !_dustAlertShown) {
      _notificationService.showHighDustAlert(value);
      _dustAlertShown = true;
    } else if (value <= AppConstants.dustWarningLevel) {
      _dustAlertShown = false;
    }

    _addToHistory(_currentData);
    _safeNotify();
  }

  void updateMotion(bool detected) {
    _currentData = SensorData(
      temperature: _currentData.temperature,
      humidity: _currentData.humidity,
      rain: _currentData.rain,
      light: _currentData.light,
      soilMoisture: _currentData.soilMoisture,
      gas: _currentData.gas,
      dust: _currentData.dust,
      motionDetected: detected,
      timestamp: DateTime.now(),
    );

    if (detected) {
      _notificationService.showMotionDetectedAlert();
    }

    _addToHistory(_currentData);
    _safeNotify();
  }

  void _addToHistory(SensorData data) {
    _history.add(data);

    // Keep only last 100 data points
    if (_history.length > AppConstants.maxDataPoints) {
      _history.removeAt(0);
    }

    _saveHistory();
  }

  void _checkAlerts(SensorData data) {
    // Gas alert
    if (data.gas > AppConstants.gasWarningLevel && !_gasAlertShown) {
      _notificationService.showGasAlert(data.gas);
      _gasAlertShown = true;
    } else if (data.gas <= AppConstants.gasWarningLevel) {
      _gasAlertShown = false;
    }

    // Rain alert
    if (data.rain == 1 && !_rainAlertShown) {
      _notificationService.showRainAlert();
      _rainAlertShown = true;
    } else if (data.rain == 0) {
      _rainAlertShown = false;
    }

    // Soil moisture alert
    if (data.soilMoisture < AppConstants.lowSoilMoisture && !_soilAlertShown) {
      _notificationService.showLowSoilMoistureAlert();
      _soilAlertShown = true;
    } else if (data.soilMoisture >= AppConstants.lowSoilMoisture) {
      _soilAlertShown = false;
    }

    // Dust alert
    if (data.dust > AppConstants.dustWarningLevel && !_dustAlertShown) {
      _notificationService.showHighDustAlert(data.dust);
      _dustAlertShown = true;
    } else if (data.dust <= AppConstants.dustWarningLevel) {
      _dustAlertShown = false;
    }

    // Motion detected
    if (data.motionDetected) {
      _notificationService.showMotionDetectedAlert();
    }
  }

  void _loadHistory() {
    final stored = _storageService.getSensorHistory('all');
    _history = stored.map((json) => SensorData.fromJson(json)).toList();
    print('📊 Loaded ${_history.length} sensor history records');
  }

  void _saveHistory() {
    final jsonList = _history.map((data) => data.toJson()).toList();
    _storageService.saveSensorHistory('all', jsonList);
  }

  void clearHistory() {
    _history.clear();
    _saveHistory();
    _safeNotify();
  }

  List<SensorData> getHistoryByTimeRange(DateTime start, DateTime end) {
    return _history.where((data) {
      return data.timestamp.isAfter(start) && data.timestamp.isBefore(end);
    }).toList();
  }

  List<SensorData> getRecentHistory(int count) {
    if (_history.length <= count) {
      return _history;
    }
    return _history.sublist(_history.length - count);
  }

  /// Add user sensor (placeholder for sensor management)
  Future<void> addSensor(dynamic sensor) async {
    print('✅ Added sensor: $sensor');
    _safeNotify();
  }

  /// Update user sensor
  Future<void> updateSensor(dynamic sensor) async {
    print('✏️ Updated sensor: $sensor');
    _safeNotify();
  }

  /// Delete user sensor
  Future<void> deleteSensor(String sensorId) async {
    print('🗑️ Deleted sensor: $sensorId');
    _safeNotify();
  }

  /// Set current user for multi-user support
  Future<void> setCurrentUser(String userId) async {
    print('👤 SensorProvider: Set current user: $userId');
  }

  /// Clear user data on logout
  void clearUserData() {
    _currentData = SensorData.empty();
    _history.clear();
    print('🗑️ SensorProvider: Cleared user data');
    _safeNotify();
  }

  /// Handle MQTT message (callback for MQTT provider)
  void handleMqttMessage(String topic, String message) {
    print('📨 SensorProvider: MQTT message - $topic: $message');
    // Can be used to update sensors from MQTT messages
  }

  void _safeNotify() {
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      notifyListeners();
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }
}
