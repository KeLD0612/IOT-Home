import 'sensor_type.dart';
import 'device_mqtt_config.dart';
import 'sensor_health.dart';

class UserSensor {
  final String id;
  final String userId;
  final String sensorTypeId;
  final String displayName;
  final String mqttTopic;
  final String deviceCode; // 🔑 MÃ CẢM BIẾN (6 KÝ TỰ)
  final bool isActive;
  final Map<String, dynamic>? configuration;
  final DisplayConfig? displayConfig; // 🆕 Cấu hình hiển thị
  final String? customIcon; // 🆕 Icon tùy chỉnh
  final String? avatarPath; // 🎨 THÊM FIELD ẢNH AVATAR
  final DeviceMqttConfig? mqttConfig; // 📡 MQTT Configuration
  final DateTime createdAt;
  final DateTime? lastUpdateAt;
  final dynamic lastValue;

  const UserSensor({
    required this.id,
    required this.userId,
    required this.sensorTypeId,
    required this.displayName,
    required this.mqttTopic,
    required this.deviceCode, // 🔑 THÊM PARAMETER BẮT BUỘC
    this.isActive = true,
    this.configuration,
    this.displayConfig,
    this.customIcon,
    this.avatarPath, // 🎨 THÊM PARAMETER
    this.mqttConfig, // 📡 MQTT Configuration
    required this.createdAt,
    this.lastUpdateAt,
    this.lastValue,
  });

  /// Lấy thông tin SensorType
  SensorType? get sensorType => AvailableSensorTypes.getById(sensorTypeId);

  /// Lấy icon (ưu tiên custom icon)
  String get icon => customIcon ?? sensorType?.icon ?? '📊';

  /// Lấy unit (ưu tiên từ displayConfig)
  String get unit => displayConfig?.unit ?? sensorType?.unit ?? '';

  /// Lấy formatted value theo displayConfig
  String get formattedValue {
    if (lastValue == null) return '--';

    // Nếu có displayConfig, sử dụng nó
    if (displayConfig != null) {
      return _formatWithDisplayConfig(lastValue);
    }

    // Fallback về format mặc định
    final type = sensorType;
    if (type == null) return lastValue.toString();

    switch (type.dataType) {
      case SensorDataType.double:
        final value = (lastValue as num).toDouble();
        return '${value.toStringAsFixed(1)}${unit}';
      case SensorDataType.int:
        return '${lastValue}${unit}';
      case SensorDataType.bool:
        return lastValue == true ? 'Có' : 'Không';
    }
  }

  /// Format value theo DisplayConfig
  String _formatWithDisplayConfig(dynamic value) {
    if (displayConfig == null) return value.toString();

    switch (displayConfig!.type) {
      case DisplayType.boolean:
        final boolValue = value == true || value == 1 || value == '1';
        return boolValue
            ? (displayConfig!.trueLabel ?? 'Có')
            : (displayConfig!.falseLabel ?? 'Không');

      case DisplayType.pulse:
        return '${value}${unit}';

      case DisplayType.percentage:
        if (displayConfig!.maxValue != null && displayConfig!.maxValue! > 0) {
          final numValue = (value as num).toDouble();
          final percentage = (numValue / displayConfig!.maxValue! * 100).clamp(
            0,
            100,
          );
          return '${percentage.toStringAsFixed(1)}%';
        }
        return '${value}${unit}';
    }
  }

  /// Kiểm tra có phải weather sensor không
  bool get isWeatherSensor =>
      AvailableSensorTypes.isWeatherSensor(sensorTypeId);

  /// 🩺 Lấy thông tin sức khỏe của sensor dựa trên giá trị hiện tại
  HealthInfo get healthInfo {
    return SensorHealthCalculator.calculateHealth(
      sensorTypeId: sensorTypeId,
      value: lastValue,
      sensorType: sensorType,
    );
  }

  // 📡 MQTT Helper Getters
  bool get hasCustomMqttConfig => mqttConfig?.useCustomConfig == true;
  String get mqttBroker => mqttConfig?.broker ?? 'default';
  int get mqttPort => mqttConfig?.port ?? 8883;
  String? get mqttUsername => mqttConfig?.username;
  String? get mqttPassword => mqttConfig?.password;
  bool get mqttUseSsl => mqttConfig?.useSsl ?? true;
  String get finalMqttTopic => mqttConfig?.customTopic ?? mqttTopic;
  String get mqttClientId =>
      mqttConfig?.generateClientId() ??
      'sensor_${id}_${DateTime.now().millisecondsSinceEpoch}';

  UserSensor copyWith({
    String? id,
    String? userId,
    String? sensorTypeId,
    String? displayName,
    String? mqttTopic,
    String? deviceCode, // 🔑 THÊM VÀO copyWith
    bool? isActive,
    Map<String, dynamic>? configuration,
    DisplayConfig? displayConfig,
    String? customIcon,
    String? avatarPath, // 🎨 THÊM VÀO copyWith
    DeviceMqttConfig? mqttConfig,
    DateTime? createdAt,
    DateTime? lastUpdateAt,
    dynamic lastValue,
  }) {
    return UserSensor(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sensorTypeId: sensorTypeId ?? this.sensorTypeId,
      displayName: displayName ?? this.displayName,
      mqttTopic: mqttTopic ?? this.mqttTopic,
      deviceCode: deviceCode ?? this.deviceCode, // 🔑 THÊM VÀO copyWith
      isActive: isActive ?? this.isActive,
      configuration: configuration ?? this.configuration,
      displayConfig: displayConfig ?? this.displayConfig,
      customIcon: customIcon ?? this.customIcon,
      avatarPath: avatarPath ?? this.avatarPath, // 🎨 THÊM VÀO copyWith
      mqttConfig: mqttConfig ?? this.mqttConfig,
      createdAt: createdAt ?? this.createdAt,
      lastUpdateAt: lastUpdateAt ?? this.lastUpdateAt,
      lastValue: lastValue ?? this.lastValue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'sensorTypeId': sensorTypeId,
      'displayName': displayName,
      'mqttTopic': mqttTopic,
      'deviceCode': deviceCode, // 🔑 THÊM VÀO toJson
      'isActive': isActive,
      'configuration': configuration,
      'displayConfig': displayConfig?.toJson(),
      'customIcon': customIcon,
      'avatarPath': avatarPath, // 🎨 THÊM VÀO toJson
      'mqttConfig': mqttConfig?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'lastUpdateAt': lastUpdateAt?.toIso8601String(),
      'lastValue': lastValue,
    };
  }

  factory UserSensor.fromJson(Map<String, dynamic> json) {
    return UserSensor(
      id: json['id'],
      userId: json['userId'],
      sensorTypeId: json['sensorTypeId'],
      displayName: json['displayName'],
      mqttTopic: json['mqttTopic'],
      deviceCode: json['deviceCode'] ?? '', // 🔑 THÊM VÀO fromJson VỚI FALLBACK
      isActive: json['isActive'] ?? true,
      configuration: json['configuration'],
      displayConfig: json['displayConfig'] != null
          ? DisplayConfig.fromJson(json['displayConfig'])
          : null,
      customIcon: json['customIcon'],
      avatarPath: json['avatarPath'], // 🎨 THÊM VÀO fromJson
      mqttConfig: json['mqttConfig'] != null
          ? DeviceMqttConfig.fromJson(json['mqttConfig'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      lastUpdateAt: json['lastUpdateAt'] != null
          ? DateTime.parse(json['lastUpdateAt'])
          : null,
      lastValue: json['lastValue'],
    );
  }

  /// Tạo UserSensor từ SensorType với custom config
  factory UserSensor.fromSensorType({
    required String userId,
    required SensorType sensorType,
    required String displayName,
    String? customMqttTopic,
    Map<String, dynamic>? configuration,
    DisplayConfig? displayConfig,
    String? customIcon,
    DeviceMqttConfig? mqttConfig,
  }) {
    final now = DateTime.now();
    final sensorId = '${sensorType.id}_${userId}_${now.millisecondsSinceEpoch}';

    // Parse DisplayConfig và customIcon từ configuration nếu có
    DisplayConfig? finalDisplayConfig = displayConfig;
    String? finalCustomIcon = customIcon;

    if (configuration != null) {
      if (configuration['displayConfig'] != null) {
        try {
          finalDisplayConfig = DisplayConfig.fromJson(
            configuration['displayConfig'] as Map<String, dynamic>,
          );
        } catch (e) {
          print('Error parsing displayConfig: $e');
        }
      }
      if (configuration['customIcon'] != null) {
        finalCustomIcon = configuration['customIcon'] as String;
      }
    }

    return UserSensor(
      id: sensorId,
      userId: userId,
      sensorTypeId: sensorType.id,
      displayName: displayName,
      mqttTopic: customMqttTopic ?? '${sensorType.defaultMqttTopic}/$sensorId',
      deviceCode: 'SENSOR', // Default device code for sensors
      isActive: true,
      configuration: configuration,
      displayConfig: finalDisplayConfig,
      customIcon: finalCustomIcon,
      mqttConfig: mqttConfig,
      createdAt: now,
    );
  }

  /// Tạo default sensors cho user mới
  static List<UserSensor> createDefaultSensors(String userId) {
    return [
      UserSensor.fromSensorType(
        userId: userId,
        sensorType: AvailableSensorTypes.getById('temperature')!,
        displayName: 'Nhiệt độ phòng khách',
      ),
      UserSensor.fromSensorType(
        userId: userId,
        sensorType: AvailableSensorTypes.getById('humidity')!,
        displayName: 'Độ ẩm phòng khách',
      ),
      UserSensor.fromSensorType(
        userId: userId,
        sensorType: AvailableSensorTypes.getById('rain')!,
        displayName: 'Cảm biến mưa',
      ),
    ];
  }
}
