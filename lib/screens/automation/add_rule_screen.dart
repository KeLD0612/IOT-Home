import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/automation_provider.dart';
import '../../models/automation_rule.dart' as automation_rule;
import 'widgets/condition_builder.dart';
import 'widgets/action_builder.dart';

/// Màn hình thêm/chỉnh sửa quy tắc tự động
class AddRuleScreen extends StatefulWidget {
  final automation_rule.AutomationRule? editRule;

  const AddRuleScreen({Key? key, this.editRule}) : super(key: key);

  @override
  State<AddRuleScreen> createState() => _AddRuleScreenState();
}

class _AddRuleScreenState extends State<AddRuleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  Map<String, dynamic> _condition = {};
  Map<String, dynamic> _startAction = {};
  Map<String, dynamic> _endAction = {};
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _useTime = false;
  bool _isEditMode = false;
  bool _hasEndActions = false; // Cho phép tùy chỉnh end actions

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.editRule != null;

    if (_isEditMode) {
      _loadExistingRule();
    }
  }

  void _loadExistingRule() {
    final rule = widget.editRule!;
    _nameController.text = rule.name;

    // Load condition
    if (rule.conditions.isNotEmpty) {
      final condition = rule.conditions.first;
      _condition = {
        'sensor': condition.sensorId,
        'operator': condition.operator,
        'value': condition.value,
      };
    }

    // Load start action
    if (rule.startActions.isNotEmpty) {
      final action = rule.startActions.first;
      _startAction = {
        'device': action.deviceId,
        'action': action.action,
        'value': action.value,
        'speed': action.speed,
        'mode': action.mode,
      };
    }

    // Load end action
    _hasEndActions = rule.hasEndActions;
    if (rule.hasEndActions && rule.endActions.isNotEmpty) {
      final action = rule.endActions.first;
      _endAction = {
        'device': action.deviceId,
        'action': action.action,
        'value': action.value,
        'speed': action.speed,
        'mode': action.mode,
      };
    }

    // Load time
    if (rule.startTime != null || rule.endTime != null) {
      _useTime = true;
      if (rule.startTime != null) {
        final parts = rule.startTime!.split(':');
        _startTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
      if (rule.endTime != null) {
        final parts = rule.endTime!.split(':');
        _endTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Widget _buildActionSection({
    required String title,
    required String subtitle,
    required Map<String, dynamic> action,
    required Function(Map<String, dynamic>) onActionChanged,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ActionBuilder(
              initialAction: action,
              onActionChanged: onActionChanged,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Chỉnh sửa quy tắc' : 'Thêm quy tắc'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Tên quy tắc
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên quy tắc',
                hintText: 'VD: Tự động tưới cây',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập tên quy tắc';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Điều kiện (tùy chọn)
            ConditionBuilder(
              onConditionChanged: (condition) {
                setState(() {
                  _condition = condition;
                });
              },
            ),
            const SizedBox(height: 16),

            // Chọn có dùng thời gian hay không
            CheckboxListTile(
              value: _useTime,
              onChanged: (val) {
                setState(() => _useTime = val ?? false);
              },
              title: Text('Kích hoạt theo thời gian'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            if (_useTime) ...[
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text(
                        _startTime == null
                            ? 'Chọn giờ bắt đầu'
                            : 'Bắt đầu: ${_startTime!.format(context)}',
                      ),
                      leading: Icon(Icons.access_time),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime:
                              _startTime ?? TimeOfDay(hour: 6, minute: 0),
                        );
                        if (picked != null) {
                          setState(() => _startTime = picked);
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: Text(
                        _endTime == null
                            ? 'Chọn giờ kết thúc'
                            : 'Kết thúc: ${_endTime!.format(context)}',
                      ),
                      leading: Icon(Icons.access_time),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime:
                              _endTime ?? TimeOfDay(hour: 18, minute: 0),
                        );
                        if (picked != null) {
                          setState(() => _endTime = picked);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Start Actions
            _buildActionSection(
              title: 'Hành động bắt đầu',
              subtitle: 'Thực thi khi điều kiện được thỏa mãn',
              action: _startAction,
              onActionChanged: (action) {
                setState(() {
                  _startAction = action;
                });
              },
            ),
            const SizedBox(height: 16),

            // End Actions toggle
            SwitchListTile(
              title: const Text('Hành động kết thúc tùy chỉnh'),
              subtitle: Text(
                _hasEndActions
                    ? 'Định nghĩa hành động khi điều kiện không còn thỏa mãn'
                    : 'Sử dụng hành động mặc định: tắt tất cả thiết bị',
              ),
              value: _hasEndActions,
              onChanged: (value) => setState(() => _hasEndActions = value),
            ),

            // End Actions (chỉ hiển thị khi bật)
            if (_hasEndActions) ...[
              const SizedBox(height: 16),
              _buildActionSection(
                title: 'Hành động kết thúc',
                subtitle: 'Thực thi khi điều kiện không còn thỏa mãn',
                action: _endAction,
                onActionChanged: (action) {
                  setState(() {
                    _endAction = action;
                  });
                },
              ),
            ],
            const SizedBox(height: 24),

            // Nút thêm
            ElevatedButton(
              onPressed: _handleAddRule,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Thêm quy tắc', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAddRule() {
    if (_formKey.currentState!.validate()) {
      if (_startAction.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng thiết lập hành động bắt đầu'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (_useTime && (_startTime == null || _endTime == null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng chọn thời gian hoạt động'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Thêm quy tắc mới
      final automationProvider = Provider.of<AutomationProvider>(
        context,
        listen: false,
      );

      // Kiểm tra dữ liệu start action
      if (_startAction.isEmpty || _startAction['device'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Vui lòng chọn hành động bắt đầu'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Chuyển đổi dữ liệu từ widgets sang format của model
      final conditionData = _condition.isEmpty || _condition['noSensor'] == true
          ? null
          : {
              'sensorType': _condition['sensor'],
              'operator': _condition['operator'],
              'value': _condition['value'],
            };

      final startActionData = {
        'deviceId': _startAction['device'],
        'action': _startAction['action'] ?? 'on',
        'value': _startAction['value'],
        'speed': _startAction['speed'],
        'mode': _startAction['mode'],
      };

      final endActionData = _hasEndActions && _endAction.isNotEmpty
          ? {
              'deviceId': _endAction['device'],
              'action': _endAction['action'] ?? 'off',
              'value': _endAction['value'],
              'speed': _endAction['speed'],
              'mode': _endAction['mode'],
            }
          : null;

      // Tạo/cập nhật rule object
      final rule = automation_rule.AutomationRule(
        id: _isEditMode
            ? widget.editRule!.id
            : DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        enabled: _isEditMode ? widget.editRule!.enabled : true,
        conditions: conditionData != null
            ? [automation_rule.Condition.fromJson(conditionData)]
            : [],
        startActions: [automation_rule.Action.fromJson(startActionData)],
        endActions: endActionData != null
            ? [automation_rule.Action.fromJson(endActionData)]
            : null,
        hasEndActions: _hasEndActions,
        createdAt: _isEditMode ? widget.editRule!.createdAt : DateTime.now(),
        lastTriggered: _isEditMode ? widget.editRule!.lastTriggered : null,
        startTime: _useTime && _startTime != null
            ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}'
            : null,
        endTime: _useTime && _endTime != null
            ? '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}'
            : null,
      );

      if (_isEditMode) {
        automationProvider.updateRule(rule.id, rule);
        print('✏️ Rule updated: ${rule.name}');
      } else {
        automationProvider.addRule(rule);
        print('🎯 Rule created: ${rule.name}');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Đã cập nhật quy tắc "${_nameController.text}"'
                : 'Đã thêm quy tắc "${_nameController.text}"',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    }
  }
}
