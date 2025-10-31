import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/automation_provider.dart';
import '../../providers/sensor_provider.dart';
import '../../providers/device_provider.dart';
import '../../config/app_colors.dart';
import 'add_rule_screen.dart';

class AutomationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tự động hóa'),
        actions: [
          Consumer<AutomationProvider>(
            builder: (context, automationProvider, _) {
              return Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    '${automationProvider.activeRulesCount}/${automationProvider.rulesCount}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<AutomationProvider>(
        builder: (context, automationProvider, _) {
          final rules = automationProvider.rules;

          if (rules.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Chưa có quy tắc tự động',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Nhấn + để thêm quy tắc mới',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(Duration(seconds: 1));
            },
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                // Header
                _buildHeader(context, automationProvider),
                SizedBox(height: 24),

                // Active Rules
                if (automationProvider.activeRules.isNotEmpty) ...[
                  _buildSectionTitle(
                    'Đang hoạt động',
                    automationProvider.activeRulesCount,
                  ),
                  SizedBox(height: 12),
                  ...automationProvider.activeRules.map((rule) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: _buildRuleCard(context, rule, automationProvider),
                    );
                  }).toList(),
                  SizedBox(height: 24),
                ],

                // Inactive Rules
                ..._buildInactiveRulesSection(
                  context,
                  rules,
                  automationProvider,
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add_rule'),
        child: Icon(Icons.add),
        tooltip: 'Thêm quy tắc',
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AutomationProvider automationProvider,
  ) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.blueGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.settings_suggest, color: Colors.white, size: 32),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tự động hóa thông minh',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${automationProvider.activeRulesCount} quy tắc đang hoạt động',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                '${automationProvider.rulesCount}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Quy tắc',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(width: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRuleCard(
    BuildContext context,
    rule,
    AutomationProvider automationProvider,
  ) {
    return Dismissible(
      key: Key(rule.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete, color: Colors.white, size: 32),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Xác nhận xóa'),
            content: Text('Bạn có chắc muốn xóa quy tắc "${rule.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Xóa'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        automationProvider.deleteRule(rule.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xóa quy tắc "${rule.name}"')),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _showRuleDetail(context, rule),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      rule.enabled ? Icons.check_circle : Icons.pause_circle,
                      color: rule.enabled ? AppColors.success : Colors.grey,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rule.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${rule.conditions.length} điều kiện • ${rule.startActions.length} hành động',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: rule.enabled,
                      onChanged: (value) {
                        automationProvider.toggleRule(rule.id);
                      },
                      activeColor: AppColors.primary,
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert),
                      onSelected: (value) {
                        if (value == 'edit') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AddRuleScreen(editRule: rule),
                            ),
                          );
                        } else if (value == 'delete') {
                          _deleteRule(context, rule, automationProvider);
                        } else if (value == 'detail') {
                          _showRuleDetail(context, rule);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 12),
                              Text('Chỉnh sửa'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'detail',
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 20),
                              SizedBox(width: 12),
                              Text('Chi tiết'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 12),
                              Text('Xóa', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (rule.lastTriggered != null) ...[
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.history, size: 16, color: AppColors.info),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Lần chạy cuối: ${_formatDateTime(rule.lastTriggered)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.info,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} giờ trước';
    } else {
      return '${difference.inDays} ngày trước';
    }
  }

  List<Widget> _buildInactiveRulesSection(
    BuildContext context,
    List rules,
    AutomationProvider automationProvider,
  ) {
    final inactiveRules = rules.where((r) => !r.enabled).toList();

    if (inactiveRules.isEmpty) {
      return [];
    }

    return [
      _buildSectionTitle('Tạm dừng', inactiveRules.length),
      SizedBox(height: 12),
      ...inactiveRules.map((rule) {
        return Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: _buildRuleCard(context, rule, automationProvider),
        );
      }).toList(),
    ];
  }

  void _showRuleDetail(BuildContext context, dynamic rule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                rule.name,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Trạng thái
              _buildDetailRow(
                'Trạng thái',
                rule.enabled ? 'Đang bật' : 'Đã tắt',
                rule.enabled ? Colors.green : Colors.grey,
              ),
              Divider(),

              // Điều kiện
              Text(
                'Điều kiện:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              if (rule.conditions.isEmpty)
                Text('Không có điều kiện', style: TextStyle(color: Colors.grey))
              else
                ...rule.conditions
                    .map(
                      (condition) => Padding(
                        padding: EdgeInsets.only(left: 16, bottom: 8),
                        child: Text(
                          '• ${_getConditionText(context, condition)}',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    )
                    .toList(),

              SizedBox(height: 16),

              // Hành động
              Text(
                'Hành động:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              ...rule.startActions
                  .map(
                    (action) => Padding(
                      padding: EdgeInsets.only(left: 16, bottom: 8),
                      child: Text(
                        '• ${_getActionText(context, action)}',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  )
                  .toList(),

              SizedBox(height: 16),

              // Thời gian hoạt động
              if (rule.startTime != null || rule.endTime != null) ...[
                Text(
                  'Thời gian hoạt động:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Text(
                    '${rule.startTime ?? '00:00'} - ${rule.endTime ?? '23:59'}',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                SizedBox(height: 16),
              ],

              // Thời gian tạo
              _buildDetailRow(
                'Ngày tạo',
                _formatDate(rule.createdAt),
                Colors.grey,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddRuleScreen(editRule: rule),
                ),
              );
            },
            icon: Icon(Icons.edit),
            label: Text('Chỉnh sửa'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color valueColor) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: valueColor)),
        ],
      ),
    );
  }

  String _getConditionText(BuildContext context, dynamic condition) {
    // Get sensor name from provider instead of hard-coded map
    final sensorProvider = Provider.of<SensorProvider>(context, listen: false);
    final sensor = sensorProvider.userSensors.firstWhere(
      (s) => s.id == condition.sensorId,
      orElse: () => throw StateError('Sensor not found'),
    );
    final sensorName = sensor.displayName;

    final operatorNames = {
      '>': 'lớn hơn',
      '<': 'nhỏ hơn',
      '==': 'bằng',
      '>=': 'lớn hơn hoặc bằng',
      '<=': 'nhỏ hơn hoặc bằng',
    };

    final operatorName =
        operatorNames[condition.operator] ?? condition.operator;

    return '$sensorName $operatorName ${condition.value}';
  }

  String _getActionText(BuildContext context, dynamic action) {
    // Get device name from provider instead of hard-coded map
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    final device = deviceProvider.devices.firstWhere(
      (d) => d.id == action.deviceId,
      orElse: () => throw StateError('Device not found'),
    );
    final deviceName = device.name;

    final actionNames = {
      'on': 'Bật',
      'off': 'Tắt',
      'turn_on': 'Bật',
      'turn_off': 'Tắt',
    };

    // Handle different action types
    if (action.value != null) {
      // Servo angle
      return '$deviceName - Xoay góc ${action.value}°';
    } else if (action.speed != null) {
      // Fan speed and mode
      final modeText = action.mode == 'auto'
          ? 'tự động'
          : action.mode == 'manual'
          ? 'thủ công'
          : action.mode == 'sleep'
          ? 'ngủ'
          : action.mode;
      return '$deviceName - Tốc độ ${action.speed}% (chế độ $modeText)';
    } else {
      // Relay on/off
      final actionName = actionNames[action.action] ?? action.action;
      return '$deviceName - $actionName';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _deleteRule(
    BuildContext context,
    dynamic rule,
    AutomationProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Xác nhận xóa'),
          ],
        ),
        content: Text('Bạn có chắc muốn xóa quy tắc "${rule.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteRule(rule.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã xóa quy tắc "${rule.name}"'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
