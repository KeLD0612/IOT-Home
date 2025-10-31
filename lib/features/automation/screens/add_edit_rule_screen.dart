import 'package:flutter/material.dart' hide Action;
import 'package:provider/provider.dart';
import '../../../models/automation_rule.dart';
import '../providers/automation_provider.dart';

class AddEditRuleScreen extends StatefulWidget {
  final AutomationRule? rule;

  const AddEditRuleScreen({Key? key, this.rule}) : super(key: key);

  @override
  State<AddEditRuleScreen> createState() => _AddEditRuleScreenState();
}

class _AddEditRuleScreenState extends State<AddEditRuleScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;

  List<Condition> _conditions = [];
  List<Action> _startActions = [];
  List<Action> _endActions = [];
  bool _enabled = true;
  bool _hasEndActions = false; // Cho phép tùy chỉnh end actions

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.rule?.name ?? '');

    if (widget.rule != null) {
      _conditions = List.from(widget.rule!.conditions);
      _startActions = List.from(widget.rule!.startActions);
      _endActions = List.from(widget.rule!.endActions);
      _hasEndActions = widget.rule!.hasEndActions;
      _enabled = widget.rule!.enabled;
    } else {
      // 🔄 Default: add one empty condition and action (will be populated by UI)
      final automationProvider = Provider.of<AutomationProvider>(
        context,
        listen: false,
      );
      final availableSensors = automationProvider.availableSensors;
      final availableDevices = automationProvider.availableDevices;

      if (availableSensors.isNotEmpty) {
        _conditions.add(
          Condition(
            sensorId: availableSensors.first.id,
            operator: '>',
            value: 25.0,
          ),
        );
      }

      if (availableDevices.isNotEmpty) {
        _startActions.add(
          Action(
            deviceId: availableDevices.first.id,
            deviceCode: availableDevices.first.deviceCode,
            action: 'turn_on',
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.rule != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Rule' : 'Create Rule'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveRule),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Rule name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Rule Name',
                hintText: 'e.g., Turn on fan when hot',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a rule name';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Enabled switch
            SwitchListTile(
              title: const Text('Enabled'),
              subtitle: const Text('Rule will run automatically when enabled'),
              value: _enabled,
              onChanged: (value) => setState(() => _enabled = value),
            ),

            const Divider(height: 32),

            // Conditions section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Conditions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton.icon(
                  onPressed: _addCondition,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'All conditions must be true for the rule to trigger',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 12),

            ..._conditions.asMap().entries.map((entry) {
              final index = entry.key;
              final condition = entry.value;
              return _buildConditionCard(context, condition, index);
            }).toList(),

            const Divider(height: 32),

            // Start Actions section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Start Actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton.icon(
                  onPressed: _addStartAction,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Actions will be executed when conditions are met',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 12),

            ..._startActions.asMap().entries.map((entry) {
              final index = entry.key;
              final action = entry.value;
              return _buildActionCard(
                context,
                action,
                index,
                isStartAction: true,
              );
            }).toList(),

            const SizedBox(height: 24),

            // End Actions toggle
            SwitchListTile(
              title: const Text('Custom End Actions'),
              subtitle: Text(
                _hasEndActions
                    ? 'Define custom actions when conditions are no longer met'
                    : 'Use default action: turn off all devices',
              ),
              value: _hasEndActions,
              onChanged: (value) => setState(() => _hasEndActions = value),
            ),

            // End Actions section (only show if enabled)
            if (_hasEndActions) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'End Actions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton.icon(
                    onPressed: _addEndAction,
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Actions will be executed when conditions are no longer met',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 12),

              ..._endActions.asMap().entries.map((entry) {
                final index = entry.key;
                final action = entry.value;
                return _buildActionCard(
                  context,
                  action,
                  index,
                  isStartAction: false,
                );
              }).toList(),
            ],

            const SizedBox(height: 32),

            // Save button
            ElevatedButton(
              onPressed: _saveRule,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: Text(isEdit ? 'Update Rule' : 'Create Rule'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionCard(
    BuildContext context,
    Condition condition,
    int index,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Condition ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: () => _removeCondition(index),
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 🔄 Sensor dropdown - Dynamic from user's actual sensors
            Consumer<AutomationProvider>(
              builder: (context, automationProvider, child) {
                final availableSensors = automationProvider.availableSensors;

                if (availableSensors.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'No sensors available. Please add sensors first.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return DropdownButtonFormField<String>(
                  value: condition.sensorId,
                  decoration: const InputDecoration(
                    labelText: 'Sensor',
                    border: OutlineInputBorder(),
                  ),
                  items: availableSensors.map((sensor) {
                    return DropdownMenuItem(
                      value: sensor.id,
                      child: Row(
                        children: [
                          Text(
                            sensor.icon,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  sensor.displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  sensor.sensorType?.name ?? 'Unknown',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _conditions[index] = Condition(
                          sensorId: value,
                          operator: condition.operator,
                          value: condition.value,
                        );
                      });
                    }
                  },
                );
              },
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                // Operator dropdown
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: condition.operator,
                    decoration: const InputDecoration(
                      labelText: 'Operator',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: '>', child: Text('>')),
                      DropdownMenuItem(value: '<', child: Text('<')),
                      DropdownMenuItem(value: '>=', child: Text('>=')),
                      DropdownMenuItem(value: '<=', child: Text('<=')),
                      DropdownMenuItem(value: '==', child: Text('==')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _conditions[index] = Condition(
                            sensorId: condition.sensorId,
                            operator: value,
                            value: condition.value,
                          );
                        });
                      }
                    },
                  ),
                ),

                const SizedBox(width: 12),

                // Value input
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: condition.value.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Value',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final numValue = double.tryParse(value);
                      if (numValue != null) {
                        _conditions[index] = Condition(
                          sensorId: condition.sensorId,
                          operator: condition.operator,
                          value: numValue,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    Action action,
    int index, {
    required bool isStartAction,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${isStartAction ? "Start" : "End"} Action ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: () => _removeAction(index, isStartAction),
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 🔄 Device dropdown - Dynamic from user's actual devices
            Consumer<AutomationProvider>(
              builder: (context, automationProvider, child) {
                final availableDevices = automationProvider.availableDevices;

                if (availableDevices.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'No devices available. Please add devices first.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return DropdownButtonFormField<String>(
                  value: action.deviceId,
                  decoration: const InputDecoration(
                    labelText: 'Device',
                    border: OutlineInputBorder(),
                  ),
                  items: availableDevices.map((device) {
                    return DropdownMenuItem(
                      value: device.id,
                      child: Row(
                        children: [
                          Text(
                            device.icon ?? '🔧',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  device.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${device.type} • ${device.deviceCode}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      final selectedDevice = availableDevices.firstWhere(
                        (d) => d.id == value,
                      );
                      setState(() {
                        if (isStartAction) {
                          _startActions[index] = Action(
                            deviceId: value,
                            deviceCode: selectedDevice.deviceCode,
                            action: action.action,
                            value: action.value,
                            speed: action.speed,
                            mode: action.mode,
                          );
                        } else {
                          _endActions[index] = Action(
                            deviceId: value,
                            deviceCode: selectedDevice.deviceCode,
                            action: action.action,
                            value: action.value,
                            speed: action.speed,
                            mode: action.mode,
                          );
                        }
                      });
                    }
                  },
                );
              },
            ),

            const SizedBox(height: 12),

            // Action type dropdown
            DropdownButtonFormField<String>(
              value: action.action,
              decoration: const InputDecoration(
                labelText: 'Action',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'turn_on', child: Text('Turn On')),
                DropdownMenuItem(value: 'turn_off', child: Text('Turn Off')),
                DropdownMenuItem(value: 'toggle', child: Text('Toggle')),
                DropdownMenuItem(value: 'set_value', child: Text('Set Value')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    if (isStartAction) {
                      _startActions[index] = Action(
                        deviceId: action.deviceId,
                        deviceCode: action.deviceCode,
                        action: value,
                        value: action.value,
                        speed: action.speed,
                        mode: action.mode,
                      );
                    } else {
                      _endActions[index] = Action(
                        deviceId: action.deviceId,
                        deviceCode: action.deviceCode,
                        action: value,
                        value: action.value,
                        speed: action.speed,
                        mode: action.mode,
                      );
                    }
                  });
                }
              },
            ),

            // Optional value field for set_value action
            if (action.action == 'set_value') ...[
              const SizedBox(height: 12),
              TextFormField(
                initialValue: action.value?.toString() ?? '',
                decoration: const InputDecoration(
                  labelText: 'Value (e.g., servo angle 0-180)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final numValue = int.tryParse(value);
                  if (isStartAction) {
                    _startActions[index] = Action(
                      deviceId: action.deviceId,
                      deviceCode: action.deviceCode,
                      action: action.action,
                      value: numValue,
                      speed: action.speed,
                      mode: action.mode,
                    );
                  } else {
                    _endActions[index] = Action(
                      deviceId: action.deviceId,
                      deviceCode: action.deviceCode,
                      action: action.action,
                      value: numValue,
                      speed: action.speed,
                      mode: action.mode,
                    );
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _addCondition() {
    setState(() {
      final automationProvider = Provider.of<AutomationProvider>(
        context,
        listen: false,
      );
      final availableSensors = automationProvider.availableSensors;

      if (availableSensors.isNotEmpty) {
        _conditions.add(
          Condition(
            sensorId: availableSensors.first.id,
            operator: '>',
            value: 25.0,
          ),
        );
      } else {
        // Fallback if no sensors available
        _conditions.add(
          Condition(sensorId: 'temp_sensor', operator: '>', value: 25.0),
        );
      }
    });
  }

  void _removeCondition(int index) {
    if (_conditions.length > 1) {
      setState(() {
        _conditions.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one condition is required')),
      );
    }
  }

  void _addStartAction() {
    setState(() {
      final automationProvider = Provider.of<AutomationProvider>(
        context,
        listen: false,
      );
      final availableDevices = automationProvider.availableDevices;

      if (availableDevices.isNotEmpty) {
        _startActions.add(
          Action(
            deviceId: availableDevices.first.id,
            deviceCode: availableDevices.first.deviceCode,
            action: 'turn_on',
          ),
        );
      } else {
        // Fallback if no devices available
        _startActions.add(
          Action(deviceId: 'relay1', deviceCode: 'RELAY1', action: 'turn_on'),
        );
      }
    });
  }

  void _addEndAction() {
    setState(() {
      final automationProvider = Provider.of<AutomationProvider>(
        context,
        listen: false,
      );
      final availableDevices = automationProvider.availableDevices;

      if (availableDevices.isNotEmpty) {
        _endActions.add(
          Action(
            deviceId: availableDevices.first.id,
            deviceCode: availableDevices.first.deviceCode,
            action: 'turn_off',
          ),
        );
      } else {
        // Fallback if no devices available
        _endActions.add(
          Action(deviceId: 'relay1', deviceCode: 'RELAY1', action: 'turn_off'),
        );
      }
    });
  }

  void _removeAction(int index, bool isStartAction) {
    setState(() {
      if (isStartAction) {
        if (_startActions.length > 1) {
          _startActions.removeAt(index);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('At least one start action is required'),
            ),
          );
        }
      } else {
        _endActions.removeAt(index);
      }
    });
  }

  void _saveRule() async {
    if (!_formKey.currentState!.validate()) return;

    if (_conditions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one condition')),
      );
      return;
    }

    if (_startActions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one start action')),
      );
      return;
    }

    final rule = AutomationRule(
      id: widget.rule?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      enabled: _enabled,
      conditions: _conditions,
      startActions: _startActions,
      endActions: _hasEndActions ? _endActions : null,
      hasEndActions: _hasEndActions,
      createdAt: widget.rule?.createdAt ?? DateTime.now(),
      lastTriggered: widget.rule?.lastTriggered,
    );

    final provider = context.read<AutomationProvider>();
    bool success;

    if (widget.rule != null) {
      success = await provider.updateRule(rule);
    } else {
      success = await provider.addRule(rule);
    }

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.rule != null ? 'Rule updated' : 'Rule created'),
        ),
      );
    } else if (mounted && provider.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error!), backgroundColor: Colors.red),
      );
    }
  }
}
