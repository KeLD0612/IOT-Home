import 'package:flutter/material.dart';
import 'widgets/condition_builder.dart';
import 'widgets/action_builder.dart';

/// Màn hình thêm quy tắc tự động mới
class AddRuleScreen extends StatefulWidget {
  const AddRuleScreen({Key? key}) : super(key: key);

  @override
  State<AddRuleScreen> createState() => _AddRuleScreenState();
}

class _AddRuleScreenState extends State<AddRuleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  // ignore: unused_field
  Map<String, dynamic> _condition = {};
  Map<String, dynamic> _action = {};
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _useTime = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm quy tắc')),
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

            // Hành động
            ActionBuilder(
              onActionChanged: (action) {
                setState(() {
                  _action = action;
                });
              },
            ),
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
      if (_action.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng thiết lập hành động'),
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
      // TODO: Implement addRule method in AutomationProvider
      // final automationProvider = Provider.of<AutomationProvider>(context, listen: false);
      // automationProvider.addRule({
      //   'name': _nameController.text,
      //   if (_condition.isNotEmpty) 'condition': _condition, // <-- chỉ thêm nếu có
      //   'action': _action,
      //   if (_useTime) 'startTime': _startTime!.format(context),
      //   if (_useTime) 'endTime': _endTime!.format(context),
      // });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm quy tắc "${_nameController.text}"'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    }
  }
}
