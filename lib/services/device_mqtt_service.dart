import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/device_model.dart';

/// Service quản lý kết nối MQTT riêng cho từng thiết bị
/// Cho phép mỗi thiết bị kết nối đến broker MQTT khác nhau
class DeviceMqttService {
  // Cache các client MQTT cho từng thiết bị
  final Map<String, MqttServerClient> _deviceClients = {};

  // Callbacks cho từng thiết bị
  final Map<String, Function(String message)?> _deviceMessageCallbacks = {};
  final Map<String, Function()?> _deviceConnectedCallbacks = {};
  final Map<String, Function()?> _deviceDisconnectedCallbacks = {};

  /// Kết nối thiết bị đến broker MQTT riêng
  Future<bool> connectDevice(Device device) async {
    try {
      final deviceId = device.id;

      // Nếu thiết bị không có cấu hình MQTT riêng, sử dụng global
      if (!device.hasCustomMqttConfig) {
        print('📡 Device $deviceId: Using global MQTT config');
        return true; // Sẽ được xử lý bởi MqttService chính
      }

      final config = device.mqttConfig!;
      print(
        '📡 Device $deviceId: Connecting to custom broker ${config.broker}:${config.port}',
      );

      // Tạo client với unique ID
      final clientId = device.mqttClientId;
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
      client.onConnected = () => _onDeviceConnected(deviceId);
      client.onDisconnected = () => _onDeviceDisconnected(deviceId);

      // Connection message
      final connMessage = MqttConnectMessage()
          .authenticateAs(config.username ?? '', config.password ?? '')
          .startClean()
          .keepAliveFor(30);

      client.connectionMessage = connMessage;

      // Connect
      await client.connect();

      if (client.connectionStatus?.state == MqttConnectionState.connected) {
        print('✅ Device $deviceId: Connected to ${config.broker}');

        // Lưu client vào cache
        _deviceClients[deviceId] = client;

        // Setup message listener
        _setupDeviceMessageListener(deviceId, client);

        return true;
      } else {
        print('❌ Device $deviceId: Connection failed to ${config.broker}');
        client.disconnect();
        return false;
      }
    } catch (e) {
      print('❌ Device ${device.id} Connection Error: $e');
      try {
        _deviceClients[device.id]?.disconnect();
        _deviceClients.remove(device.id);
      } catch (_) {}
      return false;
    }
  }

  /// Ngắt kết nối thiết bị
  void disconnectDevice(String deviceId) {
    try {
      final client = _deviceClients[deviceId];
      if (client != null) {
        client.disconnect();
        _deviceClients.remove(deviceId);
        print('🔌 Device $deviceId: Disconnected from custom broker');
      }
    } catch (e) {
      print('❌ Device $deviceId Disconnect Error: $e');
    }
  }

  /// Ngắt kết nối tất cả thiết bị
  void disconnectAllDevices() {
    for (final deviceId in _deviceClients.keys.toList()) {
      disconnectDevice(deviceId);
    }
  }

  /// Kiểm tra thiết bị có kết nối đến broker riêng không
  bool isDeviceConnected(String deviceId) {
    final client = _deviceClients[deviceId];
    return client?.connectionStatus?.state == MqttConnectionState.connected;
  }

  /// Lấy trạng thái kết nối của thiết bị
  String getDeviceConnectionStatus(String deviceId) {
    final client = _deviceClients[deviceId];
    if (client == null) return 'Not Connected';

    final state = client.connectionStatus?.state;
    switch (state) {
      case MqttConnectionState.connected:
        return 'Connected';
      case MqttConnectionState.connecting:
        return 'Connecting...';
      case MqttConnectionState.disconnected:
        return 'Disconnected';
      case MqttConnectionState.disconnecting:
        return 'Disconnecting...';
      default:
        return 'Unknown';
    }
  }

  /// Đăng ký callback cho thiết bị
  void setDeviceCallback(
    String deviceId, {
    Function(String message)? onMessage,
    Function()? onConnected,
    Function()? onDisconnected,
  }) {
    if (onMessage != null) _deviceMessageCallbacks[deviceId] = onMessage;
    if (onConnected != null) _deviceConnectedCallbacks[deviceId] = onConnected;
    if (onDisconnected != null)
      _deviceDisconnectedCallbacks[deviceId] = onDisconnected;
  }

  /// Hủy đăng ký callback cho thiết bị
  void removeDeviceCallback(String deviceId) {
    _deviceMessageCallbacks.remove(deviceId);
    _deviceConnectedCallbacks.remove(deviceId);
    _deviceDisconnectedCallbacks.remove(deviceId);
  }

  /// Lấy danh sách thiết bị đang kết nối
  List<String> get connectedDeviceIds => _deviceClients.keys.toList();

  /// Lấy thông tin broker của thiết bị
  String getDeviceBrokerInfo(String deviceId) {
    final client = _deviceClients[deviceId];
    if (client == null) return 'Not connected';

    final host = client.server;
    final port = client.port;
    return '$host:$port';
  }

  // ════════════════════════════════════════════════════════
  // PRIVATE METHODS
  // ════════════════════════════════════════════════════════

  void _onDeviceConnected(String deviceId) {
    print('✅ Device $deviceId: Connected to custom broker');
    _deviceConnectedCallbacks[deviceId]?.call();
  }

  void _onDeviceDisconnected(String deviceId) {
    print('❌ Device $deviceId: Disconnected from custom broker');
    _deviceDisconnectedCallbacks[deviceId]?.call();
  }

  void _setupDeviceMessageListener(String deviceId, MqttServerClient client) {
    client.updates!.listen(
      (List<MqttReceivedMessage<MqttMessage>> messages) {
        final recMess = messages[0].payload as MqttPublishMessage;
        final topic = messages[0].topic;
        final payload = MqttPublishPayload.bytesToStringAsString(
          recMess.payload.message,
        );

        print('📨 Device $deviceId: Received [$topic]: $payload');

        // Gọi callback nếu có
        _deviceMessageCallbacks[deviceId]?.call(payload);
      },
      onError: (error) {
        print('❌ Device $deviceId Stream Error: $error');
      },
      onDone: () {
        print('🔚 Device $deviceId Stream Done');
      },
    );
  }

  /// Gửi message đến thiết bị qua broker riêng của nó
  Future<bool> publishToDevice(
    Device device,
    String message, {
    bool retain = false,
  }) async {
    print('🔍 DEBUG: publishToDevice called for device ${device.name}');
    print('🔍 DEBUG: hasCustomMqttConfig: ${device.hasCustomMqttConfig}');

    if (!device.hasCustomMqttConfig) {
      print(
        '❌ DEBUG: Device does not have custom MQTT config, returning false',
      );
      return false; // Device không có cấu hình MQTT riêng
    }

    final config = device.mqttConfig!;
    print('🔍 DEBUG: Using custom broker: ${config.broker}:${config.port}');
    print('🔍 DEBUG: Topic: ${device.finalMqttTopic}');
    print('🔍 DEBUG: Message: $message');

    MqttServerClient? client = _deviceClients[device.id];

    if (client == null ||
        client.connectionStatus?.state != MqttConnectionState.connected) {
      // Client chưa tồn tại hoặc chưa kết nối, tạo mới và kết nối
      print(
        '🔄 Device MQTT: Connecting to ${config.broker}:${config.port} for device ${device.name}...',
      );
      client = MqttServerClient.withPort(
        config.broker,
        device.mqttClientId,
        config.port,
      );

      client.logging(on: false);
      client.keepAlivePeriod = 30;
      client.connectTimeoutPeriod = 10 * 1000;
      client.autoReconnect = true;
      client.resubscribeOnAutoReconnect = true;

      client.secure = config.useSsl;
      if (config.useSsl) {
        client.securityContext = SecurityContext.defaultContext;
      }
      client.setProtocolV311();

      final connMessage = MqttConnectMessage()
          .authenticateAs(config.username, config.password)
          .withWillTopic('${device.finalMqttTopic}/status')
          .withWillMessage('offline')
          .withWillQos(MqttQos.atLeastOnce)
          .withWillRetain()
          .startClean()
          .keepAliveFor(30);

      client.connectionMessage = connMessage;

      try {
        await client.connect();
        if (client.connectionStatus?.state == MqttConnectionState.connected) {
          print(
            '✅ Device MQTT: Connected to ${config.broker} for device ${device.name}',
          );
          _deviceClients[device.id] = client;
        } else {
          print(
            '❌ Device MQTT: Connection failed for device ${device.name} - ${client.connectionStatus?.returnCode}',
          );
          client.disconnect();
          return false;
        }
      } catch (e) {
        print('❌ Device MQTT Connection Error for device ${device.name}: $e');
        try {
          client.disconnect();
        } catch (_) {}
        return false;
      }
    }

    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      try {
        final builder = MqttClientPayloadBuilder();
        builder.addString(message);

        client.publishMessage(
          device.finalMqttTopic,
          MqttQos.atLeastOnce,
          builder.payload!,
          retain: retain,
        );
        print(
          '📤 Device MQTT: Published to ${device.finalMqttTopic}: $message for device ${device.name}',
        );
        return true;
      } catch (e) {
        print('❌ Device MQTT Publish Error for device ${device.name}: $e');
        return false;
      }
    }
    return false;
  }

  /// Subscribe đến custom topic
  Future<bool> subscribeToCustomTopic(Device device, String topic) async {
    print('🔍 DEBUG: subscribeToCustomTopic called for device ${device.name}');
    print('🔍 DEBUG: Topic: $topic');

    if (!device.hasCustomMqttConfig) {
      print('❌ Device does not have custom MQTT config');
      return false;
    }

    final config = device.mqttConfig!;
    MqttServerClient? client = _deviceClients[device.id];

    // Nếu chưa connect, connect trước
    if (client == null ||
        client.connectionStatus?.state != MqttConnectionState.connected) {
      print(
        '🔄 Device MQTT: Connecting for subscription to ${config.broker}:${config.port}...',
      );

      client = MqttServerClient.withPort(
        config.broker,
        device.mqttClientId,
        config.port,
      );

      client.logging(on: false);
      client.keepAlivePeriod = 30;
      client.connectTimeoutPeriod = 10 * 1000;
      client.autoReconnect = true;
      client.resubscribeOnAutoReconnect = true;

      client.secure = config.useSsl;
      if (config.useSsl) {
        client.securityContext = SecurityContext.defaultContext;
      }
      client.setProtocolV311();

      final connMessage = MqttConnectMessage()
          .authenticateAs(config.username, config.password)
          .withWillTopic('${device.finalMqttTopic}/status')
          .withWillMessage('offline')
          .withWillQos(MqttQos.atLeastOnce)
          .withWillRetain()
          .startClean()
          .keepAliveFor(30);

      client.connectionMessage = connMessage;

      try {
        await client.connect();
        if (client.connectionStatus?.state == MqttConnectionState.connected) {
          print('✅ Device MQTT: Connected for subscription');
          _deviceClients[device.id] = client;

          // Thiết lập message handler
          _setupDeviceMessageListener(device.id, client);
        } else {
          print('❌ Device MQTT: Connection failed');
          return false;
        }
      } catch (e) {
        print('❌ Device MQTT Connection Error: $e');
        return false;
      }
    }

    // Subscribe sau khi đảm bảo đã connected
    try {
      client.subscribe(topic, MqttQos.atLeastOnce);
      print('✅ Subscribed to custom topic: $topic');

      // Đợi một chút để đảm bảo subscription đã được xử lý
      await Future.delayed(const Duration(milliseconds: 200));

      return true;
    } catch (e) {
      print('❌ Failed to subscribe to custom topic: $e');
      return false;
    }
  }

  /// Gửi message đến custom topic (ví dụ: /ping, /status)
  Future<bool> publishToCustomTopic(
    Device device,
    String topic,
    String message, {
    bool retain = false,
  }) async {
    print('🔍 DEBUG: publishToCustomTopic called for device ${device.name}');
    print('🔍 DEBUG: Custom topic: $topic');
    print('🔍 DEBUG: Message: $message');

    if (!device.hasCustomMqttConfig) {
      print(
        '❌ DEBUG: Device does not have custom MQTT config, returning false',
      );
      return false;
    }

    final config = device.mqttConfig!;
    MqttServerClient? client = _deviceClients[device.id];

    if (client == null ||
        client.connectionStatus?.state != MqttConnectionState.connected) {
      // Connect first
      print(
        '🔄 Device MQTT: Connecting to ${config.broker}:${config.port} for custom topic...',
      );
      client = MqttServerClient.withPort(
        config.broker,
        device.mqttClientId,
        config.port,
      );

      client.logging(on: false);
      client.keepAlivePeriod = 30;
      client.connectTimeoutPeriod = 10 * 1000;
      client.secure = config.useSsl;
      if (config.useSsl) {
        client.securityContext = SecurityContext.defaultContext;
      }
      client.setProtocolV311();

      final connMessage = MqttConnectMessage()
          .authenticateAs(config.username ?? '', config.password ?? '')
          .startClean()
          .keepAliveFor(30);
      client.connectionMessage = connMessage;

      try {
        await client.connect();
        if (client.connectionStatus?.state == MqttConnectionState.connected) {
          _deviceClients[device.id] = client;
          print('✅ Device MQTT: Connected for custom topic publish');
        } else {
          print('❌ Device MQTT: Connection failed for custom topic');
          client.disconnect();
          return false;
        }
      } catch (e) {
        print('❌ Device MQTT Connection Error: $e');
        try {
          client.disconnect();
        } catch (_) {}
        return false;
      }
    }

    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      try {
        final builder = MqttClientPayloadBuilder();
        builder.addString(message);

        client.publishMessage(
          topic,
          MqttQos.atLeastOnce,
          builder.payload!,
          retain: retain,
        );
        print('📤 Device MQTT: Published to $topic: $message');
        return true;
      } catch (e) {
        print('❌ Device MQTT Publish Error: $e');
        return false;
      }
    }
    return false;
  }

  /// Cleanup khi service bị dispose
  void dispose() {
    disconnectAllDevices();
    _deviceMessageCallbacks.clear();
    _deviceConnectedCallbacks.clear();
    _deviceDisconnectedCallbacks.clear();
  }
}
