import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/automation_provider.dart';
import '../../config/app_colors.dart';

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
    return Card(
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
                          '${rule.conditions.length} điều kiện • ${rule.actions.length} hành động',
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
                          style: TextStyle(fontSize: 12, color: AppColors.info),
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

  void _showRuleDetail(BuildContext context, rule) {
    Navigator.pushNamed(context, '/edit_rule', arguments: rule);
  }
}
