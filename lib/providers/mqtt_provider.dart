import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../services/mqtt_service.dart';

class MqttProvider extends ChangeNotifier {
  final MqttService _mqttService;

  bool _isConnected = false;
  String _connectionStatus = 'Disconnected';

  bool get isConnected => _isConnected;
  String get connectionStatus => _connectionStatus;

  MqttProvider(this._mqttService) {
    _mqttService.onConnected = _onConnected;
    _mqttService.onDisconnected = _onDisconnected;
  }

  Future<void> connect() async {
    _connectionStatus = 'Connecting...';
    _safeNotify();

    final success = await _mqttService.connect();

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

  /// Set message handler callback
  void setMessageHandler(Function(String topic, String message)? handler) {
    if (handler != null) {
      _mqttService.onMessageReceived = handler;
      print('🔗 MQTT: Message handler registered');
    }
  }

  /// Set current user for multi-user support
  Future<void> setCurrentUser(String userId) async {
    print('👤 MqttProvider: Set current user: $userId');
  }
}
