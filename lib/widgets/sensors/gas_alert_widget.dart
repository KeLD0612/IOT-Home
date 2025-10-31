import 'package:flutter/material.dart';
import '../../models/user_sensor.dart';
import '../../models/sensor_health.dart';
import 'dart:math' as math;

/// ⚠️ Widget khí gas - cảnh báo nguy hiểm
class GasAlertWidget extends StatelessWidget {
  final UserSensor sensor;

  const GasAlertWidget({Key? key, required this.sensor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final value = sensor.lastValue as num?;
    final healthInfo = sensor.healthInfo;
    final gasPPM = value?.toDouble() ?? 0.0;

    // Tính mức độ nguy hiểm
    final DangerLevel dangerLevel = _getDangerLevel(gasPPM);

    return Container(
      height: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            dangerLevel.color.withOpacity(0.1),
            dangerLevel.color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dangerLevel.color.withOpacity(0.5), width: 2),
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: dangerLevel.color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_outlined,
                  color: dangerLevel.color,
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

          // Icon cảnh báo + khói
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Khói (particles)
                if (gasPPM > 100) ...[
                  for (int i = 0; i < 6; i++)
                    Positioned(
                      left: 50 + (i % 3) * 60 + math.Random().nextDouble() * 20,
                      bottom: 20 + (i ~/ 3) * 40,
                      child: _SmokeParticle(
                        delay: i * 200,
                        color: dangerLevel.color.withOpacity(0.3),
                      ),
                    ),
                ],

                // Icon cảnh báo trung tâm
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: dangerLevel.color.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: dangerLevel.color, width: 3),
                  ),
                  child: Icon(
                    dangerLevel.icon,
                    size: 40,
                    color: dangerLevel.color,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Thanh mức độ nguy hiểm
          Column(
            children: [
              Row(
                children: [
                  Icon(Icons.speed, size: 16, color: dangerLevel.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: (gasPPM / 1000).clamp(0.0, 1.0),
                        minHeight: 12,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          dangerLevel.color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${gasPPM.toInt()} ppm',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: dangerLevel.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'An toàn',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  Text(
                    'Cảnh báo',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  Text(
                    'Nguy hiểm',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
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

  DangerLevel _getDangerLevel(double ppm) {
    if (ppm < 100) {
      return DangerLevel.safe;
    } else if (ppm < 300) {
      return DangerLevel.moderate;
    } else if (ppm < 500) {
      return DangerLevel.warning;
    } else {
      return DangerLevel.danger;
    }
  }
}

enum DangerLevel { safe, moderate, warning, danger }

extension DangerLevelExtension on DangerLevel {
  String get label {
    switch (this) {
      case DangerLevel.safe:
        return 'An toàn';
      case DangerLevel.moderate:
        return 'Chú ý';
      case DangerLevel.warning:
        return 'Cảnh báo';
      case DangerLevel.danger:
        return 'NGUY HIỂM!';
    }
  }

  Color get color {
    switch (this) {
      case DangerLevel.safe:
        return Colors.green;
      case DangerLevel.moderate:
        return Colors.blue;
      case DangerLevel.warning:
        return Colors.orange;
      case DangerLevel.danger:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case DangerLevel.safe:
        return Icons.check_circle_outline;
      case DangerLevel.moderate:
        return Icons.info_outline;
      case DangerLevel.warning:
        return Icons.warning_amber_rounded;
      case DangerLevel.danger:
        return Icons.dangerous;
    }
  }
}

/// Widget khói bay lên
class _SmokeParticle extends StatefulWidget {
  final int delay;
  final Color color;

  const _SmokeParticle({required this.delay, required this.color});

  @override
  State<_SmokeParticle> createState() => _SmokeParticleState();
}

class _SmokeParticleState extends State<_SmokeParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _sizeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.8,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _sizeAnimation = Tween<double>(
      begin: 10.0,
      end: 30.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            width: _sizeAnimation.value,
            height: _sizeAnimation.value,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
