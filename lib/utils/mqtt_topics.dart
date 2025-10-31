class MqttTopicHelper {
  static const String base = 'smart_home';

  // Sensor topics
  static const String sensorBase = '$base/sensors';
  static const String temperature = '$sensorBase/temperature';
  static const String humidity = '$sensorBase/humidity';
  static const String rain = '$sensorBase/rain';
  static const String light = '$sensorBase/light';
  static const String soilMoisture = '$sensorBase/soil_moisture';
  static const String gas = '$sensorBase/gas';
  static const String dust = '$sensorBase/dust';
  static const String pir = '$sensorBase/pir';

  // Control topics
  static const String controlBase = '$base/controls';
  static const String pump = '$controlBase/pump';
  static const String lightLiving = '$controlBase/light_living';
  static const String lightYard = '$controlBase/light_yard';
  static const String mistMaker = '$controlBase/mist_maker';
  static const String roofServo = '$controlBase/roof_servo';
  static const String gateServo = '$controlBase/gate_servo';

  // Alert topics
  static const String alertBase = '$base/alerts';
  static const String gasAlert = '$alertBase/gas_warning';
  static const String rainAlert = '$alertBase/rain_detected';
  static const String lowSoilAlert = '$alertBase/low_soil_moisture';

  // Status topics
  static const String statusBase = '$base/status';
  static const String deviceOnline = '$statusBase/device_online';
  static const String deviceOffline = '$statusBase/device_offline';

  // Get all sensor topics for subscription
  static List<String> getAllSensorTopics() {
    return [temperature, humidity, rain, light, soilMoisture, gas, dust, pir];
  }

  // Get all control topics for subscription
  static List<String> getAllControlTopics() {
    return [pump, lightLiving, lightYard, mistMaker, roofServo, gateServo];
  }

  // Get all alert topics for subscription
  static List<String> getAllAlertTopics() {
    return [gasAlert, rainAlert, lowSoilAlert];
  }

  // Get all topics for subscription
  static List<String> getAllTopics() {
    return [
      ...getAllSensorTopics(),
      ...getAllControlTopics(),
      ...getAllAlertTopics(),
      deviceOnline,
      deviceOffline,
    ];
  }

  // Get topic for specific device
  static String getDeviceTopic(String deviceId) {
    switch (deviceId) {
      case 'pump':
        return pump;
      case 'light_living':
        return lightLiving;
      case 'light_yard':
        return lightYard;
      case 'mist_maker':
        return mistMaker;
      case 'roof_servo':
        return roofServo;
      case 'gate_servo':
        return gateServo;
      default:
        return '$controlBase/$deviceId';
    }
  }

  // Get topic for specific sensor
  static String getSensorTopic(String sensorType) {
    switch (sensorType) {
      case 'temperature':
        return temperature;
      case 'humidity':
        return humidity;
      case 'rain':
        return rain;
      case 'light':
        return light;
      case 'soil_moisture':
        return soilMoisture;
      case 'gas':
        return gas;
      case 'dust':
        return dust;
      case 'pir':
      case 'motion':
        return pir;
      default:
        return '$sensorBase/$sensorType';
    }
  }

  // Check if topic is a sensor topic
  static bool isSensorTopic(String topic) {
    return topic.startsWith(sensorBase);
  }

  // Check if topic is a control topic
  static bool isControlTopic(String topic) {
    return topic.startsWith(controlBase);
  }

  // Check if topic is an alert topic
  static bool isAlertTopic(String topic) {
    return topic.startsWith(alertBase);
  }

  // Extract sensor type from topic
  static String? extractSensorType(String topic) {
    if (!isSensorTopic(topic)) return null;
    return topic.replaceFirst('$sensorBase/', '');
  }

  // Extract device ID from topic
  static String? extractDeviceId(String topic) {
    if (!isControlTopic(topic)) return null;
    return topic.replaceFirst('$controlBase/', '');
  }

  // Create wildcard subscription for all sensors
  static String getSensorWildcard() {
    return '$sensorBase/#';
  }

  // Create wildcard subscription for all controls
  static String getControlWildcard() {
    return '$controlBase/#';
  }

  // Create wildcard subscription for all alerts
  static String getAlertWildcard() {
    return '$alertBase/#';
  }

  // Create wildcard subscription for everything
  static String getAllWildcard() {
    return '$base/#';
  }
}

// Alias for backward compatibility
class MqttTopics {
  static const String base = MqttTopicHelper.base;
  static const String pump = MqttTopicHelper.pump;
  static const String lightLiving = MqttTopicHelper.lightLiving;
  static const String lightYard = MqttTopicHelper.lightYard;
  static const String mistMaker = MqttTopicHelper.mistMaker;
  static const String roofServo = MqttTopicHelper.roofServo;
  static const String gateServo = MqttTopicHelper.gateServo;
}
