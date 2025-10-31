import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sensor_provider.dart';
import '../../models/user_sensor.dart';
import '../../models/sensor_health.dart';
import '../../config/app_colors.dart';
import '../../widgets/sensor_avatar.dart';
import 'add_sensor_screen.dart';
// 🎨 Import custom sensor widgets
import '../../widgets/sensors/temperature_gauge_widget.dart';
import '../../widgets/sensors/humidity_droplet_widget.dart';
import '../../widgets/sensors/soil_moisture_plant_widget.dart';
import '../../widgets/sensors/light_sun_widget.dart';
import '../../widgets/sensors/gas_alert_widget.dart';
import '../../widgets/sensors/motion_detector_widget.dart';
import '../../widgets/sensors/dust_indicator_widget.dart';
import '../../widgets/sensors/rain_drop_widget.dart';
import '../../widgets/sensors/pressure_gauge_widget.dart';
import '../../widgets/sensors/smoke_detector_widget.dart';

class SensorsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cảm biến'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToAddSensor(context),
            tooltip: 'Thêm cảm biến',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.pushNamed(context, '/history'),
            tooltip: 'Lịch sử',
          ),
        ],
      ),
      body: Consumer<SensorProvider>(
        builder: (context, sensorProvider, _) {
          final userSensors = sensorProvider.userSensors;

          if (userSensors.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(seconds: 1));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Weather sensors section
                _buildWeatherSensorsSection(context, sensorProvider),
                const SizedBox(height: 24),

                // All sensors section
                _buildAllSensorsSection(context, sensorProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sensors_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Chưa có cảm biến nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thêm cảm biến để bắt đầu theo dõi',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToAddSensor(context),
            icon: const Icon(Icons.add),
            label: const Text('Thêm cảm biến đầu tiên'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherSensorsSection(
    BuildContext context,
    SensorProvider sensorProvider,
  ) {
    final weatherSensors = sensorProvider.userSensors
        .where((s) => s.isWeatherSensor && s.isActive)
        .toList();

    if (weatherSensors.isEmpty) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.wb_sunny, color: Colors.orange),
            const SizedBox(width: 8),
            const Text(
              'Cảm biến thời tiết',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            if (sensorProvider.hasWeatherSensors())
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Đầy đủ',
                  style: TextStyle(
                    color: Colors.green[800],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        // 📱 MỖI HÀNG 1 CARD - Full width
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: weatherSensors.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _buildSensorCard(context, weatherSensors[index]);
          },
        ),
      ],
    );
  }

  Widget _buildAllSensorsSection(
    BuildContext context,
    SensorProvider sensorProvider,
  ) {
    final allSensors = sensorProvider.userSensors
        .where((s) => s.isActive)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.sensors, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              'Tất cả cảm biến',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 🎨 Dùng custom widgets cho mỗi sensor type
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: allSensors.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return _buildSensorWidget(
              context,
              allSensors[index],
              sensorProvider,
            );
          },
        ),
      ],
    );
  }

  /// 🎨 Factory method - trả về widget custom cho mỗi loại sensor
  Widget _buildSensorWidget(
    BuildContext context,
    UserSensor sensor,
    SensorProvider sensorProvider,
  ) {
    // Kiểm tra sensorTypeId để chọn widget phù hợp
    switch (sensor.sensorTypeId.toLowerCase()) {
      case 'temperature':
        return GestureDetector(
          onTap: () => _showSensorOptions(context, sensor),
          child: TemperatureGaugeWidget(sensor: sensor),
        );

      case 'humidity':
        return GestureDetector(
          onTap: () => _showSensorOptions(context, sensor),
          child: HumidityDropletWidget(sensor: sensor),
        );

      case 'soil_moisture':
        return GestureDetector(
          onTap: () => _showSensorOptions(context, sensor),
          child: SoilMoisturePlantWidget(sensor: sensor),
        );

      case 'light':
        return GestureDetector(
          onTap: () => _showSensorOptions(context, sensor),
          child: LightSunWidget(sensor: sensor),
        );

      case 'gas':
      case 'co2':
        return GestureDetector(
          onTap: () => _showSensorOptions(context, sensor),
          child: GasAlertWidget(sensor: sensor),
        );

      case 'smoke':
        return GestureDetector(
          onTap: () => _showSensorOptions(context, sensor),
          child: SmokeDetectorWidget(sensor: sensor),
        );

      case 'motion':
        return GestureDetector(
          onTap: () => _showSensorOptions(context, sensor),
          child: MotionDetectorWidget(sensor: sensor),
        );

      case 'dust':
        return GestureDetector(
          onTap: () => _showSensorOptions(context, sensor),
          child: DustIndicatorWidget(sensor: sensor),
        );

      case 'rain':
        return GestureDetector(
          onTap: () => _showSensorOptions(context, sensor),
          child: RainDropWidget(sensor: sensor),
        );

      case 'pressure':
        return GestureDetector(
          onTap: () => _showSensorOptions(context, sensor),
          child: PressureGaugeWidget(sensor: sensor),
        );

      // Fallback: dùng card cũ cho các sensor không có custom widget
      default:
        return _buildSensorCard(context, sensor);
    }
  }

  Widget _buildSensorCard(BuildContext context, UserSensor sensor) {
    final healthInfo = sensor.healthInfo;

    return Card(
      elevation: 2,
      // 🎨 Border màu theo health level
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: healthInfo.color.withOpacity(0.3), width: 2),
      ),
      child: InkWell(
        onTap: () => _showSensorOptions(context, sensor),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // � Avatar
              SensorAvatar(
                icon: sensor.icon,
                avatarPath: sensor.avatarPath,
                size: 48,
                isActive: true,
              ),
              const SizedBox(width: 16),

              // 📊 Thông tin sensor
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tên sensor
                    Text(
                      sensor.displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // 🩺 Health status
                    if (healthInfo.level != HealthLevel.unknown)
                      Row(
                        children: [
                          Icon(
                            healthInfo.icon,
                            size: 14,
                            color: healthInfo.color,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              healthInfo.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: healthInfo.color,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                    // ⏰ Timestamp
                    if (sensor.lastUpdateAt != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Cập nhật: ${_formatLastUpdate(sensor.lastUpdateAt!)}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],

                    // 💡 Action advice
                    if (healthInfo.actionAdvice != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: healthInfo.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: healthInfo.color.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 14,
                              color: healthInfo.color,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                healthInfo.actionAdvice!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: healthInfo.color,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // 📈 Value (bên phải, to và nổi bật)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    sensor.formattedValue,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: healthInfo.level == HealthLevel.unknown
                          ? AppColors.primary
                          : healthInfo.color,
                    ),
                  ),
                  if (healthInfo.level != HealthLevel.unknown) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: healthInfo.color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        healthInfo.label,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatLastUpdate(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Vừa xong';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inDays < 1) {
      return '${diff.inHours} giờ trước';
    } else {
      return '${diff.inDays} ngày trước';
    }
  }

  Future<void> _navigateToAddSensor(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddSensorScreen()),
    );

    // Refresh nếu đã thêm sensor
    if (result == true && context.mounted) {
      final sensorProvider = Provider.of<SensorProvider>(
        context,
        listen: false,
      );
      // Reload user sensors
      if (sensorProvider.userSensors.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  void _showSensorOptions(BuildContext context, UserSensor sensor) {
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
                SensorAvatar(
                  icon: sensor.icon,
                  avatarPath: sensor.avatarPath,
                  size: 40,
                  isActive: true,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sensor.displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        sensor.sensorType?.name ?? '',
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
                      _editSensor(context, sensor);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Chỉnh sửa'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmDeleteSensor(context, sensor);
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

  void _editSensor(BuildContext context, UserSensor sensor) async {
    final result = await Navigator.pushNamed(
      context,
      '/edit_sensor',
      arguments: sensor,
    );

    // Provider sẽ tự update UI khi có thay đổi
    if (result == true) {
      // Có thể thêm snackbar thông báo ở đây nếu cần
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đã cập nhật cảm biến'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _confirmDeleteSensor(BuildContext context, UserSensor sensor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa cảm biến "${sensor.displayName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteSensor(context, sensor);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSensor(BuildContext context, UserSensor sensor) async {
    try {
      final sensorProvider = Provider.of<SensorProvider>(
        context,
        listen: false,
      );
      await sensorProvider.deleteSensor(sensor.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã xóa cảm biến "${sensor.displayName}"'),
            backgroundColor: Colors.green,
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
