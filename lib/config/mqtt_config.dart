class MqttConfig {
  static const String broker =
      '16257efaa31f4843a11e19f83c34e594.s1.eu.hivemq.cloud';
  static const int port = 8883;
  static const String username = 'sigma';
  static const String password = '35386Doan';
  static const String clientId = 'flutter_smart_home';

  static const int keepAlivePeriod = 60;
  static const int connectionTimeout = 30;
  static const int reconnectDelay = 5;
}
