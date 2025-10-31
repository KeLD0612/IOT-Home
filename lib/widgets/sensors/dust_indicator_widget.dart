import 'package:flutter/material.dart';
import '../../models/user_sensor.dart';
import '../../models/sensor_health.dart';
import 'dart:math' as math;

/// 🌫️ Widget bụi - hạt bay trong không khí
class DustIndicatorWidget extends StatelessWidget {
  final UserSensor sensor;

  const DustIndicatorWidget({Key? key, required this.sensor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final value = sensor.lastValue as num?;
    final healthInfo = sensor.healthInfo;
    final dustValue = value?.toDouble() ?? 0.0;

    // Tính AQI (Air Quality Index)
    final AirQuality airQuality = _getAirQuality(dustValue);

    return Container(
      height: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            airQuality.color.withOpacity(0.1),
            airQuality.color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: airQuality.color.withOpacity(0.5), width: 2),
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: airQuality.color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.air, color: airQuality.color, size: 24),
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

          // Hạt bụi + AQI
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Hạt bụi bay
                if (dustValue > 50) ...[
                  for (int i = 0; i < 8; i++)
                    Positioned(
                      left: 20 + math.Random().nextDouble() * 160,
                      top: 10 + math.Random().nextDouble() * 80,
                      child: _DustParticle(
                        delay: i * 300,
                        color: airQuality.color.withOpacity(0.4),
                        size: 4 + math.Random().nextDouble() * 8,
                      ),
                    ),
                ],

                // Vòng tròn AQI
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Vòng ngoài
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 8,
                            ),
                          ),
                        ),
                        // Vòng tiến độ
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: CircularProgressIndicator(
                            value: (dustValue / 500).clamp(0.0, 1.0),
                            strokeWidth: 8,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              airQuality.color,
                            ),
                          ),
                        ),
                        // Số ở giữa
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${dustValue.toInt()}',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: airQuality.color,
                              ),
                            ),
                            Text(
                              'µg/m³',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: airQuality.color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        airQuality.label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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

  AirQuality _getAirQuality(double dust) {
    // PM2.5/PM10 standards
    if (dust < 50) {
      return AirQuality.good;
    } else if (dust < 100) {
      return AirQuality.moderate;
    } else if (dust < 200) {
      return AirQuality.unhealthy;
    } else if (dust < 300) {
      return AirQuality.veryUnhealthy;
    } else {
      return AirQuality.hazardous;
    }
  }
}

enum AirQuality { good, moderate, unhealthy, veryUnhealthy, hazardous }

extension AirQualityExtension on AirQuality {
  String get label {
    switch (this) {
      case AirQuality.good:
        return 'Tốt';
      case AirQuality.moderate:
        return 'Trung bình';
      case AirQuality.unhealthy:
        return 'Không tốt';
      case AirQuality.veryUnhealthy:
        return 'Xấu';
      case AirQuality.hazardous:
        return 'Nguy hại';
    }
  }

  Color get color {
    switch (this) {
      case AirQuality.good:
        return Colors.green;
      case AirQuality.moderate:
        return Colors.yellow.shade700;
      case AirQuality.unhealthy:
        return Colors.orange;
      case AirQuality.veryUnhealthy:
        return Colors.red;
      case AirQuality.hazardous:
        return Colors.purple.shade900;
    }
  }
}

/// Widget hạt bụi bay
class _DustParticle extends StatefulWidget {
  final int delay;
  final Color color;
  final double size;

  const _DustParticle({
    required this.delay,
    required this.color,
    required this.size,
  });

  @override
  State<_DustParticle> createState() => _DustParticleState();
}

class _DustParticleState extends State<_DustParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _positionAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset((math.Random().nextDouble() - 0.5) * 50, -60),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _fadeAnimation = Tween<double>(begin: 0.8, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

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
          offset: _positionAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}
