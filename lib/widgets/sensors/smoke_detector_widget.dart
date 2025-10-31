import 'package:flutter/material.dart';
import '../../models/user_sensor.dart';
import '../../models/sensor_health.dart';

/// 💨 Widget cảm biến khói - phát hiện cháy
class SmokeDetectorWidget extends StatelessWidget {
  final UserSensor sensor;

  const SmokeDetectorWidget({Key? key, required this.sensor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final value = sensor.lastValue as num?;
    final healthInfo = sensor.healthInfo;
    final smokeLevel = value?.toDouble() ?? 0.0;

    final bool hasSmoke = smokeLevel > 100;
    final DangerLevel level = _getDangerLevel(smokeLevel);

    return Container(
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: hasSmoke
              ? [Colors.deepOrange.shade50, Colors.red.shade50]
              : [Colors.green.shade50, Colors.blue.shade50],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: level.color.withOpacity(0.5), width: 2),
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: level.color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasSmoke ? Icons.smoke_free : Icons.done_all,
                  color: level.color,
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
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: level.color,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: level.color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(level.icon, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      level.label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Icon + giá trị
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: level.color.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: level.color, width: 3),
                    ),
                    child: Icon(
                      hasSmoke
                          ? Icons.local_fire_department
                          : Icons.check_circle,
                      size: 50,
                      color: level.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    sensor.formattedValue,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: level.color,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Description
          if (healthInfo.level != HealthLevel.unknown) ...[
            const SizedBox(height: 12),
            Text(
              healthInfo.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          // Advice
          if (healthInfo.actionAdvice != null) ...[
            const SizedBox(height: 8),
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

  DangerLevel _getDangerLevel(double level) {
    if (level < 100) {
      return DangerLevel.safe;
    } else if (level < 300) {
      return DangerLevel.warning;
    } else {
      return DangerLevel.danger;
    }
  }
}

enum DangerLevel { safe, warning, danger }

extension DangerLevelExtension on DangerLevel {
  String get label {
    switch (this) {
      case DangerLevel.safe:
        return 'AN TOÀN';
      case DangerLevel.warning:
        return 'CẢNH BÁO';
      case DangerLevel.danger:
        return 'NGUY HIỂM';
    }
  }

  Color get color {
    switch (this) {
      case DangerLevel.safe:
        return Colors.green;
      case DangerLevel.warning:
        return Colors.orange;
      case DangerLevel.danger:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case DangerLevel.safe:
        return Icons.check_circle;
      case DangerLevel.warning:
        return Icons.warning;
      case DangerLevel.danger:
        return Icons.dangerous;
    }
  }
}
