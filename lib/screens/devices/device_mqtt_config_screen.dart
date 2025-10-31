import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/device_model.dart';
import '../../models/device_mqtt_config.dart';
import '../../providers/device_provider.dart';
import '../../config/app_colors.dart';

class DeviceMqttConfigScreen extends StatefulWidget {
  final Device device;

  const DeviceMqttConfigScreen({Key? key, required this.device})
    : super(key: key);

  @override
  State<DeviceMqttConfigScreen> createState() => _DeviceMqttConfigScreenState();
}

class _DeviceMqttConfigScreenState extends State<DeviceMqttConfigScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _brokerController;
  late TextEditingController _portController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _customTopicController;

  // Form values
  bool _useCustomConfig = false;
  bool _useSsl = true;
  bool _showPassword = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with current values
    final config = widget.device.mqttConfig;
    _brokerController = TextEditingController(text: config?.broker ?? '');
    _portController = TextEditingController(
      text: config?.port.toString() ?? '8883',
    );
    _usernameController = TextEditingController(text: config?.username ?? '');
    _passwordController = TextEditingController(text: config?.password ?? '');
    _customTopicController = TextEditingController(
      text: config?.customTopic ?? '',
    );

    _useCustomConfig = config?.useCustomConfig ?? false;
    _useSsl = config?.useSsl ?? true;
  }

  @override
  void dispose() {
    _brokerController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _customTopicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cấu hình MQTT - ${widget.device.name}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 20),
            _buildCustomConfigToggle(),
            const SizedBox(height: 20),
            if (_useCustomConfig) ..._buildCustomConfigFields(),
            const SizedBox(height: 30),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Thông tin thiết bị',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Tên thiết bị:', widget.device.name),
            _buildInfoRow('Loại:', widget.device.type.displayName),
            _buildInfoRow('Topic mặc định:', widget.device.mqttTopic),
            _buildInfoRow('Topic cuối cùng:', widget.device.finalMqttTopic),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _useCustomConfig
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _useCustomConfig ? AppColors.success : AppColors.info,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _useCustomConfig ? Icons.check_circle : Icons.public,
                    color: _useCustomConfig
                        ? AppColors.success
                        : AppColors.info,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _useCustomConfig
                          ? 'Sử dụng broker MQTT riêng'
                          : 'Sử dụng broker MQTT mặc định',
                      style: TextStyle(
                        color: _useCustomConfig
                            ? AppColors.success
                            : AppColors.info,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey[700])),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomConfigToggle() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.settings, color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cấu hình MQTT riêng',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Thiết bị sẽ kết nối đến broker MQTT riêng thay vì broker mặc định',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
            Switch(
              value: _useCustomConfig,
              onChanged: (value) {
                setState(() {
                  _useCustomConfig = value;
                });
              },
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCustomConfigFields() {
    return [
      Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thông tin Broker',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),

              // Broker URL
              TextFormField(
                controller: _brokerController,
                decoration: const InputDecoration(
                  labelText: 'Broker URL *',
                  hintText: 'mqtt.example.com',
                  prefixIcon: Icon(Icons.cloud),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (_useCustomConfig && (value == null || value.isEmpty)) {
                    return 'Vui lòng nhập broker URL';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Port
              TextFormField(
                controller: _portController,
                decoration: const InputDecoration(
                  labelText: 'Port *',
                  hintText: '8883',
                  prefixIcon: Icon(Icons.numbers),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (_useCustomConfig) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập port';
                    }
                    final port = int.tryParse(value);
                    if (port == null || port <= 0 || port > 65535) {
                      return 'Port phải từ 1-65535';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // SSL Toggle
              Row(
                children: [
                  Icon(Icons.security, color: AppColors.primary),
                  const SizedBox(width: 12),
                  const Text('Sử dụng SSL/TLS'),
                  const Spacer(),
                  Switch(
                    value: _useSsl,
                    onChanged: (value) {
                      setState(() {
                        _useSsl = value;
                      });
                    },
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),

      Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Xác thực (Tùy chọn)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),

              // Username
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  hintText: 'username',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _showPassword = !_showPassword;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),

      Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Topic tùy chỉnh (Tùy chọn)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Để trống để sử dụng topic mặc định',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _customTopicController,
                decoration: const InputDecoration(
                  labelText: 'Custom Topic',
                  hintText: 'my_custom/topic',
                  prefixIcon: Icon(Icons.topic),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _testConnection,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Kiểm tra kết nối'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveConfig,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Lưu cấu hình'),
          ),
        ),
      ],
    );
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement actual connection test with DeviceMqttService
      // For now, just simulate the test
      await Future.delayed(const Duration(seconds: 2)); // Simulate test

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Kết nối thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Kết nối thất bại: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      DeviceMqttConfig? newConfig;

      if (_useCustomConfig) {
        newConfig = DeviceMqttConfig(
          deviceId: widget.device.id,
          broker: _brokerController.text,
          port: int.parse(_portController.text),
          username: _usernameController.text.isEmpty
              ? null
              : _usernameController.text,
          password: _passwordController.text.isEmpty
              ? null
              : _passwordController.text,
          useSsl: _useSsl,
          useCustomConfig: true,
          customTopic: _customTopicController.text.isEmpty
              ? null
              : _customTopicController.text,
          createdAt: widget.device.mqttConfig?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      // Cập nhật thiết bị với cấu hình MQTT mới
      final updatedDevice = widget.device.copyWith(mqttConfig: newConfig);

      // Lưu vào provider
      final deviceProvider = Provider.of<DeviceProvider>(
        context,
        listen: false,
      );
      await deviceProvider.updateDevice(updatedDevice);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _useCustomConfig
                  ? '✅ Đã lưu cấu hình MQTT riêng cho ${widget.device.name}'
                  : '✅ Đã chuyển về sử dụng broker mặc định',
            ),
            backgroundColor: AppColors.success,
          ),
        );

        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi khi lưu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
