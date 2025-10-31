import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/device_model.dart';
import '../../providers/device_provider.dart';
import '../../widgets/device_avatar.dart';
import '../../config/app_colors.dart';
import 'device_mqtt_config_screen.dart';

/// Màn hình chi tiết thiết bị
class DeviceDetailScreen extends StatelessWidget {
  final Device device;

  const DeviceDetailScreen({Key? key, required this.device}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceProvider>(
      builder: (context, provider, child) {
        // Lấy device mới nhất từ provider
        final currentDevice = provider.getDeviceById(device.id) ?? device;

        return Scaffold(
          appBar: AppBar(
            title: Text(currentDevice.name),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.wifi),
                onPressed: () => _openMqttConfig(context),
                tooltip: 'Cấu hình MQTT',
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => _showDeviceSettings(context),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDeleteDevice(context),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Avatar Section
                Center(
                  child: DeviceAvatarLarge(
                    icon: currentDevice.icon,
                    avatarPath: currentDevice.avatarPath,
                    isActive: currentDevice.state,
                    onTap: () => _changeAvatar(context, provider),
                  ),
                ),

                const SizedBox(height: 20),

                // Device Info Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Device Name với nút edit
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                currentDevice.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _showEditNameDialog(
                                context,
                                provider,
                                currentDevice,
                              ),
                              icon: const Icon(Icons.edit, size: 20),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.grey.withOpacity(0.1),
                                foregroundColor: AppColors.primary,
                                padding: const EdgeInsets.all(4),
                                minimumSize: const Size(32, 32),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Device Status
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: currentDevice.state
                                ? Colors.green.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: currentDevice.state
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                          ),
                          child: Text(
                            currentDevice.state ? 'ĐANG BẬT' : 'TẮT',
                            style: TextStyle(
                              color: currentDevice.state
                                  ? Colors.green
                                  : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Device Type Info
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Loại thiết bị:',
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(
                              _getDeviceTypeText(currentDevice.type),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        if (currentDevice.type == DeviceType.servo) ...[
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 20),

                          // Servo Control
                          Text(
                            'Điều khiển: ${currentDevice.value ?? 0}°',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Nút điều khiển nhanh Servo
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              _servoPresetButton(
                                context,
                                provider,
                                currentDevice,
                                'Tắt',
                                0,
                              ),
                              _servoPresetButton(
                                context,
                                provider,
                                currentDevice,
                                '45°',
                                45,
                              ),
                              _servoPresetButton(
                                context,
                                provider,
                                currentDevice,
                                '90°',
                                90,
                              ),
                              _servoPresetButton(
                                context,
                                provider,
                                currentDevice,
                                '135°',
                                135,
                              ),
                              _servoPresetButton(
                                context,
                                provider,
                                currentDevice,
                                '180°',
                                180,
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          Slider(
                            value: (currentDevice.value ?? 0).toDouble(),
                            min: 0,
                            max: (currentDevice.isServo360 == true)
                                ? 360.0
                                : 180.0,
                            divisions: (currentDevice.isServo360 == true)
                                ? 360
                                : 180,
                            activeColor: AppColors.primary,
                            onChanged: (value) {
                              provider.updateServoValue(
                                currentDevice.id,
                                value.toInt(),
                              );
                            },
                          ),
                        ],

                        if (currentDevice.type == DeviceType.fan) ...[
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 20),

                          // Fan Control
                          Text(
                            'Tốc độ quạt: ${_getFanSpeedLabel(currentDevice.value ?? 0)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Nút điều khiển nhanh Fan
                          Row(
                            children: [
                              Expanded(
                                child: _fanSpeedButton(
                                  context,
                                  provider,
                                  currentDevice,
                                  'Tắt',
                                  0,
                                  Colors.red,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _fanSpeedButton(
                                  context,
                                  provider,
                                  currentDevice,
                                  'Nhẹ',
                                  85,
                                  Colors.green,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _fanSpeedButton(
                                  context,
                                  provider,
                                  currentDevice,
                                  'Khá',
                                  170,
                                  Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _fanSpeedButton(
                                  context,
                                  provider,
                                  currentDevice,
                                  'Mạnh',
                                  255,
                                  Colors.blue,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          Slider(
                            value: (currentDevice.value ?? 0).toDouble(),
                            min: 0,
                            max: 255,
                            divisions: 25,
                            activeColor: AppColors.primary,
                            onChanged: (value) {
                              provider.updateServoValue(
                                currentDevice.id,
                                value.toInt(),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Control Buttons
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text(
                          'Điều khiển',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),

                        if (currentDevice.type == DeviceType.relay) ...[
                          // On/Off Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                provider.updateDeviceState(
                                  currentDevice.id,
                                  !currentDevice.state,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: currentDevice.state
                                    ? Colors.red
                                    : AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                currentDevice.state ? 'TẮT' : 'BẬT',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),

                        // Rename Device Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: () => _showEditNameDialog(
                              context,
                              provider,
                              currentDevice,
                            ),
                            icon: const Icon(Icons.edit),
                            label: const Text('Đổi tên thiết bị'),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Change Avatar Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: () => _changeAvatar(context, provider),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Đổi ảnh thiết bị'),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                        // Remove Avatar Button (nếu có avatar)
                        if (currentDevice.avatarPath != null) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: () => _removeAvatar(context, provider),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Xóa ảnh thiết bị'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getDeviceTypeText(DeviceType type) {
    switch (type) {
      case DeviceType.relay:
        return 'Relay (Bật/Tắt)';
      case DeviceType.servo:
        return 'Servo (Điều chỉnh)';
      case DeviceType.fan: // 🌪️ THÊM CASE CHO FAN
        return 'Quạt (Tốc độ)';
    }
  }

  void _changeAvatar(BuildContext context, DeviceProvider provider) async {
    await provider.pickAndUpdateAvatar(context, device.id);
  }

  void _removeAvatar(BuildContext context, DeviceProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa ảnh thiết bị'),
        content: const Text('Bạn có chắc muốn xóa ảnh này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              provider.removeDeviceAvatar(device.id);
              Navigator.pop(context);
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showDeviceSettings(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cài đặt thiết bị - Sẽ phát triển sau')),
    );
  }

  void _showEditNameDialog(
    BuildContext context,
    DeviceProvider provider,
    Device currentDevice,
  ) {
    final TextEditingController nameController = TextEditingController(
      text: currentDevice.name,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi tên thiết bị'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Tên thiết bị',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.devices),
              ),
              autofocus: true,
              maxLength: 50,
            ),
            const SizedBox(height: 8),
            Text(
              'Tên thiết bị sẽ hiển thị trong danh sách và điều khiển',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty && newName != currentDevice.name) {
                provider.updateDeviceName(currentDevice.id, newName);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã đổi tên thành "$newName"')),
                );
              } else if (newName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tên thiết bị không được để trống'),
                  ),
                );
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteDevice(BuildContext context) {
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
                _deleteDevice(context);
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

  void _deleteDevice(BuildContext context) async {
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
          Navigator.of(context).pop(); // Quay về danh sách devices
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

  // 🎚️ Helper method cho servo preset button
  Widget _servoPresetButton(
    BuildContext context,
    DeviceProvider provider,
    Device device,
    String label,
    int angle,
  ) {
    final isSelected = (device.value ?? 0) == angle;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        onPressed: () {
          provider.updateServoValue(device.id, angle);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? AppColors.primary : Colors.grey[300],
          foregroundColor: isSelected ? Colors.white : Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  // 🌪️ Helper method cho fan speed button
  Widget _fanSpeedButton(
    BuildContext context,
    DeviceProvider provider,
    Device device,
    String label,
    int speed,
    Color color,
  ) {
    final isSelected = (device.value ?? 0) == speed;
    return ElevatedButton(
      onPressed: () {
        provider.updateServoValue(
          device.id,
          speed,
        ); // Dùng chung updateServoValue
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  // 🌪️ Helper method để hiển thị label tốc độ fan
  String _getFanSpeedLabel(int speed) {
    if (speed == 0) return 'Tắt (0%)';
    if (speed <= 85) return 'Nhẹ (${((speed / 255) * 100).round()}%)';
    if (speed <= 170) return 'Khá (${((speed / 255) * 100).round()}%)';
    return 'Mạnh (${((speed / 255) * 100).round()}%)';
  }

  // 📡 Mở màn hình cấu hình MQTT
  void _openMqttConfig(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeviceMqttConfigScreen(device: device),
      ),
    );
  }
}
