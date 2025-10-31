import 'package:flutter/material.dart';
import '../../../models/device_model.dart';
import '../../../config/app_colors.dart';

class DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback? onToggle;
  final Function(int)? onValueChange;
  final VoidCallback? onTap;

  const DeviceCard({
    Key? key,
    required this.device,
    this.onToggle,
    this.onValueChange,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icon
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getDeviceColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      device.icon ?? _getDefaultIcon(),
                      style: TextStyle(fontSize: 24),
                    ),
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

                  // Control
                  if (device.isRelay && onToggle != null)
                    Switch(
                      value: device.state,
                      onChanged: (_) => onToggle?.call(),
                      activeColor: AppColors.primary,
                    ),
                ],
              ),

              // Servo Slider
              if (device.isServo && onValueChange != null) ...[
                SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      '0°',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Expanded(
                      child: Slider(
                        value: (device.value ?? 0).toDouble(),
                        min: 0,
                        max: 180,
                        divisions: 180,
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
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getDeviceColor() {
    if (device.isRelay && device.state) {
      switch (device.id) {
        case 'pump':
          return AppColors.pumpColor;
        case 'light_living':
        case 'light_yard':
          return AppColors.lightColor;
        case 'ionizer':
          return AppColors.ionizerColor;
        default:
          return AppColors.primary;
      }
    }
    return Colors.grey;
  }

  String _getDefaultIcon() {
    switch (device.id) {
      case 'pump':
        return '💧';
      case 'light_living':
      case 'light_yard':
        return '💡';
      case 'ionizer':
        return '🌬️';
      case 'roof_servo':
        return '🏠';
      case 'gate_servo':
        return '🚪';
      default:
        return '🔌';
    }
  }
}
