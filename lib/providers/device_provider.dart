import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/device_model.dart';
import 'mqtt_provider.dart';

class DeviceProvider extends ChangeNotifier {
  List<Device> _devices = [];
  MqttProvider? _mqttProvider;
  String? _currentUserId; // Add currentUserId

  List<Device> get devices => _devices;
  List<Device> get relays =>
      _devices.where((d) => d.type == DeviceType.relay).toList();
  List<Device> get servos =>
      _devices.where((d) => d.type == DeviceType.servo).toList();
  int get devicesCount => _devices.length;
  String? get currentUserId => _currentUserId; // Add getter
  List<String> get availableRooms {
    final rooms = _devices
        .where((d) => d.room != null && d.room!.isNotEmpty)
        .map((d) => d.room!)
        .toSet()
        .toList();
    rooms.sort();
    return rooms;
  }

  int get connectedDevicesCount {
    // Count devices that are currently ON (connected/active)
    return _devices.where((d) => d.state).length;
  }

  DeviceProvider() {
    _initializeDevices();
  }

  void setMqttProvider(MqttProvider mqttProvider) {
    _mqttProvider = mqttProvider;
  }

  void setCurrentUserId(String userId) {
    _currentUserId = userId;
  }

  /// Set current user for multi-user support
  Future<void> setCurrentUser(String userId) async {
    setCurrentUserId(userId);
    print('👤 DeviceProvider: Set current user: $userId');
  }

  /// Clear user data on logout
  Future<void> clearUserData() async {
    _devices.clear();
    _currentUserId = null;
    print('🗑️ DeviceProvider: Cleared user data');
    _safeNotify();
  }

  void _initializeDevices() {
    // Khởi tạo các thiết bị mặc định
    _devices = [
      Device(id: 'pump', name: 'Máy bơm', type: DeviceType.relay, icon: '💧'),
      Device(
        id: 'light_living',
        name: 'Đèn phòng khách',
        type: DeviceType.relay,
        icon: '💡',
      ),
      Device(
        id: 'light_yard',
        name: 'Đèn sân',
        type: DeviceType.relay,
        icon: '🔆',
      ),
      Device(
        id: 'ionizer',
        name: 'Máy phát ion',
        type: DeviceType.relay,
        icon: '🌬️',
      ),
      Device(
        id: 'roof_servo',
        name: 'Servo mái',
        type: DeviceType.servo,
        value: 0,
        icon: '🏠',
      ),
      Device(
        id: 'gate_servo',
        name: 'Servo cổng',
        type: DeviceType.servo,
        value: 0,
        icon: '🚪',
      ),
    ];
    print('🔌 Initialized ${_devices.length} devices');
  }

  Device? getDeviceById(String id) {
    try {
      return _devices.firstWhere((d) => d.id == id);
    } catch (e) {
      return null;
    }
  }

  void updateDeviceState(String id, bool state) {
    final index = _devices.indexWhere((d) => d.id == id);
    if (index != -1) {
      _devices[index] = _devices[index].copyWith(state: state);

      // Gửi lệnh qua MQTT
      if (_mqttProvider != null) {
        String topic = 'smarthome/control/$id';
        String message = state ? '1' : '0';
        _mqttProvider!.publish(topic, message);
        print('📡 MQTT: $topic -> $message');
      }

      _safeNotify();
      print('🔄 Device ${_devices[index].name}: ${state ? "ON" : "OFF"}');
    }
  }

  void updateServoValue(String id, int value) {
    final index = _devices.indexWhere((d) => d.id == id);
    if (index != -1 && _devices[index].type == DeviceType.servo) {
      _devices[index] = _devices[index].copyWith(value: value);

      // Gửi lệnh qua MQTT
      if (_mqttProvider != null) {
        String topic = 'smarthome/control/$id';
        String message = value.toString();
        _mqttProvider!.publish(topic, message);
        print('📡 MQTT: $topic -> $message');
      }

      _safeNotify();
      print('🔄 Servo ${_devices[index].name}: $value°');
    }
  }

  void toggleDevice(String id) {
    final index = _devices.indexWhere((d) => d.id == id);
    if (index != -1) {
      final currentState = _devices[index].state;
      _devices[index] = _devices[index].copyWith(state: !currentState);
      _safeNotify();
      print(
        '🔄 Toggled ${_devices[index].name}: ${!currentState ? "ON" : "OFF"}',
      );
    }
  }

  void addDevice(Device device) {
    _devices.add(device);
    _safeNotify();
    print('✅ Added device: ${device.name}');
  }

  void removeDevice(String id) {
    final device = _devices.firstWhere((d) => d.id == id);
    _devices.removeWhere((d) => d.id == id);
    _safeNotify();
    print('🗑️ Removed device: ${device.name}');
  }

  void updateDevice(String id, Device updatedDevice) {
    final index = _devices.indexWhere((d) => d.id == id);
    if (index != -1) {
      _devices[index] = updatedDevice;
      _safeNotify();
      print('✏️ Updated device: ${updatedDevice.name}');
    }
  }

  void turnOffAllDevices() {
    for (int i = 0; i < _devices.length; i++) {
      if (_devices[i].type == DeviceType.relay) {
        _devices[i] = _devices[i].copyWith(state: false);
      }
    }
    _safeNotify();
    print('⏸️ All devices turned off');
  }

  void turnOnAllDevices() {
    for (int i = 0; i < _devices.length; i++) {
      if (_devices[i].type == DeviceType.relay) {
        _devices[i] = _devices[i].copyWith(state: true);
      }
    }
    _safeNotify();
    print('✅ All devices turned on');
  }

  List<Device> getActiveDevices() {
    return _devices.where((d) => d.state).toList();
  }

  int getActiveDevicesCount() {
    return _devices.where((d) => d.state).length;
  }

  // Helper getters for specific devices
  bool get pumpState => getDeviceById('pump')?.state ?? false;
  bool get lightLivingState => getDeviceById('light_living')?.state ?? false;
  bool get lightYardState => getDeviceById('light_yard')?.state ?? false;
  bool get ionizerState => getDeviceById('ionizer')?.state ?? false;
  int get roofServoValue => getDeviceById('roof_servo')?.value ?? 0;
  int get gateServoValue => getDeviceById('gate_servo')?.value ?? 0;

  // Helper methods for specific devices
  void togglePump(bool value) => updateDeviceState('pump', value);
  void toggleLightLiving(bool value) =>
      updateDeviceState('light_living', value);
  void toggleLightYard(bool value) => updateDeviceState('light_yard', value);
  void toggleIonizer(bool value) => updateDeviceState('ionizer', value);
  void setRoofServo(int value) => updateServoValue('roof_servo', value);
  void setGateServo(int value) => updateServoValue('gate_servo', value);

  // 🔄 Room management methods
  Future<void> updateRoom(String roomName, String newRoomName) async {
    for (int i = 0; i < _devices.length; i++) {
      if (_devices[i].room == roomName) {
        _devices[i] = _devices[i].copyWith(room: newRoomName);
      }
    }
    _safeNotify();
    print('✏️ Updated room: $roomName -> $newRoomName');
  }

  Future<void> addEmptyRoom(String roomName, String avatar) async {
    // Mark room as "created" by storing it (can be enhanced with actual room model)
    print('✨ Added empty room: $roomName with avatar $avatar');
    _safeNotify();
  }

  Future<void> moveDeviceToRoom(String deviceId, String roomName) async {
    final index = _devices.indexWhere((d) => d.id == deviceId);
    if (index != -1) {
      _devices[index] = _devices[index].copyWith(room: roomName);
      _safeNotify();
      print('🚚 Moved device to room: $roomName');
    }
  }

  Future<void> deleteRoom(String roomName) async {
    // Remove all devices from this room or delete the room
    for (int i = 0; i < _devices.length; i++) {
      if (_devices[i].room == roomName) {
        _devices[i] = _devices[i].copyWith(room: null);
      }
    }
    _safeNotify();
    print('🗑️ Deleted room: $roomName');
  }

  // Fan preset control
  void setFanPreset(String deviceId, String preset) {
    final index = _devices.indexWhere((d) => d.id == deviceId);
    if (index != -1) {
      int value = 0;
      switch (preset.toLowerCase()) {
        case 'low':
          value = 85;
          break;
        case 'medium':
          value = 170;
          break;
        case 'high':
          value = 255;
          break;
      }
      _devices[index] = _devices[index].copyWith(value: value);
      _safeNotify();
      print('🌀 Fan preset: $preset ($value)');
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
}
