import 'package:flutter/material.dart';
import '../../models/user_sensor.dart';
import '../../models/sensor_health.dart';
import 'dart:math' as math;

/// ☀️ Widget ánh sáng dạng mặt trời
class LightSunWidget extends StatelessWidget {
  final UserSensor sensor;

  const LightSunWidget({Key? key, required this.sensor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final value = sensor.lastValue as num?;
    final healthInfo = sensor.healthInfo;
    final lux = value?.toDouble() ?? 500.0;

    // Tính cường độ sáng (0-100%)
    final intensity = _calculateIntensity(lux);

    return Container(
      height: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _getSkyColor(intensity).withOpacity(0.3),
            _getSkyColor(intensity).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: healthInfo.color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.wb_sunny,
                  color: Colors.orange.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sensor.displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          healthInfo.icon,
                          size: 14,
                          color: healthInfo.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          healthInfo.label,
                          style: TextStyle(
                            fontSize: 12,
                            color: healthInfo.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: healthInfo.color,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: healthInfo.color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  sensor.formattedValue,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Mặt trời + tia sáng
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Tia sáng xung quanh
                  for (int i = 0; i < 12; i++)
                    Transform.rotate(
                      angle: (i * 30) * math.pi / 180,
                      child: Container(
                        width: 4,
                        height: 50 + (intensity * 30 / 100),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              _getSunColor(intensity).withOpacity(0.8),
                              _getSunColor(intensity).withOpacity(0),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                  // Ánh sáng phát ra (glow)
                  Container(
                    width: 90 + (intensity * 20 / 100),
                    height: 90 + (intensity * 20 / 100),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _getSunColor(intensity).withOpacity(0.3),
                          _getSunColor(intensity).withOpacity(0),
                        ],
                      ),
                    ),
                  ),

                  // Mặt trời
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Colors.white, _getSunColor(intensity)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _getSunColor(intensity).withOpacity(0.6),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${intensity.toInt()}%',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: intensity > 70
                                  ? Colors.white
                                  : Colors.orange.shade900,
                            ),
                          ),
                          Text(
                            _getLightLevel(intensity),
                            style: TextStyle(
                              fontSize: 10,
                              color: intensity > 70
                                  ? Colors.white
                                  : Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Description
          if (healthInfo.level != HealthLevel.unknown) ...[
            Text(
              healthInfo.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Advice
          if (healthInfo.actionAdvice != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: healthInfo.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: healthInfo.color.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: healthInfo.color,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      healthInfo.actionAdvice!,
                      style: TextStyle(
                        fontSize: 12,
                        color: healthInfo.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Tính cường độ sáng (0-100%)
  double _calculateIntensity(double lux) {
    // Quy đổi lux sang phần trăm
    // 0 lux = 0%, 1000+ lux = 100%
    return (lux / 1000 * 100).clamp(0, 100);
  }

  /// Màu mặt trời theo cường độ
  Color _getSunColor(double intensity) {
    if (intensity < 20) {
      return Colors.grey.shade400; // Tối
    } else if (intensity < 40) {
      return Colors.yellow.shade600; // Yếu
    } else if (intensity < 70) {
      return Colors.orange.shade400; // Vừa
    } else {
      return Colors.orange.shade600; // Mạnh
    }
  }

  /// Màu bầu trời
  Color _getSkyColor(double intensity) {
    if (intensity < 20) {
      return Colors.blueGrey; // Đêm
    } else if (intensity < 40) {
      return Colors.lightBlue.shade300; // Sáng sớm
    } else {
      return Colors.blue.shade400; // Ban ngày
    }
  }

  /// Mức độ ánh sáng
  String _getLightLevel(double intensity) {
    if (intensity < 20) {
      return 'Tối';
    } else if (intensity < 40) {
      return 'Yếu';
    } else if (intensity < 70) {
      return 'Vừa';
    } else {
      return 'Mạnh';
    }
  }
}
