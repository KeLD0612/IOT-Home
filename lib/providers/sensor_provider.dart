import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:async';
import 'dart:convert';
import '../models/sensor_data.dart';
import '../models/user_sensor.dart';
import '../models/sensor_type.dart';
import '../models/device_mqtt_config.dart';
import '../services/local_storage_service.dart';
import '../services/firestore_sensor_service.dart';
import '../services/notification_service.dart';
import '../services/sensor_mqtt_service.dart'; // Service riêng cho sensor ping
import '../config/constants.dart';

class SensorProvider extends ChangeNotifier {
  final LocalStorageService _storageService; // Giữ lại cho history (in-memory)
  final NotificationService _notificationService;
  final FirestoreSensorService _firestoreService = FirestoreSensorService();
  final SensorMqttService _sensorMqttService =
      SensorMqttService(); // Service riêng cho sensor, TỰ ĐỘNG CONNECT

  SensorData _currentData = SensorData.empty();
  List<SensorData> _history = [];
  List<UserSensor> _userSensors = [];
  bool _gasAlertShown = false;
  bool _rainAlertShown = false;
  bool _soilAlertShown = false;
  bool _dustAlertShown = false;
  String? _currentUserId; // User isolation

  // 🔴 Real-time listener subscription
  StreamSubscription<List<UserSensor>>? _sensorsSubscription;

  SensorData get currentData => _currentData;
  List<SensorData> get history => _history;
  List<UserSensor> get userSensors => _userSensors;

  // Individual sensor getters for backward compatibility
  double get temperature => _currentData.temperature;
  double get humidity => _currentData.humidity;
  int get rain => _currentData.rain;
  int get light => _currentData.light;
  int get soilMoisture => _currentData.soilMoisture;
  int get gas => _currentData.gas;
  int get dust => _currentData.dust;
  bool get motionDetected => _currentData.motionDetected;

  SensorProvider(this._storageService, this._notificationService) {
    // Không load history ngay, chờ setCurrentUser
  }

  /// Set current user và load sensor history và user sensors của user đó
  Future<void> setCurrentUser(String? userId) async {
    if (_currentUserId == userId) return;

    // 🛑 HỦY LISTENER CŨ
    _sensorsSubscription?.cancel();
    _sensorsSubscription = null;

    _currentUserId = userId;

    if (userId != null) {
      await _setupRealtimeListener(userId);
      _loadHistory();
    } else {
      _history = [];
      _userSensors = [];
      _safeNotify();
    }
  }

  /// Setup real-time listener để tự động sync sensors từ Firestore
  Future<void> _setupRealtimeListener(String userId) async {
    try {
      debugPrint('👂 Setting up real-time listener for sensors...');

      // 🔴 LẮng nghe real-time changes từ Firestore
      _sensorsSubscription = _firestoreService
          .watchUserSensors(userId)
          .listen(
            (sensors) {
              print(
                '╔═══════════════════════════════════════════════════════╗',
              );
              print(
                '║  📡 FIRESTORE REAL-TIME UPDATE RECEIVED!              ║',
              );
              print(
                '╚═══════════════════════════════════════════════════════╝',
              );
              print('👤 UserId: $userId');
              print('📊 Total sensors: ${sensors.length}');
              print('───────────────────────────────────────────────────────');

              _userSensors = sensors;

              // 🔴 SUBSCRIBE TO ALL SENSOR STATE TOPICS (để nhận data từ Arduino)
              _subscribeToSensorTopics();

              // Debug: List loaded sensors với giá trị hiện tại
              for (final sensor in _userSensors) {
                print('🔹 ${sensor.displayName}');
                print('   Code: ${sensor.deviceCode}');
                print('   Type: ${sensor.sensorTypeId}');
                print('   Topic: ${sensor.mqttTopic}');
                print(
                  '   Value: ${sensor.lastValue ?? 'null'} → Formatted: ${sensor.formattedValue}',
                );
                print('   Active: ${sensor.isActive}');
              }
              print('───────────────────────────────────────────────────────');

              print('🔔 [SENSOR] Calling notifyListeners() to update UI...');
              _safeNotify();
              print('✅ [SENSOR] UI should update now!\n');
            },
            onError: (error) {
              debugPrint('❌ Error in real-time sensor listener: $error');
            },
          );

      debugPrint('✅ Real-time sensor listener setup complete');
    } catch (e) {
      debugPrint('❌ Error setting up real-time sensor listener: $e');
    }
  }

  /// Subscribe to all active sensor state topics để nhận data
  void _subscribeToSensorTopics() {
    if (_userSensors.isEmpty) {
      print('📭 No sensors to subscribe');
      return;
    }

    print('╔═══════════════════════════════════════════════════════╗');
    print('║  📡 SUBSCRIBING TO SENSOR DATA TOPICS...              ║');
    print('╚═══════════════════════════════════════════════════════╝');

    for (final sensor in _userSensors) {
      if (!sensor.isActive) continue;

      // Subscribe đến state topic để nhận data từ Arduino
      final stateTopic = sensor.mqttTopic; // smart_home/sensors/DHT22_001/state

      print('🔔 Subscribing to: $stateTopic');
      print('   Sensor: ${sensor.displayName} (${sensor.deviceCode})');

      // Dùng SensorMqttService để subscribe (mỗi sensor tự kết nối broker riêng)
      _sensorMqttService.subscribeToCustomTopic(sensor, stateTopic);

      // Setup callback để nhận message
      _sensorMqttService.setSensorCallback(
        sensor.id,
        onMessage: (message) {
          print('📨 [SENSOR DATA] ${sensor.displayName}: $message');
          // Forward to handleMqttMessage để parse
          handleMqttMessage(stateTopic, message);
        },
      );
    }

    print(
      '✅ Subscribed to ${_userSensors.where((s) => s.isActive).length} sensor topics\n',
    );
  }

  /// Kiểm tra user có đủ sensors để hiển thị weather widget
  bool hasWeatherSensors() {
    if (_currentUserId == null) return false;

    final requiredTypes = ['temperature', 'humidity', 'rain'];
    for (final type in requiredTypes) {
      final hasSensor = _userSensors.any(
        (s) => s.sensorTypeId == type && s.isActive,
      );
      if (!hasSensor) return false;
    }
    return true;
  }

  /// Lấy sensor theo type (sensor đầu tiên)
  UserSensor? getSensorByType(String sensorTypeId) {
    try {
      return _userSensors.firstWhere(
        (s) => s.sensorTypeId == sensorTypeId && s.isActive,
      );
    } catch (e) {
      return null;
    }
  }

  /// Xử lý MQTT message đến từ topic động
  Future<void> handleMqttMessage(String topic, String message) async {
    print('═══════════════════════════════════════════════════════');
    print('🔔 [SENSOR] NEW MQTT MESSAGE RECEIVED!');
    print('📨 Topic:   $topic');
    print('📦 Message: $message');
    print('👤 UserId:  $_currentUserId');
    print('📊 Total sensors loaded: ${_userSensors.length}');
    print('═══════════════════════════════════════════════════════');

    if (_currentUserId == null) {
      print('❌ [SENSOR] UserId is NULL! Cannot process message.');
      return;
    }

    try {
      // Tìm sensor theo device code (extract từ topic)
      // Topic format: smart_home/sensors/{DEVICE_CODE}/state
      UserSensor? sensor;

      // Thử tìm theo exact topic trước (backward compatibility)
      try {
        sensor = _userSensors.firstWhere(
          (s) => s.mqttTopic == topic && s.isActive,
        );
        print('✅ Found sensor by exact topic: ${sensor.displayName}');
      } catch (_) {
        // Nếu không tìm thấy, thử extract device code và tìm theo đó
        // Topic có thể là: smart_home/sensors/DHT22_001/state
        // MQTT topic lưu là: smart_home/sensors/DHT22_001/state
        final topicParts = topic.split('/');
        if (topicParts.length >= 4 &&
            topicParts[0] == 'smart_home' &&
            (topicParts[1] == 'sensors' || topicParts[1] == 'devices')) {
          final deviceCode = topicParts[2]; // DHT22_001

          print('🔍 [SENSOR] Searching sensor by device code: $deviceCode');
          print('📋 [SENSOR] Available sensors:');
          for (var s in _userSensors) {
            print(
              '   - ${s.displayName}: code="${s.deviceCode}", active=${s.isActive}, type=${s.sensorTypeId}',
            );
          }

          // Tìm sensor có deviceCode khớp
          try {
            sensor = _userSensors.firstWhere(
              (s) => s.deviceCode == deviceCode && s.isActive,
            );
            print('✅ [SENSOR] FOUND! Sensor: ${sensor.displayName}');
            print('   → Device code: ${sensor.deviceCode}');
            print('   → Type: ${sensor.sensorTypeId}');
            print('   → MQTT Topic: ${sensor.mqttTopic}');
          } catch (_) {
            print('❌ [SENSOR] NO SENSOR FOUND with device code: $deviceCode');
            print('💡 [SENSOR] Make sure sensor exists with exact deviceCode!');
            throw StateError('No sensor found for topic: $topic');
          }
        } else {
          print('❌ Invalid topic format: $topic');
          throw StateError('Invalid topic format');
        }
      }

      // Parse value - hỗ trợ cả JSON và plain text
      dynamic value;

      print('🔧 [SENSOR] Parsing message...');

      // 🛡️ Strip any "Message: " prefix (from HiveMQ Web Client formatting)
      if (message.startsWith('Message: ')) {
        message = message.substring('Message: '.length);
        print('🔧 [SENSOR] Stripped "Message: " prefix, cleaned: $message');
      }

      print(
        '   Message type: ${message.trim().startsWith('{') ? 'JSON' : 'Plain text'}',
      );

      // Kiểm tra nếu message là JSON
      if (message.trim().startsWith('{')) {
        print('📝 [SENSOR] Parsing as JSON...');
        try {
          final Map<String, dynamic> json = jsonDecode(message);
          print('✅ [SENSOR] JSON parsed successfully: $json');

          // Lấy value từ JSON (Arduino gửi {"type":"soil_moisture","value":0,...})
          if (json.containsKey('value')) {
            value = json['value'];
            print(
              '📊 [SENSOR] Extracted value from JSON: $value (${value.runtimeType})',
            );
          } else {
            print('❌ [SENSOR] JSON missing "value" key! Keys: ${json.keys}');
            throw Exception('JSON không chứa key "value"');
          }
        } catch (jsonError) {
          print('❌ [SENSOR] JSON parse error: $jsonError');
          throw jsonError;
        }
      } else {
        // Plain text message
        switch (sensor.sensorType!.dataType) {
          case SensorDataType.double:
            value = double.parse(message);
            break;
          case SensorDataType.int:
            value = int.parse(message);
            break;
          case SensorDataType.bool:
            value = message == '1' || message.toLowerCase() == 'true';
            break;
        }
        print('📊 Parsed plain text value: $value');
      }

      // Chuyển đổi kiểu dữ liệu nếu cần
      print('🔄 [SENSOR] Converting to ${sensor.sensorType!.dataType}...');
      switch (sensor.sensorType!.dataType) {
        case SensorDataType.double:
          value = (value as num).toDouble();
          break;
        case SensorDataType.int:
          value = (value as num).toInt();
          break;
        case SensorDataType.bool:
          value = value == true || value == 1 || value == '1';
          break;
      }

      print('✅ [SENSOR] Final converted value: $value (${value.runtimeType})');
      print('───────────────────────────────────────────────────────');

      // 🔥 CẬP NHẬT SENSOR VALUE VÀO FIRESTORE
      print('💾 [SENSOR] Updating Firestore...');
      print('   UserId: $_currentUserId');
      print('   SensorId: ${sensor.id}');
      print('   New value: $value');

      await _firestoreService.updateSensorValue(
        _currentUserId!,
        sensor.id,
        value,
      );

      print('✅ [SENSOR] Firestore updated successfully!');

      // Real-time listener sẽ tự động update _userSensors
      // Nhưng để đảm bảo UI update ngay, ta cập nhật currentData
      print('🔄 [SENSOR] Updating currentData from sensors...');
      _updateCurrentDataFromSensors();

      print('═══════════════════════════════════════════════════════');
      print(
        '🎉 [SENSOR] SUCCESS! Updated sensor: ${sensor.displayName} = $value',
      );
      print(
        '⏰ [SENSOR] Waiting for Firestore listener to trigger UI update...',
      );
      print('═══════════════════════════════════════════════════════\n');
    } catch (e, stackTrace) {
      print('═══════════════════════════════════════════════════════');
      print('❌ [SENSOR] ERROR in handleMqttMessage!');
      print('📨 Topic:   $topic');
      print('📦 Message: $message');
      print('⚠️  Error:   $e');
      print('📚 Stack trace:');
      print(stackTrace);
      print('═══════════════════════════════════════════════════════\n');
    }
  }

  /// Cập nhật currentData từ user sensors (backward compatibility)
  void _updateCurrentDataFromSensors() {
    double temperature = 0.0;
    double humidity = 0.0;
    int rain = 0;
    int light = 0;
    int soilMoisture = 0;
    int gas = 0;
    int dust = 0;
    bool motionDetected = false;

    for (final sensor in _userSensors.where(
      (s) => s.isActive && s.lastValue != null,
    )) {
      switch (sensor.sensorTypeId) {
        case 'temperature':
          temperature = (sensor.lastValue as num).toDouble();
          break;
        case 'humidity':
          humidity = (sensor.lastValue as num).toDouble();
          break;
        case 'rain':
          rain = sensor.lastValue as int;
          break;
        case 'light':
          light = sensor.lastValue as int;
          break;
        case 'soil_moisture':
          soilMoisture = sensor.lastValue as int;
          break;
        case 'gas':
          gas = sensor.lastValue as int;
          break;
        case 'dust':
          dust = sensor.lastValue as int;
          break;
        case 'motion':
          motionDetected = sensor.lastValue as bool;
          break;
      }
    }

    _currentData = SensorData(
      temperature: temperature,
      humidity: humidity,
      rain: rain,
      light: light,
      soilMoisture: soilMoisture,
      gas: gas,
      dust: dust,
      motionDetected: motionDetected,
      timestamp: DateTime.now(),
    );

    _addToHistory(_currentData);
    _checkAlerts(_currentData);
    _safeNotify();
  }

  /// Clear user data when logout
  void clearUserData() {
    _sensorsSubscription?.cancel();
    _sensorsSubscription = null;

    _currentUserId = null;
    _history = [];
    _userSensors = [];
    _currentData = SensorData.empty();
    _gasAlertShown = false;
    _rainAlertShown = false;
    _soilAlertShown = false;
    _dustAlertShown = false;
    _safeNotify();
    print('🧹 SensorProvider: Cleared user data');
  }

  /// Cập nhật sensor
  Future<void> updateSensor(UserSensor sensor) async {
    if (_currentUserId == null) return;

    // 🔥 UPDATE VÀO FIRESTORE → Real-time listener sẽ tự động update _userSensors
    await _firestoreService.updateSensor(_currentUserId!, sensor);
  }

  /// Xóa sensor
  Future<void> deleteSensor(String sensorId) async {
    if (_currentUserId == null) return;

    // 🔥 XÓA KHỎI FIRESTORE → Real-time listener sẽ tự động update _userSensors
    await _firestoreService.deleteSensor(_currentUserId!, sensorId);
  }

  /// Tạo default sensors cho user mới (DEPRECATED - không cần nữa)
  @Deprecated('Create sensors manually via addSensor')
  Future<void> createDefaultSensors() async {
    // Không cần tạo default sensors nữa
    // User sẽ tự tạo sensors qua UI
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
    if (_currentUserId == null) {
      _history = [];
      return;
    }

    final stored = _storageService.getSensorHistory(
      'all',
      userId: _currentUserId,
    );
    _history = stored.map((json) => SensorData.fromJson(json)).toList();
    print(
      '📊 Loaded ${_history.length} sensor history records for user: $_currentUserId',
    );
  }

  void _saveHistory() {
    if (_currentUserId == null) return;

    final jsonList = _history.map((data) => data.toJson()).toList();
    _storageService.saveSensorHistory('all', jsonList, userId: _currentUserId);
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

  /// Add new user sensor
  Future<void> addSensor({
    required String sensorTypeId,
    required String displayName,
    required String customMqttTopic,
    required String deviceCode,
    Map<String, dynamic>? configuration,
    DeviceMqttConfig? mqttConfig,
  }) async {
    if (_currentUserId == null) {
      throw Exception('No current user set');
    }

    final sensorId = 'sensor_${DateTime.now().millisecondsSinceEpoch}';

    final userSensor = UserSensor(
      id: sensorId,
      userId: _currentUserId!,
      sensorTypeId: sensorTypeId,
      displayName: displayName,
      mqttTopic: customMqttTopic,
      deviceCode: deviceCode,
      isActive: true,
      configuration: configuration,
      displayConfig: configuration?['displayConfig'] != null
          ? DisplayConfig.fromJson(configuration!['displayConfig'])
          : null,
      customIcon: configuration?['customIcon'],
      mqttConfig: mqttConfig,
      createdAt: DateTime.now(),
    );

    // 🔥 LƯU VÀO FIRESTORE → Real-time listener sẽ tự động update _userSensors
    await _firestoreService.addSensor(_currentUserId!, userSensor);

    print('✅ Added sensor: $displayName with device code: $deviceCode');
  }

  /// Debug method to check storage (DEPRECATED)
  @Deprecated('Use Firestore Console to check data')
  Future<void> debugCheckStorage() async {
    if (_currentUserId == null) {
      print('🐞 DEBUG: No current user set');
      return;
    }

    print('🐞 DEBUG: Checking Firestore for user: $_currentUserId');
    print('🐞 DEBUG: Current sensors in memory: ${_userSensors.length}');

    try {
      final storedSensors = await _firestoreService.loadUserSensors(
        _currentUserId!,
      );
      print('🐞 DEBUG: Stored sensors: ${storedSensors.length}');

      for (final sensor in storedSensors) {
        print(
          '🐞 DEBUG: Stored sensor: ${sensor.displayName} (${sensor.deviceCode})',
        );
      }
    } catch (e) {
      print('🐞 DEBUG: Error reading Firestore: $e');
    }
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

  // 🔍 CHECK SENSOR MQTT CONNECTION (tương tự devices)
  bool _isCheckingConnection = false;
  String? _connectionCheckSensorId;
  Timer? _connectionCheckTimer;

  bool get isCheckingConnection => _isCheckingConnection;
  String? get connectionCheckSensorId => _connectionCheckSensorId;

  Future<bool> checkSensorConnection(UserSensor sensor) async {
    // Ngăn gọi nhiều lần cùng lúc
    if (_isCheckingConnection) {
      print('⚠️ Sensor connection check already in progress');
      return false;
    }

    _isCheckingConnection = true;
    _connectionCheckSensorId = sensor.id;
    notifyListeners();

    final completer = Completer<bool>();

    try {
      // Topic ping cho SENSORS: smart_home/sensors/{CODE}/ping
      final pingTopic = 'smart_home/sensors/${sensor.deviceCode}/ping';
      final pingPayload = 'ping';

      print('🔍 Starting connection check for sensor: ${sensor.displayName}');
      print('🔍 Ping topic: $pingTopic');

      // Subscribe đến ping topic trước (dùng SensorMqttService)
      await _sensorMqttService.subscribeToCustomTopic(sensor, pingTopic);

      // Timeout sau 5 giây
      _connectionCheckTimer = Timer(const Duration(seconds: 5), () {
        if (!completer.isCompleted) {
          print(
            '⏱️ Connection check timeout for sensor: ${sensor.displayName}',
          );
          _isCheckingConnection = false;
          _connectionCheckSensorId = null;
          _sensorMqttService.removeSensorCallback(sensor.id);
          notifyListeners();
          completer.complete(false);
        }
      });

      // Lắng nghe MQTT messages - CHỈ GỌI 1 LẦN
      _sensorMqttService.setSensorCallback(
        sensor.id,
        onMessage: (message) {
          if (message == '1' && !completer.isCompleted) {
            print(
              '✅ MQTT connection check successful for sensor: ${sensor.displayName}',
            );
            _isCheckingConnection = false;
            _connectionCheckSensorId = null;
            _connectionCheckTimer?.cancel();
            _sensorMqttService.removeSensorCallback(sensor.id);
            notifyListeners();
            completer.complete(true);
          }
        },
      );

      // Gửi lệnh ping CHỈ 1 LẦN
      print('📤 Sending ping to: $pingTopic');
      await _sensorMqttService.publishToCustomTopic(
        sensor,
        pingTopic,
        pingPayload,
      );
      print('✅ Ping sent successfully');

      // Đợi kết quả (timeout hoặc nhận response)
      final result = await completer.future;
      return result;
    } catch (e) {
      print('❌ Error checking sensor connection: $e');
      _isCheckingConnection = false;
      _connectionCheckSensorId = null;
      _connectionCheckTimer?.cancel();
      _sensorMqttService.removeSensorCallback(sensor.id);
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _connectionCheckTimer?.cancel();
    _sensorsSubscription?.cancel(); // 🔴 Cancel real-time listener
    _sensorMqttService.dispose(); // Cleanup sensor MQTT connections
    super.dispose();
  }
}
