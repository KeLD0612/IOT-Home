import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/user_sensor.dart';

/// Service quản lý kết nối MQTT riêng cho từng sensor
/// Cho phép mỗi sensor kết nối đến broker MQTT khác nhau
class SensorMqttService {
  // Cache các client MQTT cho từng sensor
  final Map<String, MqttServerClient> _sensorClients = {};

  // Callbacks cho từng sensor
  final Map<String, Function(String message)?> _sensorMessageCallbacks = {};
  final Map<String, Function()?> _sensorConnectedCallbacks = {};
  final Map<String, Function()?> _sensorDisconnectedCallbacks = {};

  /// Kết nối sensor đến broker MQTT riêng
  Future<bool> connectSensor(UserSensor sensor) async {
    try {
      final sensorId = sensor.id;

      // Nếu sensor không có cấu hình MQTT riêng, sử dụng global
      if (sensor.mqttConfig == null) {
        print('📡 Sensor $sensorId: Using global MQTT config');
        return true; // Sẽ được xử lý bởi MqttService chính
      }

      final config = sensor.mqttConfig!;
      print(
        '📡 Sensor $sensorId: Connecting to custom broker ${config.broker}:${config.port}',
      );

      // Tạo client với unique ID
      final clientId =
          'sensor_${sensor.deviceCode}_${DateTime.now().millisecondsSinceEpoch}';
      final client = MqttServerClient.withPort(
        config.broker,
        clientId,
        config.port,
      );

      // Cấu hình client
      client.logging(on: false);
      client.keepAlivePeriod = 30;
      client.connectTimeoutPeriod = 10 * 1000;
      client.autoReconnect = true;
      client.resubscribeOnAutoReconnect = true;

      // SSL/TLS
      client.secure = config.useSsl;
      if (config.useSsl) {
        client.securityContext = SecurityContext.defaultContext;
      }

      // Set protocol
      client.setProtocolV311();

      // Callbacks
      client.onConnected = () => _onSensorConnected(sensorId);
      client.onDisconnected = () => _onSensorDisconnected(sensorId);

      // Connection message
      final connMessage = MqttConnectMessage()
          .authenticateAs(config.username ?? '', config.password ?? '')
          .startClean()
          .keepAliveFor(30);

      client.connectionMessage = connMessage;

      // Connect
      await client.connect();

      if (client.connectionStatus?.state == MqttConnectionState.connected) {
        print('✅ Sensor $sensorId: Connected to ${config.broker}');

        // Lưu client vào cache
        _sensorClients[sensorId] = client;

        // Setup message listener
        _setupSensorMessageListener(sensorId, client);

        return true;
      } else {
        print('❌ Sensor $sensorId: Connection failed to ${config.broker}');
        client.disconnect();
        return false;
      }
    } catch (e) {
      print('❌ Sensor ${sensor.id} Connection Error: $e');
      try {
        _sensorClients[sensor.id]?.disconnect();
        _sensorClients.remove(sensor.id);
      } catch (_) {}
      return false;
    }
  }

  /// Ngắt kết nối sensor
  void disconnectSensor(String sensorId) {
    try {
      final client = _sensorClients[sensorId];
      if (client != null) {
        print('🔌 Sensor $sensorId: Disconnecting...');
        client.disconnect();
        _sensorClients.remove(sensorId);
        _sensorMessageCallbacks.remove(sensorId);
        _sensorConnectedCallbacks.remove(sensorId);
        _sensorDisconnectedCallbacks.remove(sensorId);
      }
    } catch (e) {
      print('❌ Sensor $sensorId Disconnect Error: $e');
    }
  }

  /// Subscribe sensor đến custom topic
  Future<void> subscribeToCustomTopic(UserSensor sensor, String topic) async {
    try {
      final sensorId = sensor.id;

      print('🔍 DEBUG: subscribeToCustomTopic called for sensor $sensorId');
      print('🔍 DEBUG: Topic: $topic');

      // Kiểm tra xem sensor có client riêng không
      var client = _sensorClients[sensorId];

      // Nếu chưa có client hoặc client disconnected → TỰ ĐỘNG CONNECT
      if (client == null ||
          client.connectionStatus?.state != MqttConnectionState.connected) {
        print(
          '🔄 Sensor MQTT: Connecting for subscription to ${sensor.mqttConfig?.broker}:${sensor.mqttConfig?.port}...',
        );
        final connected = await connectSensor(sensor);

        if (!connected) {
          print(
            '❌ Sensor $sensorId: Cannot connect to broker for subscription',
          );
          return;
        }

        // Lấy client sau khi connect
        client = _sensorClients[sensorId];
      }

      // Subscribe
      if (client != null &&
          client.connectionStatus?.state == MqttConnectionState.connected) {
        client.subscribe(topic, MqttQos.atLeastOnce);
        print('✅ Subscribed to custom topic: $topic');
      }
    } catch (e) {
      print('❌ Sensor ${sensor.id} Subscribe Error: $e');
    }
  }

  /// Publish message từ sensor đến custom topic
  Future<void> publishToCustomTopic(
    UserSensor sensor,
    String topic,
    String message,
  ) async {
    try {
      final sensorId = sensor.id;

      print('🔍 DEBUG: publishToCustomTopic called for sensor $sensorId');
      print('🔍 DEBUG: Custom topic: $topic');
      print('🔍 DEBUG: Message: $message');

      // Kiểm tra xem sensor có client riêng không
      var client = _sensorClients[sensorId];

      // Nếu chưa có client hoặc client disconnected → TỰ ĐỘNG CONNECT
      if (client == null ||
          client.connectionStatus?.state != MqttConnectionState.connected) {
        print(
          '🔄 Sensor MQTT: Connecting for publish to ${sensor.mqttConfig?.broker}:${sensor.mqttConfig?.port}...',
        );
        final connected = await connectSensor(sensor);

        if (!connected) {
          print('❌ Sensor $sensorId: Cannot connect to broker for publish');
          return;
        }

        // Lấy client sau khi connect
        client = _sensorClients[sensorId];
      }

      // Publish
      if (client != null &&
          client.connectionStatus?.state == MqttConnectionState.connected) {
        final builder = MqttClientPayloadBuilder();
        builder.addString(message);
        client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
        print('📤 Sensor MQTT: Published to $topic: $message');
      }
    } catch (e) {
      print('❌ Sensor ${sensor.id} Publish Error: $e');
    }
  }

  /// Set callback cho sensor
  void setSensorCallback(
    String sensorId, {
    Function(String message)? onMessage,
    Function()? onConnected,
    Function()? onDisconnected,
  }) {
    if (onMessage != null) {
      _sensorMessageCallbacks[sensorId] = onMessage;
    }
    if (onConnected != null) {
      _sensorConnectedCallbacks[sensorId] = onConnected;
    }
    if (onDisconnected != null) {
      _sensorDisconnectedCallbacks[sensorId] = onDisconnected;
    }
  }

  /// Remove callback cho sensor
  void removeSensorCallback(String sensorId) {
    _sensorMessageCallbacks.remove(sensorId);
    _sensorConnectedCallbacks.remove(sensorId);
    _sensorDisconnectedCallbacks.remove(sensorId);
  }

  /// Setup message listener cho sensor
  void _setupSensorMessageListener(String sensorId, MqttServerClient client) {
    print('🎧 Setting up message listener for sensor: $sensorId');

    client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      print('📬 Sensor $sensorId: Received ${messages.length} message(s)');

      for (final message in messages) {
        final topic = message.topic;
        final payload = MqttPublishPayload.bytesToStringAsString(
          (message.payload as MqttPublishMessage).payload.message,
        );

        print('📨 Sensor $sensorId: Received [$topic]: $payload');

        // Gọi callback nếu có
        final callback = _sensorMessageCallbacks[sensorId];
        if (callback != null) {
          print('🔔 Triggering callback for sensor: $sensorId');
          callback(payload);
        } else {
          print('⚠️ No callback registered for sensor: $sensorId');
        }
      }
    });

    print('✅ Message listener setup complete for sensor: $sensorId');
  }

  void _onSensorConnected(String sensorId) {
    print('✅ Sensor $sensorId: Connected');
    final callback = _sensorConnectedCallbacks[sensorId];
    if (callback != null) {
      callback();
    }
  }

  void _onSensorDisconnected(String sensorId) {
    print('🔌 Sensor $sensorId: Disconnected');
    final callback = _sensorDisconnectedCallbacks[sensorId];
    if (callback != null) {
      callback();
    }
  }

  /// Dispose tất cả connections
  void dispose() {
    for (final client in _sensorClients.values) {
      try {
        client.disconnect();
      } catch (_) {}
    }
    _sensorClients.clear();
    _sensorMessageCallbacks.clear();
    _sensorConnectedCallbacks.clear();
    _sensorDisconnectedCallbacks.clear();
  }
}
