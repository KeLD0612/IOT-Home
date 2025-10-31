class AutomationRule {
  final String id;
  final String name;
  final bool enabled;
  final List<Condition> conditions;
  final List<Action> startActions;
  final List<Action> endActions;
  final bool hasEndActions;
  final DateTime createdAt;
  final DateTime? lastTriggered;

  AutomationRule({
    required this.id,
    required this.name,
    required this.enabled,
    required this.conditions,
    required this.startActions,
    this.endActions = const [],
    this.hasEndActions = false,
    required this.createdAt,
    this.lastTriggered,
  });

  factory AutomationRule.fromJson(Map<String, dynamic> json) {
    return AutomationRule(
      id: json['id'],
      name: json['name'],
      enabled: json['enabled'],
      conditions: (json['conditions'] as List)
          .map((e) => Condition.fromJson(e))
          .toList(),
      startActions: (json['startActions'] as List? ?? json['actions'] as List? ?? [])
          .map((e) => Action.fromJson(e))
          .toList(),
      endActions: (json['endActions'] as List? ?? [])
          .map((e) => Action.fromJson(e))
          .toList(),
      hasEndActions: json['hasEndActions'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      lastTriggered: json['lastTriggered'] != null
          ? DateTime.parse(json['lastTriggered'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'enabled': enabled,
      'conditions': conditions.map((e) => e.toJson()).toList(),
      'startActions': startActions.map((e) => e.toJson()).toList(),
      'endActions': endActions.map((e) => e.toJson()).toList(),
      'hasEndActions': hasEndActions,
      'createdAt': createdAt.toIso8601String(),
      'lastTriggered': lastTriggered?.toIso8601String(),
    };
  }

  AutomationRule copyWith({
    String? id,
    String? name,
    bool? enabled,
    List<Condition>? conditions,
    List<Action>? startActions,
    List<Action>? endActions,
    bool? hasEndActions,
    DateTime? createdAt,
    DateTime? lastTriggered,
  }) {
    return AutomationRule(
      id: id ?? this.id,
      name: name ?? this.name,
      enabled: enabled ?? this.enabled,
      conditions: conditions ?? this.conditions,
      startActions: startActions ?? this.startActions,
      endActions: endActions ?? this.endActions,
      hasEndActions: hasEndActions ?? this.hasEndActions,
      createdAt: createdAt ?? this.createdAt,
      lastTriggered: lastTriggered ?? this.lastTriggered,
    );
  }

  /// Get effective end actions (custom or auto-reverse of start actions)
  List<Action> getEffectiveEndActions() {
    if (hasEndActions && endActions.isNotEmpty) {
      return endActions;
    }
    // Auto-reverse: turn off all devices that were turned on
    return startActions.map((action) {
      if (action.action == 'turn_on') {
        return action.copyWith(action: 'turn_off');
      }
      return action;
    }).toList();
  }
}

class Condition {
  final String sensorId;
  final String operator; // '>', '<', '==', '>=', '<='
  final dynamic value;

  Condition({
    required this.sensorId,
    required this.operator,
    required this.value,
  });

  factory Condition.fromJson(Map<String, dynamic> json) {
    return Condition(
      sensorId: json['sensorId'] ?? json['sensorType'] ?? '',
      operator: json['operator'],
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'sensorId': sensorId, 'operator': operator, 'value': value};
  }

  bool evaluate(dynamic currentValue) {
    switch (operator) {
      case '>':
        return currentValue > value;
      case '<':
        return currentValue < value;
      case '==':
        return currentValue == value;
      case '>=':
        return currentValue >= value;
      case '<=':
        return currentValue <= value;
      default:
        return false;
    }
  }

  Condition copyWith({
    String? sensorId,
    String? operator,
    dynamic value,
  }) {
    return Condition(
      sensorId: sensorId ?? this.sensorId,
      operator: operator ?? this.operator,
      value: value ?? this.value,
    );
  }
}

class Action {
  final String deviceId;
  final String? deviceCode;
  final String action; // 'turn_on', 'turn_off', 'set_value', 'set_speed', 'set_angle', 'toggle'
  final dynamic value;
  final int? speed;
  final String? mode;

  Action({
    required this.deviceId,
    this.deviceCode,
    required this.action,
    this.value,
    this.speed,
    this.mode,
  });

  factory Action.fromJson(Map<String, dynamic> json) {
    return Action(
      deviceId: json['deviceId'] ?? '',
      deviceCode: json['deviceCode'],
      action: json['action'] ?? 'turn_on',
      value: json['value'],
      speed: json['speed'],
      mode: json['mode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceCode': deviceCode,
      'action': action,
      'value': value,
      'speed': speed,
      'mode': mode,
    };
  }

  Action copyWith({
    String? deviceId,
    String? deviceCode,
    String? action,
    dynamic value,
    int? speed,
    String? mode,
  }) {
    return Action(
      deviceId: deviceId ?? this.deviceId,
      deviceCode: deviceCode ?? this.deviceCode,
      action: action ?? this.action,
      value: value ?? this.value,
      speed: speed ?? this.speed,
      mode: mode ?? this.mode,
    );
  }
}
