import 'package:flutter/material.dart';
import '../models/automation_rule.dart';
import '../services/local_storage_service.dart';

class AutomationProvider extends ChangeNotifier {
  final LocalStorageService _storageService;

  List<AutomationRule> _rules = [];

  List<AutomationRule> get rules => _rules;
  List<AutomationRule> get activeRules =>
      _rules.where((r) => r.enabled).toList();
  int get rulesCount => _rules.length;
  int get activeRulesCount => activeRules.length;

  AutomationProvider(this._storageService) {
    _loadRules();
  }

  void _loadRules() {
    final stored = _storageService.getAutomationRules();
    _rules = stored.map((json) => AutomationRule.fromJson(json)).toList();
    print('🤖 Loaded ${_rules.length} automation rules');
  }

  void _saveRules() {
    final jsonList = _rules.map((rule) => rule.toJson()).toList();
    _storageService.saveAutomationRules(jsonList);
    print('💾 Saved ${_rules.length} automation rules');
  }

  void addRule(AutomationRule rule) {
    _rules.add(rule);
    _saveRules();
    notifyListeners();
    print('✅ Added rule: ${rule.name}');
  }

  void updateRule(String id, AutomationRule updatedRule) {
    final index = _rules.indexWhere((r) => r.id == id);
    if (index != -1) {
      _rules[index] = updatedRule;
      _saveRules();
      notifyListeners();
      print('✏️ Updated rule: ${updatedRule.name}');
    }
  }

  void deleteRule(String id) {
    final rule = _rules.firstWhere((r) => r.id == id);
    _rules.removeWhere((r) => r.id == id);
    _saveRules();
    notifyListeners();
    print('🗑️ Deleted rule: ${rule.name}');
  }

  void toggleRule(String id) {
    final index = _rules.indexWhere((r) => r.id == id);
    if (index != -1) {
      final rule = _rules[index];
      _rules[index] = rule.copyWith(enabled: !rule.enabled);
      _saveRules();
      notifyListeners();
      print('🔄 Toggled rule: ${rule.name} -> ${!rule.enabled}');
    }
  }

  void enableRule(String id) {
    final index = _rules.indexWhere((r) => r.id == id);
    if (index != -1) {
      final rule = _rules[index];
      _rules[index] = rule.copyWith(enabled: true);
      _saveRules();
      notifyListeners();
      print('✅ Enabled rule: ${rule.name}');
    }
  }

  void disableRule(String id) {
    final index = _rules.indexWhere((r) => r.id == id);
    if (index != -1) {
      final rule = _rules[index];
      _rules[index] = rule.copyWith(enabled: false);
      _saveRules();
      notifyListeners();
      print('⏸️ Disabled rule: ${rule.name}');
    }
  }

  AutomationRule? getRuleById(String id) {
    try {
      return _rules.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  void markRuleTriggered(String id) {
    final index = _rules.indexWhere((r) => r.id == id);
    if (index != -1) {
      final rule = _rules[index];
      _rules[index] = rule.copyWith(lastTriggered: DateTime.now());
      _saveRules();
      notifyListeners();
      print('⚡ Rule triggered: ${rule.name}');
    }
  }

  void clearAllRules() {
    _rules.clear();
    _saveRules();
    notifyListeners();
    print('🗑️ Cleared all automation rules');
  }

  bool checkConditions(AutomationRule rule, Map<String, dynamic> sensorData) {
    // Check if all conditions are met
    for (var condition in rule.conditions) {
      final sensorValue = sensorData[condition.sensorId];
      if (sensorValue == null) continue;

      // Use the evaluate method from Condition class
      if (!condition.evaluate(sensorValue)) {
        return false;
      }
    }

    return true;
  }

  List<AutomationRule> getTriggeredRules(Map<String, dynamic> sensorData) {
    return activeRules
        .where((rule) => checkConditions(rule, sensorData))
        .toList();
  }

  /// Set current user for multi-user support
  Future<void> setCurrentUser(String userId) async {
    print('👤 AutomationProvider: Set current user: $userId');
  }

  /// Clear user data on logout
  void clearUserData() {
    _rules.clear();
    print('🗑️ AutomationProvider: Cleared user data');
    notifyListeners();
  }
}
