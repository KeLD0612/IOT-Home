import 'package:flutter/material.dart';

/// Widget xây dựng hành động cho quy tắc tự động
class ActionBuilder extends StatefulWidget {
  final Map<String, dynamic>? initialAction;
  final ValueChanged<Map<String, dynamic>> onActionChanged;

  const ActionBuilder({
    Key? key,
    this.initialAction,
    required this.onActionChanged,
  }) : super(key: key);

  @override
  State<ActionBuilder> createState() => _ActionBuilderState();
}

class _ActionBuilderState extends State<ActionBuilder> {
  String _actionType = 'device';
  String _device = 'pump';
  String _action = 'on';
  int _servoAngle = 90;

  final List<Map<String, String>> _devices = [
    {'id': 'pump', 'name': 'Máy bơm', 'type': 'relay'},
    {'id': 'light_living', 'name': 'Đèn phòng khách', 'type': 'relay'},
    {'id': 'light_yard', 'name': 'Đèn sân', 'type': 'relay'},
    {'id': 'ionizer', 'name': 'Máy ion hóa', 'type': 'relay'},
    {'id': 'roof', 'name': 'Mái che', 'type': 'servo'},
    {'id': 'gate', 'name': 'Cổng', 'type': 'servo'},
    {'id': 'buzzer', 'name': 'Còi', 'type': 'relay'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialAction != null) {
      _device = widget.initialAction!['device'] ?? 'pump';
      _action = widget.initialAction!['action'] ?? 'on';
      _servoAngle = widget.initialAction!['value'] ?? 90;
    }
    // Gọi sau khi build xong
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyChange();
    });
  }

  void _notifyChange() {
    final deviceInfo = _devices.firstWhere((d) => d['id'] == _device);
    widget.onActionChanged({
      'type': _actionType,
      'device': _device,
      'action': _action,
      'value': deviceInfo['type'] == 'servo' ? _servoAngle : null,
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedDevice = _devices.firstWhere((d) => d['id'] == _device);
    final isServo = selectedDevice['type'] == 'servo';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hành động',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Chọn thiết bị
            DropdownButtonFormField<String>(
              value: _device,
              decoration: const InputDecoration(
                labelText: 'Thiết bị',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.device_hub),
              ),
              items: _devices.map((device) {
                return DropdownMenuItem(
                  value: device['id'],
                  child: Text(device['name']!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _device = value!;
                  _notifyChange();
                });
              },
            ),
            const SizedBox(height: 16),

            // Hành động
            if (isServo) ...[
              // Servo: Slider góc
              Text('Góc: $_servoAngle°', style: const TextStyle(fontSize: 14)),
              Slider(
                value: _servoAngle.toDouble(),
                min: 0,
                max: 180,
                divisions: 18,
                label: '$_servoAngle°',
                onChanged: (value) {
                  setState(() {
                    _servoAngle = value.toInt();
                    _notifyChange();
                  });
                },
              ),
            ] else ...[
              // Relay: Bật/Tắt
              DropdownButtonFormField<String>(
                value: _action,
                decoration: const InputDecoration(
                  labelText: 'Hành động',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flash_on),
                ),
                items: const [
                  DropdownMenuItem(value: 'on', child: Text('Bật')),
                  DropdownMenuItem(value: 'off', child: Text('Tắt')),
                ],
                onChanged: (value) {
                  setState(() {
                    _action = value!;
                    _notifyChange();
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
