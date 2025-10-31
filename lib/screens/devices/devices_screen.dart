import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/device_provider.dart';
import '../../models/device_model.dart';
import '../../config/app_colors.dart';
import 'widgets/device_card.dart' show DeviceCard;
import 'add_device_screen.dart';

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
                        onLongPress: () => _showDeviceMenu(context, device),
                        onPin: () => _togglePin(context, device.id),
                        onEdit: () => _editDevice(context, device),
                        onDelete: () => _deleteDevice(context, device),
                        onMoveRoom: () => _moveDeviceToRoom(context, device),
                        onCheckConnection: () =>
                            _checkMqttConnection(context, device),
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
                        onLongPress: () => _showDeviceMenu(context, device),
                        onPin: () => _togglePin(context, device.id),
                        onEdit: () => _editDevice(context, device),
                        onDelete: () => _deleteDevice(context, device),
                        onMoveRoom: () => _moveDeviceToRoom(context, device),
                        onCheckConnection: () =>
                            _checkMqttConnection(context, device),
                      ),
                    );
                  }).toList(),
                  SizedBox(height: 24),
                ],

                // Fan Devices
                if (deviceProvider.fans.isNotEmpty) ...[
                  _buildSectionTitle(
                    'Thiết bị Quạt',
                    deviceProvider.fans.length,
                  ),
                  SizedBox(height: 12),
                  ...deviceProvider.fans.map((device) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: DeviceCard(
                        device: device,
                        onValueChange: (value) => _updateFanSpeed(
                          context,
                          device.id,
                          value.toDouble(),
                        ),
                        onTap: () => _showDeviceDetail(context, device),
                        onLongPress: () => _showDeviceMenu(context, device),
                        onPin: () => _togglePin(context, device.id),
                        onEdit: () => _editDevice(context, device),
                        onDelete: () => _deleteDevice(context, device),
                        onMoveRoom: () => _moveDeviceToRoom(context, device),
                        onCheckConnection: () =>
                            _checkMqttConnection(context, device),
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
    // Removed duplicate MQTT publish - DeviceProvider already handles this
    deviceProvider.toggleDevice(deviceId);
  }

  void _updateServoValue(BuildContext context, String deviceId, int value) {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    // Removed duplicate MQTT publish - DeviceProvider already handles this
    deviceProvider.updateServoValue(deviceId, value);
  }

  void _updateFanSpeed(BuildContext context, String deviceId, double value) {
    print('_updateFanSpeed called: deviceId=$deviceId, value=$value');
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    deviceProvider.updateServoValue(
      deviceId,
      value.toInt(),
    ); // Fan cũng dùng value field như servo
  }

  void _togglePin(BuildContext context, String deviceId) {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    deviceProvider.togglePin(deviceId);

    // Hiển thị snackbar thông báo
    final device = deviceProvider.devices.firstWhere((d) => d.id == deviceId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          device.isPinned
              ? '📌 Đã ghim "${device.name}" vào điều khiển nhanh'
              : '📌 Đã bỏ ghim "${device.name}" khỏi điều khiển nhanh',
        ),
        duration: Duration(seconds: 2),
        backgroundColor: device.isPinned ? AppColors.success : Colors.grey[600],
      ),
    );
  }

  void _showDeviceDetail(BuildContext context, device) {
    Navigator.pushNamed(context, '/device_detail', arguments: device);
  }

  void _showAddDeviceDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddDeviceScreen()),
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

  void _showDeviceMenu(BuildContext context, Device device) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  device.type == DeviceType.relay
                      ? Icons.power_outlined
                      : device.type == DeviceType.servo
                      ? Icons.tune
                      : Icons.air,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Phòng: ${device.room ?? "Chung"}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showDeviceDetail(context, device);
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Chi tiết'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmDeleteDevice(context, device);
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Xóa'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteDevice(BuildContext context, Device device) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              const SizedBox(width: 12),
              const Text('Xác nhận xóa'),
            ],
          ),
          content: Text(
            'Bạn có chắc chắn muốn xóa thiết bị "${device.name}"?\n\nHành động này không thể hoàn tác.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteDevice(context, device);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );
  }

  void _deleteDevice(BuildContext context, Device device) async {
    try {
      final deviceProvider = Provider.of<DeviceProvider>(
        context,
        listen: false,
      );
      final success = await deviceProvider.removeDevice(device.id);

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Đã xóa thiết bị "${device.name}"'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Không thể xóa thiết bị'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _moveDeviceToRoom(BuildContext context, Device device) {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    final availableRooms = deviceProvider.availableRooms;
    String? selectedRoom;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Chuyển thiết bị "${device.name}"'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Thiết bị hiện tại ở phòng: ${device.room ?? "Không xác định"}',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRoom,
                  decoration: const InputDecoration(
                    labelText: 'Chọn phòng đích',
                    border: OutlineInputBorder(),
                  ),
                  items: availableRooms
                      .where((room) => room != device.room)
                      .map(
                        (room) =>
                            DropdownMenuItem(value: room, child: Text(room)),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedRoom = value;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: selectedRoom != null
                    ? () async {
                        try {
                          await deviceProvider.moveDeviceToRoom(
                            device.id,
                            selectedRoom!,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '✅ Đã chuyển "${device.name}" sang phòng "$selectedRoom"',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                          Navigator.pop(context);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('❌ Lỗi: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Chuyển'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _editDevice(BuildContext context, Device device) {
    Navigator.pushNamed(context, '/edit_device', arguments: device).then((
      result,
    ) {
      if (result == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã cập nhật thiết bị "${device.name}"'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  // Kiểm tra kết nối MQTT
  void _checkMqttConnection(BuildContext context, Device device) async {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);

    // Hiển thị dialog đang kiểm tra
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Kiểm tra kết nối'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang kiểm tra kết nối với "${device.name}"...'),
          ],
        ),
      ),
    );

    try {
      final isConnected = await deviceProvider.checkMqttConnection(device);

      if (context.mounted) {
        Navigator.pop(context); // Đóng dialog loading

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  isConnected ? Icons.check_circle : Icons.error,
                  color: isConnected ? Colors.green : Colors.red,
                  size: 32,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isConnected ? 'Kết nối thành công' : 'Kết nối thất bại',
                    style: TextStyle(
                      color: isConnected ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConnected
                      ? 'Thiết bị "${device.name}" đang kết nối bình thường!'
                      : 'Không thể kết nối với thiết bị "${device.name}".',
                  style: TextStyle(fontSize: 16),
                ),
                if (!isConnected) ...[
                  SizedBox(height: 12),
                  Text(
                    'Vui lòng kiểm tra:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Cấu hình MQTT của thiết bị\n'
                    '• ESP32 đã được cấp nguồn và kết nối WiFi\n'
                    '• Mã thiết bị (device code) khớp với ESP32',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: isConnected ? Colors.green : Colors.red,
                ),
                child: Text(
                  'OK',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Đóng dialog loading

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi kiểm tra kết nối: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
