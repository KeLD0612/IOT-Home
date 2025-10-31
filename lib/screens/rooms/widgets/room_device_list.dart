import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/device_provider.dart';
import '../../../models/device_model.dart';
import '../../../widgets/device_avatar.dart';
// import '../../devices/device_detail_screen.dart'; // Unused - removed

/// Widget danh sách thiết bị trong phòng - Sử dụng data thực từ DeviceProvider
class RoomDeviceList extends StatelessWidget {
  final String roomId;
  final String roomName;

  const RoomDeviceList({Key? key, required this.roomId, required this.roomName})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceProvider>(
      builder: (context, deviceProvider, _) {
        // Lấy devices thật từ provider theo phòng
        final devices = _getDevicesFromProvider(deviceProvider, roomId);

        if (devices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.devices_other, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Không có thiết bị nào trong phòng này',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Phòng: $roomName',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/add_device'),
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm thiết bị'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        print('🔍 DEBUG: Building ListView with ${devices.length} devices');

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: devices.length,
          itemBuilder: (context, index) {
            final device = devices[index];
            print(
              '🔍 DEBUG: Building device $index: ${device.name} (${device.type})',
            );

            // Hiển thị device dựa trên type
            if (device.type == DeviceType.relay) {
              print('🔍 DEBUG: Building relay device: ${device.name}');
              return _buildRelayDevice(context, device, deviceProvider);
            } else if (device.type == DeviceType.servo) {
              print('🔍 DEBUG: Building servo device: ${device.name}');
              return _buildServoDevice(context, device, deviceProvider);
            } else if (device.type == DeviceType.fan) {
              print('🔍 DEBUG: Building fan device: ${device.name}');
              return _buildServoDevice(
                context,
                device,
                deviceProvider,
              ); // Fan sử dụng servo UI
            }

            print('🔍 DEBUG: Unknown device type: ${device.type}');
            return Container(); // fallback
          },
        );
      },
    );
  }

  // Lấy devices từ provider theo phòng - SỬ DỤNG FIELD ROOM THAY VÌ HARD-CODE
  List<Device> _getDevicesFromProvider(DeviceProvider provider, String roomId) {
    final allDevices = provider.devices;

    // Debug: In ra tất cả devices và room của chúng
    print('🔍 DEBUG: All devices and their rooms:');
    for (final device in allDevices) {
      print('  - ${device.name} (${device.id}) -> room: "${device.room}"');
    }

    // Convert roomId từ format "living_room" về tên phòng thực tế để match với device.room
    final roomName = _convertRoomIdToName(roomId);
    print(
      '🔍 DEBUG: Looking for devices in room: "$roomName" (from roomId: "$roomId")',
    );

    // Lấy tất cả devices có room field khớp với roomName
    // Tìm kiếm linh hoạt: exact match hoặc partial match
    final devices = allDevices.where((device) {
      if (device.room == null) return false;

      // Exact match
      if (device.room == roomName) return true;

      // Partial match (case insensitive)
      if (device.room!.toLowerCase().contains(roomName.toLowerCase()) ||
          roomName.toLowerCase().contains(device.room!.toLowerCase())) {
        return true;
      }

      // Match với roomId (trường hợp thiết bị có room = tên thiết bị)
      if (device.room!.toLowerCase() == roomId.toLowerCase()) {
        return true;
      }

      return false;
    }).toList();
    print('🔍 DEBUG: Found ${devices.length} devices in room "$roomName"');

    // Debug: In ra chi tiết thiết bị được tìm thấy
    for (final device in devices) {
      print(
        '  ✅ Found device: ${device.name} (${device.id}) - Type: ${device.type}',
      );
    }

    return devices;
  }

  // Convert roomId từ format "living_room" về tên phòng thực tế
  String _convertRoomIdToName(String roomId) {
    switch (roomId) {
      case 'phòng_khách':
        return 'Phòng khách';
      case 'phòng_ngủ':
        return 'Phòng ngủ';
      case 'bếp':
        return 'Bếp';
      case 'phòng_tắm':
        return 'Phòng tắm';
      case 'sân_vườn':
        return 'Sân vườn';
      case 'living_room':
        return 'Phòng khách';
      case 'bedroom':
        return 'Phòng ngủ';
      case 'kitchen':
        return 'Bếp';
      case 'bathroom':
        return 'Phòng tắm';
      case 'garden':
        return 'Sân vườn';
      default:
        // Fallback: convert từ snake_case về Title Case
        return roomId
            .split('_')
            .map(
              (word) =>
                  word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1),
            )
            .join(' ');
    }
  }

  Widget _buildRelayDevice(
    BuildContext context,
    Device device,
    DeviceProvider provider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: Stack(
          children: [
            DeviceAvatar(
              icon: device.icon ?? '⚡',
              avatarPath: device.avatarPath,
              size: 40,
              isActive: device.state,
            ),
            // Chấm xanh online indicator
            if (provider.isDeviceConnected(device.id))
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          device.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: device.state ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              device.state ? 'Đang bật' : 'Đang tắt',
              style: TextStyle(color: device.state ? Colors.green : Colors.red),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: device.state,
              onChanged: (value) {
                provider.updateDeviceState(device.id, value);
              },
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  Navigator.pushNamed(
                    context,
                    '/edit_device',
                    arguments: device,
                  );
                } else if (value == 'delete') {
                  _showDeleteConfirmation(context, device, provider);
                } else if (value == 'move_room') {
                  _showMoveRoomDialog(context, device, provider);
                } else if (value == 'check_connection') {
                  _checkMqttConnection(context, device, provider);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Sửa thiết bị'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'move_room',
                  child: Row(
                    children: [
                      Icon(Icons.swap_horiz, size: 20),
                      SizedBox(width: 8),
                      Text('Chuyển phòng'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'check_connection',
                  child: Row(
                    children: [
                      Icon(Icons.wifi, size: 20),
                      SizedBox(width: 8),
                      Text('Kiểm tra kết nối'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Xóa thiết bị', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              icon: Icon(Icons.more_vert),
            ),
          ],
        ),
        onTap: () {
          Navigator.pushNamed(context, '/device_detail', arguments: device);
        },
      ),
    );
  }

  Widget _buildServoDevice(
    BuildContext context,
    Device device,
    DeviceProvider provider,
  ) {
    final value = device.value ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/device_detail', arguments: device);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Stack(
                    children: [
                      DeviceAvatar(
                        icon: device.icon ?? '🎚️',
                        avatarPath: device.avatarPath,
                        size: 40,
                        isActive: value > 0,
                      ),
                      // Chấm xanh online indicator
                      if (provider.isDeviceConnected(device.id))
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getServoStatusText(device, value),
                          style: TextStyle(
                            color: Colors.blue[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // On/Off switch cho fan_living
                  if (device.id == 'fan_living')
                    Switch(
                      value: device.state,
                      onChanged: (isOn) {
                        provider.toggleDevice(device.id);
                      },
                    ),
                  // Menu 3 chấm
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.pushNamed(
                          context,
                          '/edit_device',
                          arguments: device,
                        );
                      } else if (value == 'delete') {
                        _showDeleteConfirmation(context, device, provider);
                      } else if (value == 'move_room') {
                        _showMoveRoomDialog(context, device, provider);
                      } else if (value == 'check_connection') {
                        _checkMqttConnection(context, device, provider);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Sửa thiết bị'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'move_room',
                        child: Row(
                          children: [
                            Icon(Icons.swap_horiz, size: 20),
                            SizedBox(width: 8),
                            Text('Chuyển phòng'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'check_connection',
                        child: Row(
                          children: [
                            Icon(Icons.wifi, size: 20),
                            SizedBox(width: 8),
                            Text('Kiểm tra kết nối'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Xóa thiết bị',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                    icon: Icon(Icons.more_vert),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Slider điều khiển
              Row(
                children: [
                  Text(_getSliderLabel(device)),
                  Expanded(
                    child: Slider(
                      value: value.toDouble(),
                      min: 0,
                      max: _getSliderMax(device),
                      divisions: _getSliderDivisions(device),
                      onChanged: device.state || device.id != 'fan_living'
                          ? (newValue) {
                              provider.updateServoValue(
                                device.id,
                                newValue.round(),
                              );
                            }
                          : null, // Disable khi fan tắt
                    ),
                  ),
                  Text(_getSliderValueText(device, value)),
                ],
              ),

              // Preset buttons cho quạt
              if (device.id == 'fan_living') ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPresetButton(
                      provider,
                      device,
                      'Chậm',
                      'low',
                      Colors.green,
                      value == 80,
                    ),
                    _buildPresetButton(
                      provider,
                      device,
                      'Vừa',
                      'medium',
                      Colors.orange,
                      value == 150,
                    ),
                    _buildPresetButton(
                      provider,
                      device,
                      'Nhanh',
                      'high',
                      Colors.red,
                      value == 255,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getServoStatusText(Device device, int value) {
    if (device.type == DeviceType.fan) {
      if (value == 0) return 'Tắt';
      return 'Tốc độ: ${((value / 255) * 100).round()}%';
    }
    return 'Góc: $value°';
  }

  String _getSliderLabel(Device device) {
    return device.type == DeviceType.fan ? 'Tốc độ: ' : 'Góc: ';
  }

  double _getSliderMax(Device device) {
    if (device.type == DeviceType.fan) return 255;
    // For servo: check if it's 360° servo
    return (device.isServo360 == true) ? 360 : 180;
  }

  int _getSliderDivisions(Device device) {
    if (device.type == DeviceType.fan) return 10;
    // For servo: more divisions for 360° servo
    return (device.isServo360 == true) ? 36 : 18;
  }

  String _getSliderValueText(Device device, int value) {
    if (device.type == DeviceType.fan) {
      return '${((value / 255) * 100).round()}%';
    }
    return '$value°';
  }

  Widget _buildPresetButton(
    DeviceProvider provider,
    Device device,
    String label,
    String preset,
    Color color,
    bool isSelected,
  ) {
    return ElevatedButton(
      onPressed: () {
        provider.setFanPreset(device.id, preset);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : color.withOpacity(0.3),
        foregroundColor: isSelected ? Colors.white : color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    Device device,
    DeviceProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa thiết bị "${device.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await provider.removeDevice(device.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? '✅ Đã xóa thiết bị "${device.name}"'
                    : '❌ Không thể xóa thiết bị',
              ),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _showMoveRoomDialog(
    BuildContext context,
    Device device,
    DeviceProvider provider,
  ) {
    final availableRooms = provider.availableRooms;
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
                          await provider.moveDeviceToRoom(
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
                  backgroundColor: Theme.of(context).primaryColor,
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

  void _checkMqttConnection(
    BuildContext context,
    Device device,
    DeviceProvider provider,
  ) async {
    // Hiển thị dialog đang kiểm tra
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Đang kiểm tra kết nối...'),
          ],
        ),
      ),
    );

    try {
      final isConnected = await provider.checkMqttConnection(device);

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
