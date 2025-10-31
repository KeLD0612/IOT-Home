import 'package:flutter/material.dart';
import '../../models/user_sensor.dart';
import '../../models/sensor_health.dart';

/// 🌱 Widget độ ẩm đất dạng cây cối
class SoilMoisturePlantWidget extends StatelessWidget {
  final UserSensor sensor;

  const SoilMoisturePlantWidget({Key? key, required this.sensor})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final value = sensor.lastValue as num?;
    final healthInfo = sensor.healthInfo;
    final moisture = value?.toDouble() ?? 50.0;

    // Tính trạng thái cây
    final PlantState plantState = _getPlantState(moisture);

    return Container(
      height: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.brown.shade50, Colors.green.shade50],
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
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.grass,
                  color: Colors.green.shade700,
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
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Cây + đất
          Expanded(
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Đất (nền)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _getSoilColor(moisture).withOpacity(0.7),
                          _getSoilColor(moisture),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(100),
                        topRight: Radius.circular(100),
                      ),
                    ),
                  ),
                ),

                // Cây
                Positioned(
                  bottom: 50,
                  child: CustomPaint(
                    size: const Size(120, 80),
                    painter: _PlantPainter(
                      plantState: plantState,
                      leafColor: plantState.leafColor,
                    ),
                  ),
                ),

                // Giọt nước nếu ẩm
                if (moisture > 60) ...[
                  Positioned(
                    bottom: 40,
                    left: 60,
                    child: Icon(
                      Icons.water_drop,
                      color: Colors.blue.withOpacity(0.6),
                      size: 16,
                    ),
                  ),
                  Positioned(
                    bottom: 45,
                    right: 55,
                    child: Icon(
                      Icons.water_drop,
                      color: Colors.blue.withOpacity(0.4),
                      size: 12,
                    ),
                  ),
                ],

                // Icon cảnh báo nếu khô
                if (moisture < 30)
                  Positioned(
                    top: 10,
                    right: 20,
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 32,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Thanh tiến độ độ ẩm
          Column(
            children: [
              Row(
                children: [
                  Icon(Icons.water_drop, size: 16, color: Colors.blue.shade400),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: moisture / 100,
                        minHeight: 12,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getSoilColor(moisture),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${moisture.toInt()}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Khô',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  Text(
                    'Lý tưởng',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  Text(
                    'Ngập',
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

  PlantState _getPlantState(double moisture) {
    if (moisture < 20) {
      return PlantState.dying; // Đang chết
    } else if (moisture < 40) {
      return PlantState.dry; // Khô
    } else if (moisture < 70) {
      return PlantState.healthy; // Khỏe mạnh
    } else {
      return PlantState.overWatered; // Ngập nước
    }
  }

  Color _getSoilColor(double moisture) {
    if (moisture < 30) {
      return Colors.brown.shade400; // Đất khô
    } else if (moisture < 60) {
      return Colors.brown.shade600; // Đất ẩm vừa
    } else {
      return Colors.brown.shade800; // Đất ướt
    }
  }
}

enum PlantState { dying, dry, healthy, overWatered }

extension PlantStateExtension on PlantState {
  Color get leafColor {
    switch (this) {
      case PlantState.dying:
        return Colors.brown.shade300;
      case PlantState.dry:
        return Colors.yellow.shade700;
      case PlantState.healthy:
        return Colors.green.shade600;
      case PlantState.overWatered:
        return Colors.green.shade800;
    }
  }
}

/// Painter vẽ cây
class _PlantPainter extends CustomPainter {
  final PlantState plantState;
  final Color leafColor;

  _PlantPainter({required this.plantState, required this.leafColor});

  @override
  void paint(Canvas canvas, Size size) {
    // Thân cây
    final stemPaint = Paint()
      ..color = plantState == PlantState.dying
          ? Colors.brown.shade400
          : Colors.green.shade800
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width / 2, size.height),
      Offset(size.width / 2, size.height * 0.3),
      stemPaint,
    );

    // Lá
    final leafPaint = Paint()
      ..color = leafColor
      ..style = PaintingStyle.fill;

    // Lá trái
    _drawLeaf(canvas, leafPaint, size, -1);

    // Lá phải
    _drawLeaf(canvas, leafPaint, size, 1);

    // Lá giữa (nếu khỏe mạnh)
    if (plantState == PlantState.healthy) {
      _drawTopLeaf(canvas, leafPaint, size);
    }
  }

  void _drawLeaf(Canvas canvas, Paint paint, Size size, int side) {
    final path = Path();

    final centerX = size.width / 2;
    final startY = size.height * 0.5;

    path.moveTo(centerX, startY);

    // Cong lá
    path.quadraticBezierTo(
      centerX + (side * 20),
      startY - 15,
      centerX + (side * 30),
      startY - 25,
    );

    path.quadraticBezierTo(
      centerX + (side * 25),
      startY - 30,
      centerX,
      startY - 10,
    );

    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawTopLeaf(Canvas canvas, Paint paint, Size size) {
    final path = Path();

    final centerX = size.width / 2;
    final topY = size.height * 0.3;

    path.moveTo(centerX, topY);

    path.quadraticBezierTo(centerX - 15, topY - 10, centerX - 10, topY - 25);

    path.quadraticBezierTo(centerX, topY - 30, centerX + 10, topY - 25);

    path.quadraticBezierTo(centerX + 15, topY - 10, centerX, topY);

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
