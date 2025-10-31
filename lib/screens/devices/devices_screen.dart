import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/mqtt_provider.dart';
import '../../config/app_colors.dart';
import '../../config/constants.dart';
import 'widgets/device_card.dart' show DeviceCard;

class DevicesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thiết bị'),
        actions: [
          Consumer<DeviceProvider>(
            builder: (context, deviceProvider, _) {
              return TextButton.icon(
                onPressed: () => _showDeviceOptions(context, deviceProvider),
                icon: Icon(Icons.more_vert, color: Colors.white),
                label: Text(
                  '${deviceProvider.getActiveDevicesCount()}/${deviceProvider.devicesCount}',
                  style: TextStyle(color: Colors.white),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<DeviceProvider>(
        builder: (context, deviceProvider, _) {
          final devices = deviceProvider.devices;

          if (devices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.devices_other, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Chưa có thiết bị',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Reload devices
              await Future.delayed(Duration(seconds: 1));
            },
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                // Header
                _buildHeader(context, deviceProvider),
                SizedBox(height: 24),

                // Relay Devices
                if (deviceProvider.relays.isNotEmpty) ...[
                  _buildSectionTitle(
                    'Thiết bị Relay',
                    deviceProvider.relays.length,
                  ),
                  SizedBox(height: 12),
                  ...deviceProvider.relays.map((device) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: DeviceCard(
                        device: device,
                        onToggle: () => _toggleDevice(context, device.id),
                        onTap: () => _showDeviceDetail(context, device),
                      ),
                    );
                  }).toList(),
                  SizedBox(height: 24),
                ],

                // Servo Devices
                if (deviceProvider.servos.isNotEmpty) ...[
                  _buildSectionTitle(
                    'Thiết bị Servo',
                    deviceProvider.servos.length,
                  ),
                  SizedBox(height: 12),
                  ...deviceProvider.servos.map((device) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: DeviceCard(
                        device: device,
                        onValueChange: (value) =>
                            _updateServoValue(context, device.id, value),
                        onTap: () => _showDeviceDetail(context, device),
                      ),
                    );
                  }).toList(),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDeviceDialog(context),
        child: Icon(Icons.add),
        tooltip: 'Thêm thiết bị',
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DeviceProvider deviceProvider) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.blueGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.devices, color: Colors.white, size: 32),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tổng quan thiết bị',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${deviceProvider.getActiveDevicesCount()} đang hoạt động',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                '${deviceProvider.devicesCount}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Thiết bị',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(width: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  void _toggleDevice(BuildContext context, String deviceId) {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    final mqttProvider = Provider.of<MqttProvider>(context, listen: false);

    deviceProvider.toggleDevice(deviceId);

    final device = deviceProvider.getDeviceById(deviceId);
    if (device != null) {
      final topic = _getDeviceTopic(deviceId);
      mqttProvider.publish(topic, device.state ? '1' : '0');
    }
  }

  void _updateServoValue(BuildContext context, String deviceId, int value) {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    final mqttProvider = Provider.of<MqttProvider>(context, listen: false);

    deviceProvider.updateServoValue(deviceId, value);

    final topic = _getDeviceTopic(deviceId);
    mqttProvider.publish(topic, value.toString());
  }

  String _getDeviceTopic(String deviceId) {
    switch (deviceId) {
      case 'pump':
        return MqttTopics.pump;
      case 'light_living':
        return MqttTopics.lightLiving;
      case 'light_yard':
        return MqttTopics.lightYard;
      case 'ionizer':
        return MqttTopics.ionizer;
      case 'roof_servo':
        return MqttTopics.roofServo;
      case 'gate_servo':
        return MqttTopics.gateServo;
      default:
        return '${MqttTopics.base}/controls/$deviceId';
    }
  }

  void _showDeviceDetail(BuildContext context, device) {
    Navigator.pushNamed(context, '/device_detail', arguments: device);
  }

  void _showAddDeviceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thêm thiết bị'),
        content: Text('Chức năng đang được phát triển'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showDeviceOptions(BuildContext context, DeviceProvider deviceProvider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.power_settings_new, color: AppColors.success),
              title: Text('Bật tất cả thiết bị'),
              onTap: () {
                deviceProvider.turnOnAllDevices();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.power_off, color: AppColors.error),
              title: Text('Tắt tất cả thiết bị'),
              onTap: () {
                deviceProvider.turnOffAllDevices();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
