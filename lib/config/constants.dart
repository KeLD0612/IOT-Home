class MqttTopics {
  static const String base = 'smart_home';

  // Sensors
  static const String temperature = '$base/sensors/temperature';
  static const String humidity = '$base/sensors/humidity';
  static const String rain = '$base/sensors/rain';
  static const String light = '$base/sensors/light';
  static const String soilMoisture = '$base/sensors/soil_moisture';
  static const String gas = '$base/sensors/gas';
  static const String dust = '$base/sensors/dust';
  static const String pir = '$base/sensors/pir';

  // Controls
  static const String pump = '$base/controls/pump';
  static const String lightLiving = '$base/controls/light_living';
  static const String lightYard = '$base/controls/light_yard';
  static const String mistMaker = '$base/controls/mist_maker';
  static const String roofServo = '$base/controls/roof_servo';
  static const String gateServo = '$base/controls/gate_servo';

  // Status
  static const String deviceOnline = '$base/status/device_online';

  // Alerts
  static const String gasAlert = '$base/alerts/gas_warning';
  static const String rainAlert = '$base/alerts/rain_detected';
  static const String lowSoilAlert = '$base/alerts/low_soil_moisture';
}

class AppConstants {
  // Thresholds
  static const int gasWarningLevel = 1500;
  static const int dustWarningLevel = 150;
  static const double lowSoilMoisture = 30.0;
  static const int lightDarkThreshold = 300;

  // UI
  static const double cardBorderRadius = 12.0;
  static const double defaultPadding = 16.0;

  // Chart
  static const int maxDataPoints = 100;
}

class DeviceNames {
  static const String pump = 'Máy bơm';
  static const String lightLiving = 'Đèn phòng khách';
  static const String lightYard = 'Đèn sân';
  static const String mistMaker = 'Máy phun sương';
  static const String roofServo = 'Cửa trần';
  static const String gateServo = 'Cửa cổng';
}
