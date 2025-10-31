import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/device_model.dart';
import '../../../config/app_colors.dart';
import '../../../widgets/device_avatar.dart';
import '../../../providers/device_provider.dart';

class DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback? onToggle;
  final Function(int)? onValueChange;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onPin; // 📌 THÊM CALLBACK PIN
  final VoidCallback? onEdit; // ✏️ THÊM CALLBACK EDIT
  final VoidCallback? onDelete; // 🗑️ THÊM CALLBACK DELETE
  final VoidCallback? onMoveRoom; // 🏠 THÊM CALLBACK CHUYỂN PHÒNG
  final VoidCallback? onCheckConnection; // 🔗 THÊM CALLBACK KIỂM TRA KẾT NỐI

  const DeviceCard({
    Key? key,
    required this.device,
    this.onToggle,
    this.onValueChange,
    this.onTap,
    this.onLongPress,
    this.onPin, // 📌 THÊM PARAMETER PIN
    this.onEdit, // ✏️ THÊM PARAMETER EDIT
    this.onDelete, // 🗑️ THÊM PARAMETER DELETE
    this.onMoveRoom, // 🏠 THÊM PARAMETER CHUYỂN PHÒNG
    this.onCheckConnection, // 🔗 THÊM PARAMETER KIỂM TRA KẾT NỐI
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // DeviceAvatar thay cho icon cũ với online indicator
                  Consumer<DeviceProvider>(
                    builder: (context, deviceProvider, child) {
                      final isOnline = deviceProvider.isDeviceConnected(
                        device.id,
                      );
                      return Stack(
                        children: [
                          DeviceAvatar(
                            icon: device.icon ?? _getDefaultIcon(),
                            avatarPath: device.avatarPath,
                            size: 48,
                            isActive: device.state,
                          ),
                          // Chấm xanh online indicator (như Messenger)
                          if (isOnline)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  SizedBox(width: 16),

                  // Name and Status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          device.isRelay
                              ? (device.state ? 'Đang bật' : 'Đang tắt')
                              : '${device.value}°',
                          style: TextStyle(
                            fontSize: 12,
                            color: device.state
                                ? AppColors.success
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Control Section
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pin Button
                      if (onPin != null)
                        IconButton(
                          onPressed: onPin,
                          icon: Icon(
                            device.isPinned
                                ? Icons.push_pin
                                : Icons.push_pin_outlined,
                            color: device.isPinned
                                ? AppColors.primary
                                : Colors.grey,
                            size: 20,
                          ),
                          constraints: BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          padding: EdgeInsets.all(4),
                        ),

                      // Menu 3 chấm
                      if (onEdit != null ||
                          onDelete != null ||
                          onMoveRoom != null ||
                          onCheckConnection != null)
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit' && onEdit != null) {
                              onEdit!();
                            } else if (value == 'delete' && onDelete != null) {
                              onDelete!();
                            } else if (value == 'move_room' &&
                                onMoveRoom != null) {
                              onMoveRoom!();
                            } else if (value == 'check_connection' &&
                                onCheckConnection != null) {
                              onCheckConnection!();
                            }
                          },
                          itemBuilder: (context) => [
                            if (onEdit != null)
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
                            if (onMoveRoom != null)
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
                            if (onCheckConnection != null)
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
                            if (onDelete != null)
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Xóa thiết bị',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                          icon: Icon(
                            Icons.more_vert,
                            color: Colors.grey,
                            size: 20,
                          ),
                          constraints: BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          padding: EdgeInsets.all(4),
                        ),

                      // Device Control
                      if (device.isRelay && onToggle != null)
                        Switch(
                          value: device.state,
                          onChanged: (_) => onToggle?.call(),
                          activeColor: AppColors.primary,
                        ),
                    ],
                  ),
                ],
              ),

              // Servo Controls
              if (device.isServo && onValueChange != null) ...[
                SizedBox(height: 16),
                // Servo Slider
                Row(
                  children: [
                    Text(
                      '0°',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Expanded(
                      child: Slider(
                        value: ((device.value ?? 0).toDouble()).clamp(
                          0.0,
                          (device.isServo360 == true) ? 360.0 : 180.0,
                        ),
                        min: 0,
                        max: (device.isServo360 == true) ? 360 : 180,
                        divisions: (device.isServo360 == true) ? 360 : 180,
                        label: '${device.value}°',
                        onChanged: (value) =>
                            onValueChange?.call(value.toInt()),
                        activeColor: AppColors.primary,
                      ),
                    ),
                    Text(
                      '180°',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                // Servo Preset Buttons
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: (device.isServo360 == true)
                        ? [0, 90, 180, 270, 360].map((angle) {
                            return Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: SizedBox(
                                height: 28,
                                child: ElevatedButton(
                                  onPressed: () {
                                    print(
                                      'Servo preset button pressed: ${angle}°',
                                    );
                                    onValueChange?.call(angle);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: (device.value == angle)
                                        ? AppColors.primary
                                        : Colors.grey[200],
                                    foregroundColor: (device.value == angle)
                                        ? Colors.white
                                        : Colors.black87,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    minimumSize: Size(0, 28),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    '${angle}°',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                            );
                          }).toList()
                        : [0, 45, 90, 135, 180].map((angle) {
                            return Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: SizedBox(
                                height: 28,
                                child: ElevatedButton(
                                  onPressed: () {
                                    print(
                                      'Servo preset button pressed: ${angle}°',
                                    );
                                    onValueChange?.call(angle);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: (device.value == angle)
                                        ? AppColors.primary
                                        : Colors.grey[200],
                                    foregroundColor: (device.value == angle)
                                        ? Colors.white
                                        : Colors.black87,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    minimumSize: Size(0, 28),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    '${angle}°',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                  ),
                ),
              ],

              // Fan Controls
              if (device.isFan && onValueChange != null) ...[
                SizedBox(height: 16),
                // Fan Speed Slider
                Row(
                  children: [
                    Text(
                      'Tắt',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Expanded(
                      child: Slider(
                        value: ((device.value ?? 0).toDouble()).clamp(
                          0.0,
                          100.0,
                        ),
                        min: 0,
                        max: 100,
                        divisions: 100,
                        label: '${device.value}%',
                        onChanged: (value) =>
                            onValueChange?.call(value.toInt()),
                        activeColor: _getFanColor(device.value ?? 0),
                      ),
                    ),
                    Text(
                      'Mạnh',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                // Fan Preset Buttons
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFanPresetButton('Tắt', 0, Colors.grey),
                      _buildFanPresetButton('Nhẹ', 33, Colors.green),
                      _buildFanPresetButton('Khá', 67, Colors.orange),
                      _buildFanPresetButton('Mạnh', 100, Colors.red),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Color _getDeviceColor() { // Unused method - removed
  //   if (device.isRelay && device.state) {
  //     switch (device.id) {
  //       case 'pump':
  //         return AppColors.pumpColor;
  //       case 'light_living':
  //       case 'light_yard':
  //         return AppColors.lightColor;
  //       case 'mist_maker':
  //         return AppColors.mistMakerColor;
  //       default:
  //         return AppColors.primary;
  //     }
  //   }
  //   return Colors.grey;
  // }

  String _getDefaultIcon() {
    switch (device.id) {
      case 'pump':
        return '💧';
      case 'light_living':
      case 'light_yard':
        return '💡';
      case 'mist_maker':
        return '💨';
      case 'roof_servo':
        return '🏠';
      case 'gate_servo':
        return '🚪';
      default:
        return '🔌';
    }
  }

  Color _getFanColor(int value) {
    if (value == 0) return Colors.grey;
    if (value <= 33) return Colors.green;
    if (value <= 67) return Colors.orange;
    return Colors.red;
  }

  Widget _buildFanPresetButton(String label, int value, Color color) {
    bool isSelected = (device.value == value);
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: SizedBox(
        height: 28,
        child: ElevatedButton(
          onPressed: () {
            print('Fan preset button pressed: $label -> $value');
            onValueChange?.call(value);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? color : Colors.grey[200],
            foregroundColor: isSelected ? Colors.white : Colors.black87,
            padding: EdgeInsets.symmetric(horizontal: 12),
            minimumSize: Size(0, 28),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}
