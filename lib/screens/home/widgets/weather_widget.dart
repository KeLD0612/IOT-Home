import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/sensor_provider.dart';

/// Widget hiển thị thời tiết
class WeatherWidget extends StatelessWidget {
  const WeatherWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SensorProvider>(
      builder: (context, sensorProvider, child) {
        // Kiểm tra user có đủ sensors cho weather widget không
        if (!sensorProvider.hasWeatherSensors()) {
          return _buildNoSensorsWidget(context);
        }

        final temp = sensorProvider.temperature;
        final humidity = sensorProvider.humidity;
        final rain = sensorProvider.rain;

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thời tiết',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Icon thời tiết
                    _buildWeatherIcon(temp, rain),
                    const SizedBox(width: 16),

                    // Thông tin
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nhiệt độ
                          Row(
                            children: [
                              Text(
                                '${temp.toStringAsFixed(1)}°C',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getWeatherDescription(temp, rain),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Độ ẩm
                          Row(
                            children: [
                              Icon(
                                Icons.water_drop,
                                size: 16,
                                color: Colors.blue[400],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Độ ẩm: ${humidity.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeatherIcon(double temp, int rain) {
    IconData icon;
    Color color;

    if (rain == 0) {
      // Có mưa
      icon = Icons.cloud_queue;
      color = Colors.grey;
    } else if (temp > 30) {
      // Nắng nóng
      icon = Icons.wb_sunny;
      color = Colors.orange;
    } else if (temp < 20) {
      // Lạnh
      icon = Icons.ac_unit;
      color = Colors.blue;
    } else {
      // Bình thường
      icon = Icons.wb_cloudy;
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 48, color: color),
    );
  }

  String _getWeatherDescription(double temp, int rain) {
    if (rain == 1) {
      // Fix bug: rain == 1 là có mưa
      return 'Mưa';
    } else if (temp > 35) {
      return 'Nắng nóng';
    } else if (temp > 30) {
      return 'Nóng';
    } else if (temp < 15) {
      return 'Lạnh';
    } else if (temp < 20) {
      return 'Mát';
    } else {
      return 'Dễ chịu';
    }
  }

  /// Widget hiển thị khi chưa có đủ sensors
  Widget _buildNoSensorsWidget(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thời tiết',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.sensors_off, size: 48, color: Colors.grey[400]),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chưa đủ cảm biến',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cần thêm: Nhiệt độ, Độ ẩm, Cảm biến mưa',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/add_sensor');
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm cảm biến'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
