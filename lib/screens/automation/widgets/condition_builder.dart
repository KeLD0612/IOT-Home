import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/sensor_provider.dart';

/// Widget xây dựng điều kiện cho quy tắc tự động
class ConditionBuilder extends StatefulWidget {
  final Map<String, dynamic>? initialCondition;
  final ValueChanged<Map<String, dynamic>> onConditionChanged;

  const ConditionBuilder({
    Key? key,
    this.initialCondition,
    required this.onConditionChanged,
  }) : super(key: key);

  @override
  State<ConditionBuilder> createState() => _ConditionBuilderState();
}

class _ConditionBuilderState extends State<ConditionBuilder> {
  bool _noSensor = false; // Checkbox trạng thái
  String? _selectedSensor = 'temperature';
  String _operator = '>';
  double _value = 30;

  List<Map<String, String>> _sensors = [];

  final List<Map<String, String>> _operators = [
    {'value': '>', 'label': 'Lớn hơn'},
    {'value': '<', 'label': 'Nhỏ hơn'},
    {'value': '==', 'label': 'Bằng'},
    {'value': '>=', 'label': 'Lớn hơn hoặc bằng'},
    {'value': '<=', 'label': 'Nhỏ hơn hoặc bằng'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSensors();
    if (widget.initialCondition != null) {
      _noSensor = widget.initialCondition!['noSensor'] ?? false;
      _selectedSensor = widget.initialCondition!['sensor'] ?? 'temperature';
      _operator = widget.initialCondition!['operator'] ?? '>';
      _value = widget.initialCondition!['value']?.toDouble() ?? 30;
    }

    // Ensure selected sensor exists in the list
    if (_sensors.isNotEmpty && _selectedSensor != null) {
      final sensorExists = _sensors.any((s) => s['id'] == _selectedSensor);
      if (!sensorExists) {
        _selectedSensor = _sensors.first['id'];
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyChange();
    });
  }

  void _loadSensors() {
    // Load sensors from provider
    final sensorProvider = Provider.of<SensorProvider>(context, listen: false);
    _sensors = sensorProvider.userSensors.map((sensor) {
      return {'id': sensor.id, 'name': sensor.displayName};
    }).toList();
  }

  void _notifyChange() {
    if (_noSensor) {
      widget.onConditionChanged({'noSensor': true});
    } else {
      widget.onConditionChanged({
        'sensor': _selectedSensor,
        'operator': _operator,
        'value': _value,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Điều kiện (tùy chọn)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text('Không dùng cảm biến'),
              value: _noSensor,
              onChanged: (value) {
                setState(() {
                  _noSensor = value ?? false;
                  _notifyChange();
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 8),
            if (!_noSensor) ...[
              DropdownButtonFormField<String>(
                value: _selectedSensor,
                decoration: const InputDecoration(
                  labelText: 'Cảm biến',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.sensors),
                ),
                items: _sensors.map((sensor) {
                  return DropdownMenuItem(
                    value: sensor['id'],
                    child: Text(sensor['name']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSensor = value;
                    _notifyChange();
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _operator,
                      decoration: const InputDecoration(
                        labelText: 'Điều kiện',
                        border: OutlineInputBorder(),
                      ),
                      items: _operators.map((op) {
                        return DropdownMenuItem(
                          value: op['value'],
                          child: Text(op['label']!),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _operator = value!;
                          _notifyChange();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      initialValue: _value.toString(),
                      decoration: InputDecoration(
                        labelText: 'Giá trị',
                        border: const OutlineInputBorder(),
                        suffix: Text(_getUnit(_selectedSensor!)),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _value = double.tryParse(value) ?? 0;
                          _notifyChange();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getUnit(String sensor) {
    switch (sensor) {
      case 'temperature':
        return '°C';
      case 'humidity':
      case 'soil':
        return '%';
      case 'gas':
        return 'ppm';
      case 'dust':
        return 'µg/m³';
      case 'light':
        return 'lux';
      default:
        return '';
    }
  }
}
