import '../models/device_mqtt_config.dart';

class Device {
  final String id;
  final String name;
  final DeviceType type;
  final String? keyName; // Unique key for identification
  final String? deviceCode; // Device code for MQTT/commands
  final String? avatarPath; // Custom image path
  final bool? isServo360; // For servo type: 360 degrees or 180 degrees
  bool state;
  int? value; // For servo angles (0-180)
  final String? icon;
  final String? room;
  final DeviceMqttConfig? mqttConfig; // MQTT configuration
  final DateTime? lastUpdated;

  Device({
    required this.id,
    required this.name,
    required this.type,
    this.keyName,
    this.deviceCode,
    this.avatarPath,
    this.isServo360,
    this.state = false,
    this.value,
    this.icon,
    this.room,
    this.mqttConfig,
    this.lastUpdated,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      name: json['name'],
      type: DeviceType.values.firstWhere(
        (e) => e.toString() == 'DeviceType.${json['type']}',
        orElse: () => DeviceType.relay,
      ),
      keyName: json['keyName'],
      deviceCode: json['deviceCode'],
      avatarPath: json['avatarPath'],
      isServo360: json['isServo360'],
      state: json['state'] ?? false,
      value: json['value'],
      icon: json['icon'],
      room: json['room'],
      mqttConfig: json['mqttConfig'] != null
          ? DeviceMqttConfig.fromJson(json['mqttConfig'])
          : null,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'keyName': keyName,
      'deviceCode': deviceCode,
      'avatarPath': avatarPath,
      'isServo360': isServo360,
      'state': state,
      'value': value,
      'icon': icon,
      'room': room,
      'mqttConfig': mqttConfig?.toJson(),
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  Device copyWith({
    String? id,
    String? name,
    DeviceType? type,
    String? keyName,
    String? deviceCode,
    String? avatarPath,
    bool? isServo360,
    bool? state,
    int? value,
    String? icon,
    String? room,
    DeviceMqttConfig? mqttConfig,
    DateTime? lastUpdated,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      keyName: keyName ?? this.keyName,
      deviceCode: deviceCode ?? this.deviceCode,
      avatarPath: avatarPath ?? this.avatarPath,
      isServo360: isServo360 ?? this.isServo360,
      state: state ?? this.state,
      value: value ?? this.value,
      icon: icon ?? this.icon,
      room: room ?? this.room,
      mqttConfig: mqttConfig ?? this.mqttConfig,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  bool get isRelay => type == DeviceType.relay;
  bool get isServo => type == DeviceType.servo;
  bool get isOn => state;
  bool get isOff => !state;
  bool get hasCustomMqttConfig => mqttConfig != null;
  String? get mqttTopic => mqttConfig?.customTopic;
  String? get mqttClientId => mqttConfig?.clientId;
  String? get finalMqttTopic => mqttConfig?.customTopic ?? 'smarthome/device/$deviceCode';
}

enum DeviceType { 
  relay, 
  servo 
}

extension DeviceTypeExtension on DeviceType {
  String get displayName {
    switch (this) {
      case DeviceType.relay:
        return 'Relay (Rơle)';
      case DeviceType.servo:
        return 'Servo (Động cơ)';
    }
  }

  String get shortName {
    switch (this) {
      case DeviceType.relay:
        return 'Relay';
      case DeviceType.servo:
        return 'Servo';
    }
  }
}
