import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../services/mqtt_service.dart';
import '../services/mqtt_config_service.dart';
import '../services/local_storage_service.dart';
import '../models/mqtt_config.dart';

class MqttProvider extends ChangeNotifier {
  final MqttService _mqttService;
  late final MqttConfigService _configService;

  bool _isConnected = false;
  String _connectionStatus = 'Disconnected';
  String? _currentUserId;
  MqttConfig? _currentConfig;
  Function(String topic, String message)? _messageHandler;

  bool get isConnected => _isConnected;
  String get connectionStatus => _connectionStatus;
  MqttConfig? get currentConfig => _currentConfig;
  MqttService get mqttService =>
      _mqttService; // Expose MQTT service để sensors có thể ping

  MqttProvider(this._mqttService) {
    _configService = MqttConfigService(LocalStorageService());
    _mqttService.onConnected = _onConnected;
    _mqttService.onDisconnected = _onDisconnected;
    _mqttService.onMessageReceived = _onMessageReceived;
  }

  /// Set message handler for MQTT messages
  void setMessageHandler(Function(String topic, String message)? handler) {
    _messageHandler = handler;
  }

  /// Handle incoming MQTT messages
  void _onMessageReceived(String topic, String message) {
    if (_messageHandler != null) {
      _messageHandler!(topic, message);
    }
  }

  /// Set current user and load their MQTT config
  Future<void> setCurrentUser(String? userId) async {
    if (_currentUserId == userId) return;

    _currentUserId = userId;

    if (userId != null) {
      await _loadUserMqttConfig(userId);
    } else {
      _currentConfig = null;
    }
  }

  /// Load MQTT config for current user
  Future<void> _loadUserMqttConfig(String userId) async {
    try {
      _currentConfig = await _configService.loadUserMqttConfig(userId);
      print('📡 Loaded MQTT config for user: $userId');
      print('📡 Config: ${_currentConfig.toString()}');
    } catch (e) {
      print('❌ Error loading MQTT config: $e');
    }
  }

  /// Reconnect with user's custom config
  Future<void> reconnectWithUserConfig() async {
    if (_currentUserId != null) {
      // Disconnect first
      disconnect();

      // Reload config
      await _loadUserMqttConfig(_currentUserId!);

      // Reconnect with new config
      await connect();
    }
  }

  Future<void> connect() async {
    // Tránh connect nhiều lần cùng lúc
    if (_connectionStatus == 'Connecting...') {
      print('⚠️ MQTT: Already connecting, skipping...');
      return;
    }

    _connectionStatus = 'Connecting...';
    _safeNotify();

    // Use custom config if available
    if (_currentConfig == null) {
      _connectionStatus = 'No MQTT config available';
      _isConnected = false;
      _safeNotify();
      return;
    }

    final success = await _mqttService.connect(_currentConfig!);

    if (!success) {
      _connectionStatus = 'Connection Failed';
      _isConnected = false;
      _safeNotify();
    }
  }

  void publish(String topic, String message, {bool retain = false}) {
    _mqttService.publish(topic, message, retain: retain);
  }

  void _onConnected() {
    _isConnected = true;
    _connectionStatus = 'Connected';
    _safeNotify();
  }

  void _onDisconnected() {
    _isConnected = false;
    _connectionStatus = 'Disconnected';
    _safeNotify();
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

  void disconnect() {
    _mqttService.disconnect();
  }
}
