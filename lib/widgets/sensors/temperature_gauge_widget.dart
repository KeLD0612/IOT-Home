import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/user_sensor.dart';
import '../../models/sensor_health.dart';

/// 🌡️ Widget nhiệt độ dạng đồng hồ kim với gradient màu
class TemperatureGaugeWidget extends StatelessWidget {
  final UserSensor sensor;

  const TemperatureGaugeWidget({Key? key, required this.sensor})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final value = sensor.lastValue as num?;
    final healthInfo = sensor.healthInfo;

    // Range nhiệt độ: -10 đến 60°C
    final minTemp = -10.0;
    final maxTemp = 60.0;
    final currentTemp = value?.toDouble() ?? 25.0;

    // Tính góc cho kim (từ -45° đến 225° = 270° total)
    final normalizedValue = ((currentTemp - minTemp) / (maxTemp - minTemp))
        .clamp(0.0, 1.0);
    final angle = -45 + (270 * normalizedValue);

    return Container(
      height: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            healthInfo.color.withOpacity(0.1),
            healthInfo.color.withOpacity(0.05),
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
                  color: healthInfo.color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.thermostat,
                  color: healthInfo.color,
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
              // Badge nhiệt độ
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
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Gauge (đồng hồ kim)
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background arc (vòng cung nền)
                CustomPaint(
                  size: const Size(150, 150),
                  painter: _GaugeBackgroundPainter(),
                ),

                // Colored arc (vòng cung màu theo giá trị)
                CustomPaint(
                  size: const Size(150, 150),
                  painter: _GaugeArcPainter(
                    value: normalizedValue,
                    color: healthInfo.color,
                  ),
                ),

                // Needle (kim chỉ)
                CustomPaint(
                  size: const Size(150, 150),
                  painter: _GaugeNeedlePainter(
                    angle: angle,
                    color: healthInfo.color,
                  ),
                ),

                // Center dot
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: healthInfo.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: healthInfo.color.withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),

                // Temperature markers
                ..._buildMarkers(minTemp, maxTemp),
              ],
            ),
          ),

          // Description & Advice
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

  /// Tạo các vạch chia độ trên đồng hồ
  List<Widget> _buildMarkers(double min, double max) {
    final markers = <Widget>[];
    final temps = [min, (min + max) / 2, max]; // -10, 25, 60
    final angles = [-45.0, 90.0, 225.0]; // Góc tương ứng

    for (int i = 0; i < temps.length; i++) {
      final angleRad = angles[i] * pi / 180;
      final radius = 65.0;
      final x = radius * cos(angleRad);
      final y = radius * sin(angleRad);

      markers.add(
        Positioned(
          left: 75 + x - 15,
          top: 75 + y - 10,
          child: Text(
            '${temps[i].toInt()}°',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }

    return markers;
  }
}

/// Painter cho nền gauge (vòng cung xám)
class _GaugeBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 10;

    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Vẽ vòng cung từ -45° đến 225° (270° total)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -45 * pi / 180,
      270 * pi / 180,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter cho vòng cung màu theo giá trị
class _GaugeArcPainter extends CustomPainter {
  final double value; // 0.0 to 1.0
  final Color color;

  _GaugeArcPainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 10;

    // Gradient từ xanh lạnh → đỏ nóng
    final gradient = SweepGradient(
      startAngle: -45 * pi / 180,
      endAngle: 225 * pi / 180,
      colors: [
        Colors.blue,
        Colors.cyan,
        Colors.green,
        Colors.yellow,
        Colors.orange,
        Colors.red,
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Vẽ vòng cung theo giá trị
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -45 * pi / 180,
      270 * pi / 180 * value,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_GaugeArcPainter oldDelegate) =>
      oldDelegate.value != value;
}

/// Painter cho kim chỉ
class _GaugeNeedlePainter extends CustomPainter {
  final double angle; // Độ (degrees)
  final Color color;

  _GaugeNeedlePainter({required this.angle, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final angleRad = angle * pi / 180;
    final needleLength = min(size.width, size.height) / 2 - 20;

    final endPoint = Offset(
      center.dx + needleLength * cos(angleRad),
      center.dy + needleLength * sin(angleRad),
    );

    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Vẽ kim
    canvas.drawLine(center, endPoint, paint);

    // Vẽ shadow cho kim
    final shadowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawLine(center, endPoint, shadowPaint);
  }

  @override
  bool shouldRepaint(_GaugeNeedlePainter oldDelegate) =>
      oldDelegate.angle != angle;
}
