import 'device_mqtt_config.dart';

class Device {
  final String id;
  final String name;
  final String keyName; // 🎯 TÊN CHUẨN HÓA CHO AI VOICE CONTROL
  final String deviceCode; // 🔑 MÃ THIẾT BỊ (6 KÝ TỰ)
  final DeviceType type;
  bool state;
  int? value; // For servo angles (0-180 or 0-360)
  final bool? isServo360; // For servo type: true = 360°, false = 180°
  final String? icon;
  final String? avatarPath; // 🎨 THÊM FIELD ẢNH AVATAR
  final String? room;
  final String? userId; // 👤 THÊM USER ID
  final DateTime? lastUpdated;
  final DateTime? createdAt; // 📅 THÊM THỜI GIAN TẠO
  bool isPinned; // 📌 THÊM FIELD GHIM CHO ĐIỀU KHIỂN NHANH

  // 📡 THÊM CẤU HÌNH MQTT RIÊNG CHO THIẾT BỊ
  final DeviceMqttConfig? mqttConfig;

  Device({
    required this.id,
    required this.name,
    required this.keyName, // 🎯 THÊM PARAMETER BẮT BUỘC
    required this.deviceCode, // 🔑 THÊM PARAMETER BẮT BUỘC
    required this.type,
    this.state = false,
    this.value,
    this.isServo360, // For servo type: true = 360°, false = 180°
    this.icon,
    this.avatarPath, // 🎨 THÊM PARAMETER
    this.room,
    this.userId, // 👤 THÊM PARAMETER
    this.lastUpdated,
    this.createdAt,
    this.isPinned = false, // 📌 THÊM PARAMETER VỚI DEFAULT FALSE
    this.mqttConfig, // 📡 THÊM PARAMETER MQTT CONFIG
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      name: json['name'],
      keyName:
          json['keyName'] ??
          normalizeDeviceName(
            json['name'],
          ), // 🎯 THÊM VÀO fromJson VỚI FALLBACK
      deviceCode: json['deviceCode'] ?? '', // 🔑 THÊM VÀO fromJson VỚI FALLBACK
      type: DeviceType.values.firstWhere(
        (e) => e.toString() == 'DeviceType.${json['type']}',
        orElse: () => DeviceType.relay,
      ),
      state: json['state'] ?? false,
      value: json['value'],
      isServo360:
          json['isServo360'], // For servo type: true = 360°, false = 180°
      icon: json['icon'],
      avatarPath: json['avatarPath'], // 🎨 THÊM VÀO fromJson
      room: json['room'],
      userId: json['userId'], // 👤 THÊM VÀO fromJson
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      isPinned: json['isPinned'] ?? false, // 📌 THÊM VÀO fromJson
      mqttConfig: json['mqttConfig'] != null
          ? DeviceMqttConfig.fromJson(json['mqttConfig'])
          : null, // 📡 THÊM VÀO fromJson
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'keyName': keyName, // 🎯 THÊM VÀO toJson
      'deviceCode': deviceCode, // 🔑 THÊM VÀO toJson
      'type': type.toString().split('.').last,
      'state': state,
      'value': value,
      'isServo360': isServo360, // For servo type: true = 360°, false = 180°
      'icon': icon,
      'avatarPath': avatarPath, // 🎨 THÊM VÀO toJson
      'room': room,
      'userId': userId, // 👤 THÊM VÀO toJson
      'lastUpdated': lastUpdated?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'isPinned': isPinned, // 📌 THÊM VÀO toJson
      'mqttConfig': mqttConfig?.toJson(), // 📡 THÊM VÀO toJson
    };
  }

  Device copyWith({
    String? id,
    String? name,
    String? keyName, // 🎯 THÊM VÀO copyWith
    String? deviceCode, // 🔑 THÊM VÀO copyWith
    DeviceType? type,
    bool? state,
    int? value,
    bool? isServo360, // For servo type: true = 360°, false = 180°
    String? icon,
    String? avatarPath, // 🎨 THÊM VÀO copyWith
    String? room,
    String? userId, // 👤 THÊM VÀO copyWith
    DateTime? lastUpdated,
    DateTime? createdAt,
    bool? isPinned, // 📌 THÊM VÀO copyWith
    DeviceMqttConfig? mqttConfig, // 📡 THÊM VÀO copyWith
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      keyName: keyName ?? this.keyName, // 🎯 THÊM VÀO copyWith
      deviceCode: deviceCode ?? this.deviceCode, // 🔑 THÊM VÀO copyWith
      type: type ?? this.type,
      state: state ?? this.state,
      value: value ?? this.value,
      isServo360:
          isServo360 ??
          this.isServo360, // For servo type: true = 360°, false = 180°
      icon: icon ?? this.icon,
      avatarPath: avatarPath ?? this.avatarPath, // 🎨 THÊM VÀO copyWith
      room: room ?? this.room,
      userId: userId ?? this.userId, // 👤 THÊM VÀO copyWith
      lastUpdated: lastUpdated ?? this.lastUpdated,
      createdAt: createdAt ?? this.createdAt,
      isPinned: isPinned ?? this.isPinned, // 📌 THÊM VÀO copyWith
      mqttConfig: mqttConfig ?? this.mqttConfig, // 📡 THÊM VÀO copyWith
    );
  }

  bool get isRelay => type == DeviceType.relay;
  bool get isServo => type == DeviceType.servo;
  bool get isFan => type == DeviceType.fan;
  bool get isOn => state;
  bool get isOff => !state;

  // 🌪️ FAN SPECIFIC PROPERTIES
  int get fanSpeed => isFan ? (value ?? 0) : 0;
  String get fanMode {
    if (!isFan) return 'off';
    final speed = fanSpeed;
    if (speed == 0) return 'off';
    if (speed <= 85) return 'low';
    if (speed <= 170) return 'medium';
    return 'high';
  }

  // 🌪️ FAN SPEED HELPERS
  static const int fanSpeedLow = 85;
  static const int fanSpeedMedium = 170;
  static const int fanSpeedHigh = 255;

  // 📡 MQTT TOPIC GENERATION
  String get mqttTopic {
    // Tạo topic dạng: smart_home/devices/room/device_name
    final cleanRoom = (room ?? 'general')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    final cleanName = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    return 'smart_home/devices/$cleanRoom/$cleanName';
  }

  // 📡 FALLBACK TO OLD TOPIC FORMAT
  String get legacyMqttTopic => 'smarthome/control/$id';

  // 📡 MQTT CONFIGURATION HELPERS

  /// Kiểm tra thiết bị có sử dụng cấu hình MQTT riêng không
  bool get hasCustomMqttConfig => mqttConfig?.useCustomConfig == true;

  /// Lấy broker MQTT cho thiết bị này (riêng hoặc global)
  String get mqttBroker => mqttConfig?.broker ?? 'default';

  /// Lấy port MQTT cho thiết bị này
  int get mqttPort => mqttConfig?.port ?? 8883;

  /// Lấy username MQTT cho thiết bị này
  String? get mqttUsername => mqttConfig?.username;

  /// Lấy password MQTT cho thiết bị này
  String? get mqttPassword => mqttConfig?.password;

  /// Kiểm tra thiết bị có sử dụng SSL không
  bool get mqttUseSsl => mqttConfig?.useSsl ?? true;

  /// Lấy topic cuối cùng (dùng custom topic nếu có)
  String get finalMqttTopic => mqttConfig?.getTopic(mqttTopic) ?? mqttTopic;

  /// Tạo client ID unique cho thiết bị này
  String get mqttClientId =>
      mqttConfig?.generateClientId() ??
      'device_${id}_${DateTime.now().millisecondsSinceEpoch}';
}

enum DeviceType { relay, servo, fan }

extension DeviceTypeExtension on DeviceType {
  /// Tên hiển thị dễ hiểu cho người dùng
  String get displayName {
    switch (this) {
      case DeviceType.relay:
        return 'Relay (Công tắc)';
      case DeviceType.servo:
        return 'Servo Motor';
      case DeviceType.fan:
        return 'PWM (Điều khiển tốc độ)';
    }
  }

  /// Mô tả chi tiết cho người dùng
  String get description {
    switch (this) {
      case DeviceType.relay:
        return 'Dùng để bật/tắt thiết bị điện như đèn, máy bơm, ổ cắm điện. Chỉ có 2 trạng thái: BẬT hoặc TẮT.';
      case DeviceType.servo:
        return 'Động cơ servo có thể xoay đến góc chính xác. Thường dùng cho cửa tự động, rèm cửa, tay robot.';
      case DeviceType.fan:
        return 'Điều khiển tốc độ thiết bị như quạt, motor, đèn dimmer. Có thể điều chỉnh từ 0% đến 100%.';
    }
  }

  /// Icon đại diện
  String get icon {
    switch (this) {
      case DeviceType.relay:
        return '⚡';
      case DeviceType.servo:
        return '🎚️';
      case DeviceType.fan:
        return '🌪️';
    }
  }

  /// Đơn vị đo
  String get unit {
    switch (this) {
      case DeviceType.relay:
        return '';
      case DeviceType.servo:
        return '°';
      case DeviceType.fan:
        return '%';
    }
  }

  /// Giá trị mặc định tối thiểu
  int get minValue {
    switch (this) {
      case DeviceType.relay:
        return 0;
      case DeviceType.servo:
        return 0;
      case DeviceType.fan:
        return 0;
    }
  }

  /// Giá trị mặc định tối đa
  int get maxValue {
    switch (this) {
      case DeviceType.relay:
        return 1;
      case DeviceType.servo:
        return 180;
      case DeviceType.fan:
        return 255;
    }
  }

  /// Các preset thông dụng
  List<DevicePreset> get presets {
    switch (this) {
      case DeviceType.relay:
        return [DevicePreset('Tắt', 0), DevicePreset('Bật', 1)];
      case DeviceType.servo:
        return [
          DevicePreset('Đóng/Tắt', 0),
          DevicePreset('45°', 45),
          DevicePreset('90°', 90),
          DevicePreset('135°', 135),
          DevicePreset('Mở tối đa', 180),
        ];
      case DeviceType.fan:
        return [
          DevicePreset('Tắt', 0),
          DevicePreset('Nhẹ', 85), // 33%
          DevicePreset('Khá', 170), // 67%
          DevicePreset('Mạnh', 255), // 100%
        ];
    }
  }
}

/// 🎯 CHUẨN HÓA TÊN THIẾT BỊ CHO AI VOICE CONTROL
/// Chuyển "Đèn phòng khách" → "den_phong_khach"
String normalizeDeviceName(String displayName) {
  // Loại bỏ dấu tiếng Việt
  String normalized = displayName
      .toLowerCase()
      .replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
      .replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e')
      .replaceAll(RegExp(r'[ìíịỉĩ]'), 'i')
      .replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
      .replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u')
      .replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y')
      .replaceAll(RegExp(r'[đ]'), 'd')
      .replaceAll(RegExp(r'[^a-z0-9\s]'), '') // Loại bỏ ký tự đặc biệt
      .replaceAll(RegExp(r'\s+'), '_') // Thay space = _
      .replaceAll(RegExp(r'_+'), '_') // Loại bỏ _ liên tiếp
      .replaceAll(RegExp(r'^_|_$'), ''); // Loại bỏ _ đầu/cuối

  return normalized.isNotEmpty ? normalized : 'device';
}

/// 🎯 TẠO ID NGẪU NHIÊN CHO THIẾT BỊ
String generateDeviceId() {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final random = DateTime.now().millisecondsSinceEpoch;
  String result = '';

  for (int i = 0; i < 10; i++) {
    result += chars[(random + i) % chars.length];
  }

  return result;
}

class DevicePreset {
  final String name;
  final int value;

  const DevicePreset(this.name, this.value);
}
