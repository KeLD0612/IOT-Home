import 'package:flutter/material.dart';
import '../../models/user_sensor.dart';
import '../../models/sensor_health.dart';

/// 🌧️ Widget cảm biến mưa - giọt mưa rơi
class RainDropWidget extends StatelessWidget {
  final UserSensor sensor;

  const RainDropWidget({Key? key, required this.sensor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final value = sensor.lastValue as num?;
    final healthInfo = sensor.healthInfo;
    final rainLevel = value?.toDouble() ?? 0.0;

    // Tính mức độ mưa
    final RainIntensity intensity = _getRainIntensity(rainLevel);

    return Container(
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            intensity.skyColor.withOpacity(0.3),
            intensity.skyColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: intensity.color.withOpacity(0.5), width: 2),
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: intensity.color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(intensity.icon, color: intensity.color, size: 24),
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
                  color: intensity.color,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: intensity.color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  intensity.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Giọt mưa rơi
          Expanded(
            child: Stack(
              children: [
                // Giọt mưa
                if (rainLevel > 100) ...[
                  for (int i = 0; i < 8; i++)
                    Positioned(
                      left: 30 + (i * 40.0),
                      top: 10,
                      child: _RainDrop(
                        delay: i * 150,
                        speed: intensity == RainIntensity.heavy ? 400 : 600,
                      ),
                    ),
                ],

                // Icon trung tâm
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        intensity.centerIcon,
                        size: 80,
                        color: intensity.color.withOpacity(0.3),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        sensor.formattedValue,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: intensity.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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

  RainIntensity _getRainIntensity(double level) {
    if (level < 100) {
      return RainIntensity.dry;
    } else if (level < 300) {
      return RainIntensity.light;
    } else if (level < 600) {
      return RainIntensity.moderate;
    } else {
      return RainIntensity.heavy;
    }
  }
}

enum RainIntensity { dry, light, moderate, heavy }

extension RainIntensityExtension on RainIntensity {
  String get label {
    switch (this) {
      case RainIntensity.dry:
        return 'Khô ráo';
      case RainIntensity.light:
        return 'Mưa nhẹ';
      case RainIntensity.moderate:
        return 'Mưa vừa';
      case RainIntensity.heavy:
        return 'Mưa to';
    }
  }

  Color get color {
    switch (this) {
      case RainIntensity.dry:
        return Colors.orange;
      case RainIntensity.light:
        return Colors.blue.shade300;
      case RainIntensity.moderate:
        return Colors.blue.shade600;
      case RainIntensity.heavy:
        return Colors.indigo;
    }
  }

  Color get skyColor {
    switch (this) {
      case RainIntensity.dry:
        return Colors.amber;
      case RainIntensity.light:
        return Colors.grey.shade300;
      case RainIntensity.moderate:
        return Colors.grey.shade500;
      case RainIntensity.heavy:
        return Colors.grey.shade700;
    }
  }

  IconData get icon {
    switch (this) {
      case RainIntensity.dry:
        return Icons.wb_sunny;
      case RainIntensity.light:
        return Icons.grain;
      case RainIntensity.moderate:
        return Icons.water_drop;
      case RainIntensity.heavy:
        return Icons.thunderstorm;
    }
  }

  IconData get centerIcon {
    switch (this) {
      case RainIntensity.dry:
        return Icons.wb_sunny_outlined;
      case RainIntensity.light:
        return Icons.cloud_outlined;
      case RainIntensity.moderate:
        return Icons.cloud_queue;
      case RainIntensity.heavy:
        return Icons.cloud;
    }
  }
}

/// Widget giọt mưa rơi
class _RainDrop extends StatefulWidget {
  final int delay;
  final int speed;

  const _RainDrop({required this.delay, required this.speed});

  @override
  State<_RainDrop> createState() => _RainDropState();
}

class _RainDropState extends State<_RainDrop>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _positionAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.speed),
      vsync: this,
    );

    _positionAnimation = Tween<double>(
      begin: 0.0,
      end: 100.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

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
        return Transform.translate(
          offset: Offset(0, _positionAnimation.value),
          child: Container(
            width: 3,
            height: 15,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue.shade200, Colors.blue.shade400],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      },
    );
  }
}
