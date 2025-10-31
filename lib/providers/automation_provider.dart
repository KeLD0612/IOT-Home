import 'package:flutter/material.dart';
import 'dart:async';
import '../models/automation_rule.dart';
import '../services/firestore_automation_service.dart';

class AutomationProvider extends ChangeNotifier {
  final FirestoreAutomationService _firestoreService =
      FirestoreAutomationService();

  List<AutomationRule> _rules = [];
  String? _currentUserId; // User isolation

  // 🔴 Real-time listener subscription
  StreamSubscription<List<AutomationRule>>? _rulesSubscription;

  List<AutomationRule> get rules => _rules;
  List<AutomationRule> get activeRules =>
      _rules.where((r) => r.enabled).toList();
  int get rulesCount => _rules.length;
  int get activeRulesCount => activeRules.length;

  AutomationProvider() {
    // Không load rules ngay, chờ setCurrentUser
  }

  /// Set current user và setup real-time listener
  Future<void> setCurrentUser(String? userId) async {
    if (_currentUserId == userId) return;

    // 🛑 HỦY LISTENER CŨ
    _rulesSubscription?.cancel();
    _rulesSubscription = null;

    _currentUserId = userId;

    if (userId != null) {
      await _setupRealtimeListener(userId);
    } else {
      _rules = [];
      notifyListeners();
    }
  }

  /// Setup real-time listener để tự động sync rules từ Firestore
  Future<void> _setupRealtimeListener(String userId) async {
    try {
      debugPrint('👂 Setting up real-time listener for automation rules...');

      // 🔴 LẮng nghe real-time changes từ Firestore
      _rulesSubscription = _firestoreService
          .watchUserRules(userId)
          .listen(
            (rules) {
              debugPrint(
                '📡 Received real-time rules update: ${rules.length} rules',
              );

              _rules = rules;
              notifyListeners();
            },
            onError: (error) {
              debugPrint('❌ Error in real-time rules listener: $error');
            },
          );

      debugPrint('✅ Real-time rules listener setup complete');
    } catch (e) {
      debugPrint('❌ Error setting up real-time rules listener: $e');
    }
  }

  /// Clear user data when logout
  void clearUserData() {
    _rulesSubscription?.cancel();
    _rulesSubscription = null;

    _currentUserId = null;
    _rules = [];
    notifyListeners();
    print('🧹 AutomationProvider: Cleared user data');
  }

  Future<void> addRule(AutomationRule rule) async {
    if (_currentUserId == null) return;

    // 🔥 LƯU VÀO FIRESTORE → Real-time listener sẽ tự động update _rules
    await _firestoreService.addRule(_currentUserId!, rule);
    print('✅ Added rule: ${rule.name}');
  }

  Future<void> updateRule(String id, AutomationRule updatedRule) async {
    if (_currentUserId == null) return;

    // 🔥 UPDATE VÀO FIRESTORE
    await _firestoreService.updateRule(_currentUserId!, updatedRule);
    print('✏️ Updated rule: ${updatedRule.name}');
  }

  Future<void> deleteRule(String id) async {
    if (_currentUserId == null) return;

    final rule = _rules.firstWhere((r) => r.id == id);

    // 🔥 XÓA KHỎI FIRESTORE
    await _firestoreService.deleteRule(_currentUserId!, id);
    print('🗑️ Deleted rule: ${rule.name}');
  }

  Future<void> toggleRule(String id) async {
    if (_currentUserId == null) return;

    final rule = _rules.firstWhere((r) => r.id == id);
    final newEnabled = !rule.enabled;

    // 🔥 UPDATE VÀO FIRESTORE
    await _firestoreService.toggleRule(_currentUserId!, id, newEnabled);
    print('🔄 Toggled rule: ${rule.name} -> $newEnabled');
  }

  Future<void> enableRule(String id) async {
    if (_currentUserId == null) return;

    final rule = _rules.firstWhere((r) => r.id == id);

    // 🔥 UPDATE VÀO FIRESTORE
    await _firestoreService.toggleRule(_currentUserId!, id, true);
    print('✅ Enabled rule: ${rule.name}');
  }

  Future<void> disableRule(String id) async {
    if (_currentUserId == null) return;

    final rule = _rules.firstWhere((r) => r.id == id);

    // 🔥 UPDATE VÀO FIRESTORE
    await _firestoreService.toggleRule(_currentUserId!, id, false);
    print('⏸️ Disabled rule: ${rule.name}');
  }

  AutomationRule? getRuleById(String id) {
    try {
      return _rules.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> markRuleTriggered(String id) async {
    if (_currentUserId == null) return;

    final rule = _rules.firstWhere((r) => r.id == id);

    // 🔥 UPDATE LAST TRIGGERED TIME VÀO FIRESTORE
    await _firestoreService.updateLastTriggered(
      _currentUserId!,
      id,
      DateTime.now(),
    );
    print('⚡ Rule triggered: ${rule.name}');
  }

  Future<void> clearAllRules() async {
    if (_currentUserId == null) return;

    // 🔥 XÓA TẤT CẢ KHỎI FIRESTORE
    await _firestoreService.deleteAllRules(_currentUserId!);
    print('🗑️ Cleared all automation rules');
  }

  @override
  void dispose() {
    _rulesSubscription?.cancel(); // 🔴 Cancel real-time listener
    super.dispose();
  }

  bool _isWithinTimeRange(AutomationRule rule) {
    if (rule.startTime == null && rule.endTime == null) {
      return true; // No time restriction
    }

    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;

    if (rule.startTime != null) {
      final startParts = rule.startTime!.split(':');
      final startMinutes =
          int.parse(startParts[0]) * 60 + int.parse(startParts[1]);

      if (rule.endTime != null) {
        final endParts = rule.endTime!.split(':');
        final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

        final inRange = startMinutes <= endMinutes
            ? (nowMinutes >= startMinutes && nowMinutes <= endMinutes)
            : (nowMinutes >= startMinutes || nowMinutes <= endMinutes);

        // Debug log
        print(
          '🕐 Time check for "${rule.name}": Now ${now.hour}:${now.minute.toString().padLeft(2, '0')}, Range ${rule.startTime}-${rule.endTime}, InRange: $inRange',
        );

        return inRange;
      }
    }

    return true;
  }

  bool checkConditions(AutomationRule rule, Map<String, dynamic> sensorData) {
    // Check time range first
    final withinTime = _isWithinTimeRange(rule);
    if (!withinTime) {
      // Debug: Uncomment để debug thời gian
      // print('⏰ Rule "${rule.name}" not in time range');
      return false;
    }

    print(
      '📋 Rule "${rule.name}" - conditions: ${rule.conditions.length}, sensorData keys: ${sensorData.keys.toList()}',
    );

    // If no sensor conditions, only time matters
    if (rule.conditions.isEmpty) {
      print('✅ Rule "${rule.name}" triggered (time-based only)');
      return true;
    }

    // If sensor data is empty but rule has conditions
    // For time-based rules, ignore sensor conditions if no data available
    if (sensorData.isEmpty) {
      print(
        '⚠️ Rule "${rule.name}" has conditions but no sensor data - treating as time-only rule',
      );
      return true; // Cho phép trigger nếu đã trong time range
    }

    // Check if all conditions are met
    for (var condition in rule.conditions) {
      final sensorValue = sensorData[condition.sensorId];
      if (sensorValue == null) {
        // Debug: sensor value not available
        // print('⚠️ Sensor "${condition.sensorId}" value not available for rule "${rule.name}"');
        continue;
      }

      // Use the evaluate method from Condition class
      if (!condition.evaluate(sensorValue)) {
        return false;
      }
    }

    print('✅ Rule "${rule.name}" triggered (condition met)');
    return true;
  }

  List<AutomationRule> getTriggeredRules(Map<String, dynamic> sensorData) {
    return activeRules
        .where((rule) => checkConditions(rule, sensorData))
        .toList();
  }

  // Method to evaluate and execute rules (called from SensorProvider)
  void evaluateRules(
    Map<String, dynamic> sensorData,
    Function(String deviceId, dynamic action) executeAction,
  ) {
    print('🔍 Evaluating ${activeRules.length} active rules');
    for (var rule in activeRules) {
      print(
        '🔎 Checking rule "${rule.name}" (enabled: ${rule.enabled}, startActions: ${rule.startActions.length})',
      );
      if (checkConditions(rule, sensorData)) {
        print(
          '⚡ Rule "${rule.name}" matched! Actions count: ${rule.startActions.length}',
        );

        // Execute all start actions
        for (var action in rule.startActions) {
          print('🎬 Executing action: ${action.deviceId} - ${action.action}');
          executeAction(action.deviceId, action);
        }

        // Mark as triggered
        markRuleTriggered(rule.id);
      }
    }
  }
}
