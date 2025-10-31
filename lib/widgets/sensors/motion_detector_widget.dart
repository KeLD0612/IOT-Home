import 'package:flutter/material.dart';
import '../../models/user_sensor.dart';
import '../../models/sensor_health.dart';

/// 📡 Widget chuyển động - sóng phát hiện
class MotionDetectorWidget extends StatelessWidget {
  final UserSensor sensor;

  const MotionDetectorWidget({Key? key, required this.sensor})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final value = sensor.lastValue;
    final healthInfo = sensor.healthInfo;

    // Kiểm tra có chuyển động không
    final bool hasMotion = value == true || value == 1 || value == '1';

    return Container(
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: hasMotion
              ? [Colors.red.shade50, Colors.orange.shade50]
              : [Colors.green.shade50, Colors.blue.shade50],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasMotion
              ? Colors.red.withOpacity(0.5)
              : Colors.green.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hasMotion
                      ? Colors.red.shade100
                      : Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasMotion ? Icons.sensors : Icons.sensors_off,
                  color: hasMotion
                      ? Colors.red.shade700
                      : Colors.green.shade700,
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
                  color: hasMotion ? Colors.red : Colors.green,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: hasMotion
                          ? Colors.red.withOpacity(0.3)
                          : Colors.green.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasMotion ? Icons.warning : Icons.check_circle,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      hasMotion ? 'PHÁT HIỆN' : 'BÌNH THƯỜNG',
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

          // Sóng phát hiện
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Sóng lan tỏa nếu có chuyển động
                  if (hasMotion) ...[
                    for (int i = 0; i < 3; i++)
                      _RippleWave(
                        delay: i * 500,
                        color: Colors.red.withOpacity(0.3),
                      ),
                  ],

                  // Icon trung tâm
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: hasMotion
                          ? Colors.red.withOpacity(0.2)
                          : Colors.green.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: hasMotion ? Colors.red : Colors.green,
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      hasMotion ? Icons.person : Icons.person_off,
                      size: 40,
                      color: hasMotion ? Colors.red : Colors.green,
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
}

/// Widget sóng lan tỏa
class _RippleWave extends StatefulWidget {
  final int delay;
  final Color color;

  const _RippleWave({required this.delay, required this.color});

  @override
  State<_RippleWave> createState() => _RippleWaveState();
}

class _RippleWaveState extends State<_RippleWave>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _sizeAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _sizeAnimation = Tween<double>(
      begin: 80.0,
      end: 150.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 0.8,
      end: 0.0,
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
        return Container(
          width: _sizeAnimation.value,
          height: _sizeAnimation.value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.color.withOpacity(_fadeAnimation.value),
              width: 3,
            ),
          ),
        );
      },
    );
  }
}
