import 'package:flutter/material.dart';
import '../../models/user_sensor.dart';
import '../../models/sensor_health.dart';

/// 💧 Widget độ ẩm dạng giọt nước đổ đầy
class HumidityDropletWidget extends StatelessWidget {
  final UserSensor sensor;

  const HumidityDropletWidget({Key? key, required this.sensor})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final value = sensor.lastValue as num?;
    final healthInfo = sensor.healthInfo;
    final humidity = value?.toDouble() ?? 50.0;
    final percentage = (humidity / 100).clamp(0.0, 1.0);

    return Container(
      height: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade50, Colors.cyan.shade50],
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
                  color: Colors.blue.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.water_drop,
                  color: Colors.blue.shade700,
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
              // Badge
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

          const SizedBox(height: 20),

          // Giọt nước + thanh tiến độ
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Giọt nước lớn
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    // Giọt nước outline
                    CustomPaint(
                      size: const Size(100, 120),
                      painter: _DropletOutlinePainter(
                        color: Colors.blue.shade200,
                      ),
                    ),
                    // Giọt nước đổ đầy
                    ClipPath(
                      clipper: _DropletClipper(),
                      child: Container(
                        width: 100,
                        height: 120,
                        alignment: Alignment.bottomCenter,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                          height: 120 * percentage,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                _getHumidityColor(humidity).withOpacity(0.7),
                                _getHumidityColor(humidity),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Phần trăm ở giữa giọt nước
                    Positioned(
                      top: 40,
                      child: Text(
                        '${humidity.toInt()}%',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: percentage > 0.5
                              ? Colors.white
                              : Colors.blue.shade900,
                          shadows: percentage > 0.5
                              ? [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ],
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

  /// Màu theo độ ẩm
  Color _getHumidityColor(double humidity) {
    if (humidity < 30) {
      return Colors.orange; // Khô
    } else if (humidity < 60) {
      return Colors.blue; // Bình thường
    } else if (humidity < 80) {
      return Colors.cyan; // Ẩm
    } else {
      return Colors.blue.shade900; // Rất ẩm
    }
  }
}

/// Custom clipper để tạo hình giọt nước
class _DropletClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    // Vẽ hình giọt nước
    path.moveTo(size.width / 2, 0); // Đỉnh

    // Cong bên trái
    path.quadraticBezierTo(
      size.width * 0.2,
      size.height * 0.3,
      size.width * 0.15,
      size.height * 0.6,
    );

    // Đáy tròn
    path.quadraticBezierTo(
      size.width * 0.15,
      size.height * 0.85,
      size.width / 2,
      size.height,
    );

    path.quadraticBezierTo(
      size.width * 0.85,
      size.height * 0.85,
      size.width * 0.85,
      size.height * 0.6,
    );

    // Cong bên phải
    path.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.3,
      size.width / 2,
      0,
    );

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Painter vẽ viền giọt nước
class _DropletOutlinePainter extends CustomPainter {
  final Color color;

  _DropletOutlinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();

    path.moveTo(size.width / 2, 0);
    path.quadraticBezierTo(
      size.width * 0.2,
      size.height * 0.3,
      size.width * 0.15,
      size.height * 0.6,
    );
    path.quadraticBezierTo(
      size.width * 0.15,
      size.height * 0.85,
      size.width / 2,
      size.height,
    );
    path.quadraticBezierTo(
      size.width * 0.85,
      size.height * 0.85,
      size.width * 0.85,
      size.height * 0.6,
    );
    path.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.3,
      size.width / 2,
      0,
    );
    path.close();

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
