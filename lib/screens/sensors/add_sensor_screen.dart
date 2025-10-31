import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/sensor_type.dart';
import '../../models/device_mqtt_config.dart';
import '../../providers/sensor_provider.dart';
import '../../config/app_colors.dart';

class AddSensorScreen extends StatefulWidget {
  const AddSensorScreen({Key? key}) : super(key: key);

  @override
  State<AddSensorScreen> createState() => _AddSensorScreenState();
}

class _AddSensorScreenState extends State<AddSensorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _mqttTopicController = TextEditingController();
  final _maxValueController = TextEditingController(
    text: '100',
  ); // Mặc định cho phần trăm
  final _trueLabelController = TextEditingController(
    text: 'Có',
  ); // Mặc định cho boolean
  final _falseLabelController = TextEditingController(
    text: 'Không',
  ); // Mặc định cho boolean

  // 🔑 Device Code Configuration
  final _deviceCodeController = TextEditingController();
  bool _autoGenerateCode = true;

  // 📡 MQTT Configuration - BẮT BUỘC cho mọi cảm biến
  final _mqttBrokerController = TextEditingController(
    text: '16257efaa31f4843a11e19f83c34e594.s1.eu.hivemq.cloud',
  );
  final _mqttPortController = TextEditingController(text: '8883');
  final _mqttUsernameController = TextEditingController(text: 'sigma');
  final _mqttPasswordController = TextEditingController(text: '35386Doan');
  final _mqttCustomTopicController = TextEditingController();
  bool _mqttUseSsl = true;
  bool _showMqttPassword = false;

  SensorType? _selectedSensorType;
  String? _selectedIcon;
  DisplayType _displayType =
      DisplayType.boolean; // Mặc định Boolean (chỉ dùng khi cần)
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Auto-generate device code if checkbox is checked
    if (_autoGenerateCode) {
      _deviceCodeController.text = _generateDeviceCode();
      _generateMqttTopic(); // 🔥 FIX: Tự động gen topic khi init
    }
  }

  /// 🔑 GENERATE DEVICE CODE (6 KÝ TỰ)
  String _generateDeviceCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    String result = '';

    for (int i = 0; i < 6; i++) {
      result += chars[(random + i) % chars.length];
    }

    return result;
  }

  /// 📡 GENERATE MQTT TOPIC
  void _generateMqttTopic() {
    if (_deviceCodeController.text.isNotEmpty) {
      _mqttTopicController.text =
          'smart_home/sensors/${_deviceCodeController.text}/state';
    } else {
      // Auto-generate device code if not exists
      _deviceCodeController.text = _generateDeviceCode();
      _mqttTopicController.text =
          'smart_home/sensors/${_deviceCodeController.text}/state';
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _mqttTopicController.dispose();
    _maxValueController.dispose();
    _trueLabelController.dispose();
    _falseLabelController.dispose();

    // Dispose device code controller
    _deviceCodeController.dispose();

    // Dispose MQTT controllers
    _mqttBrokerController.dispose();
    _mqttPortController.dispose();
    _mqttUsernameController.dispose();
    _mqttPasswordController.dispose();
    _mqttCustomTopicController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm cảm biến'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Sensor Type Selection
            _buildSensorTypeSection(),
            const SizedBox(height: 24),

            // Display Name
            _buildDisplayNameField(),
            const SizedBox(height: 16),

            // 🔑 Device Code Field
            _buildDeviceCodeField(),
            const SizedBox(height: 16),

            // MQTT Topic
            _buildMqttTopicField(),
            const SizedBox(height: 24),

            // Display Configuration (chỉ hiển thị cho Boolean sensor)
            if (_selectedSensorType?.dataType == SensorDataType.bool) ...[
              _buildDisplayConfigSection(),
              const SizedBox(height: 24),
            ],

            // Sensor Type Info
            if (_selectedSensorType != null) _buildSensorInfo(),
            const SizedBox(height: 32),

            // 📡 MQTT Configuration Section
            _buildMqttConfigSection(),
            const SizedBox(height: 32),

            // Add Button
            _buildAddButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Loại cảm biến',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: AvailableSensorTypes.all.length,
          itemBuilder: (context, index) {
            final sensorType = AvailableSensorTypes.all[index];
            final isSelected = _selectedSensorType?.id == sensorType.id;

            return InkWell(
              onTap: () => _selectSensorType(sensorType),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Text(sensorType.icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sensorType.name,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSelected ? AppColors.primary : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDisplayNameField() {
    return TextFormField(
      controller: _displayNameController,
      decoration: const InputDecoration(
        labelText: 'Tên hiển thị *',
        hintText: 'VD: Nhiệt độ phòng khách',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Vui lòng nhập tên hiển thị';
        }
        return null;
      },
    );
  }

  Widget _buildDeviceCodeField() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _deviceCodeController,
            enabled: !_autoGenerateCode,
            decoration: InputDecoration(
              labelText: 'Mã cảm biến',
              hintText: 'Nhập mã cảm biến (3-20 ký tự)',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.vpn_key),
              suffixIcon: _autoGenerateCode
                  ? const Icon(Icons.auto_awesome, color: Colors.blue)
                  : null,
            ),
            onChanged: (value) {
              // 🔥 FIX: Tự động cập nhật MQTT topic khi user sửa device code
              setState(() {
                if (value.trim().isNotEmpty) {
                  _mqttTopicController.text =
                      'smart_home/sensors/${value.trim()}/state';
                }
              });
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập mã cảm biến';
              }
              if (value.length < 3 || value.length > 20) {
                return 'Mã cảm biến phải từ 3-20 ký tự';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 12),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: _autoGenerateCode,
              onChanged: (bool? value) {
                setState(() {
                  _autoGenerateCode = value ?? false;
                  if (_autoGenerateCode) {
                    _deviceCodeController.text = _generateDeviceCode();
                    _generateMqttTopic(); // 🔥 FIX: Gen topic khi check checkbox
                  } else {
                    _deviceCodeController.text = '';
                    _mqttTopicController.text = ''; // Clear topic khi uncheck
                  }
                });
              },
            ),
            const Text(
              'Tự động\ntạo mã',
              style: TextStyle(fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMqttTopicField() {
    return TextFormField(
      controller: _mqttTopicController,
      decoration: InputDecoration(
        labelText: 'MQTT Topic',
        hintText: _deviceCodeController.text.isNotEmpty
            ? 'smart_home/sensors/${_deviceCodeController.text}/state'
            : 'smart_home/sensors/XXXXXX/state',
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.auto_fix_high),
          onPressed: _generateMqttTopic,
          tooltip: 'Tự động tạo topic',
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Vui lòng nhập MQTT topic';
        }
        if (!value.contains('/')) {
          return 'Topic phải có định dạng: smart_home/sensors/XXXXXX/state';
        }
        return null;
      },
    );
  }

  Widget _buildSensorInfo() {
    final sensorType = _selectedSensorType!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(sensorType.icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    sensorType.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              sensorType.description,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(
                  'Đơn vị',
                  sensorType.unit.isEmpty ? 'Không có' : sensorType.unit,
                ),
                const SizedBox(width: 12),
                _buildInfoChip(
                  'Kiểu dữ liệu',
                  _getDataTypeText(sensorType.dataType),
                ),
              ],
            ),
            if (sensorType.minValue != null && sensorType.maxValue != null) ...[
              const SizedBox(height: 8),
              _buildInfoChip(
                'Phạm vi',
                '${sensorType.minValue} - ${sensorType.maxValue}',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text('$label: $value', style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildDisplayConfigSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cấu hình hiển thị',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Display Type Selection
            DropdownButtonFormField<DisplayType>(
              value: _displayType,
              decoration: const InputDecoration(
                labelText: 'Kiểu hiển thị',
                border: OutlineInputBorder(),
              ),
              items: DisplayType.values.map((type) {
                String label;
                switch (type) {
                  case DisplayType.boolean:
                    label = 'Có/Không (On/Off)';
                    break;
                  case DisplayType.pulse:
                    label = 'Xung (Pulse)';
                    break;
                  case DisplayType.percentage:
                    label = 'Phần trăm (%)';
                    break;
                }
                return DropdownMenuItem(value: type, child: Text(label));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _displayType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Conditional configuration based on display type
            if (_displayType == DisplayType.boolean) ...[
              TextFormField(
                controller: _trueLabelController,
                decoration: const InputDecoration(
                  labelText: 'Nhãn khi TRUE',
                  hintText: 'Bật, Có, On...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _falseLabelController,
                decoration: const InputDecoration(
                  labelText: 'Nhãn khi FALSE',
                  hintText: 'Tắt, Không, Off...',
                  border: OutlineInputBorder(),
                ),
              ),
            ] else if (_displayType == DisplayType.percentage) ...[
              TextFormField(
                controller: _maxValueController,
                decoration: const InputDecoration(
                  labelText: 'Giá trị tối đa (100%)',
                  hintText: 'Ví dụ: 1024 cho analog',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (_displayType == DisplayType.percentage &&
                      (value == null || value.trim().isEmpty)) {
                    return 'Vui lòng nhập giá trị tối đa';
                  }
                  if (value != null && value.isNotEmpty) {
                    final number = double.tryParse(value);
                    if (number == null || number <= 0) {
                      return 'Vui lòng nhập số dương';
                    }
                  }
                  return null;
                },
              ),
            ],

            const SizedBox(height: 16),

            // Icon Selection
            Text(
              'Icon tùy chỉnh (tùy chọn)',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _showIconPicker,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      _selectedIcon ?? (_selectedSensorType?.icon ?? '📊'),
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _selectedIcon != null
                          ? 'Icon tùy chỉnh'
                          : 'Dùng icon mặc định',
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMqttConfigSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wifi, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cấu hình MQTT (Bắt buộc)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        'Mọi cảm biến phải có cấu hình MQTT để hoạt động',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Broker URL
            TextFormField(
              controller: _mqttBrokerController,
              decoration: const InputDecoration(
                labelText: 'Broker URL *',
                hintText: 'mqtt.example.com',
                prefixIcon: Icon(Icons.cloud),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập broker URL';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),

            // Quick select broker chips
            Wrap(
              spacing: 8,
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      _mqttBrokerController.text =
                          '16257efaa31f4843a11e19f83c34e594.s1.eu.hivemq.cloud';
                    });
                  },
                  child: Chip(
                    avatar: const Icon(
                      Icons.cloud_circle,
                      size: 18,
                      color: Colors.blue,
                    ),
                    label: const Text(
                      'Broker 94',
                      style: TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.blue.shade50,
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      _mqttBrokerController.text =
                          '26d1fcc0724b46c495e45a93d79c78d2.s1.eu.hivemq.cloud';
                    });
                  },
                  child: Chip(
                    avatar: const Icon(
                      Icons.cloud_circle,
                      size: 18,
                      color: Colors.green,
                    ),
                    label: const Text(
                      'Broker 78',
                      style: TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.green.shade50,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Port
            TextFormField(
              controller: _mqttPortController,
              decoration: const InputDecoration(
                labelText: 'Port *',
                hintText: '8883',
                prefixIcon: Icon(Icons.numbers),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập port';
                }
                final port = int.tryParse(value);
                if (port == null || port <= 0 || port > 65535) {
                  return 'Port phải từ 1-65535';
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
                  value: _mqttUseSsl,
                  onChanged: (value) {
                    setState(() {
                      _mqttUseSsl = value;
                    });
                  },
                  activeColor: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Username
            TextFormField(
              controller: _mqttUsernameController,
              decoration: const InputDecoration(
                labelText: 'Username (tùy chọn)',
                hintText: 'username',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Password
            TextFormField(
              controller: _mqttPasswordController,
              obscureText: !_showMqttPassword,
              decoration: InputDecoration(
                labelText: 'Password (tùy chọn)',
                hintText: 'password',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showMqttPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _showMqttPassword = !_showMqttPassword;
                    });
                  },
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Custom Topic
            TextFormField(
              controller: _mqttCustomTopicController,
              decoration: const InputDecoration(
                labelText: 'Topic tùy chỉnh (tùy chọn)',
                hintText: 'my_custom/topic',
                prefixIcon: Icon(Icons.topic),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Để trống để sử dụng topic mặc định: ${_displayNameController.text.toLowerCase().replaceAll(' ', '_')}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _addSensor,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text('Thêm cảm biến'),
      ),
    );
  }

  void _selectSensorType(SensorType sensorType) {
    setState(() {
      _selectedSensorType = sensorType;

      // Auto-fill tên hiển thị nếu chưa có
      if (_displayNameController.text.isEmpty) {
        _displayNameController.text = sensorType.name;
      }

      // Auto-generate MQTT topic nếu chưa có
      if (_mqttTopicController.text.isEmpty) {
        _generateMqttTopic();
      }

      // 🎯 Tự động thiết lập giá trị mặc định dựa trên loại cảm biến
      _setDefaultValuesForSensorType(sensorType);
    });
  }

  /// Thiết lập giá trị mặc định dựa trên loại cảm biến
  void _setDefaultValuesForSensorType(SensorType sensorType) {
    // Chỉ áp dụng cho cảm biến không phải tùy chỉnh
    if (sensorType.id == 'custom') return;

    // ⚡ QUAN TRỌNG: Không set displayType mặc định!
    // Để null → sensor sẽ hiển thị giá trị thô + unit (ví dụ: 25.5°C)
    // User có thể tự chọn DisplayType nếu muốn custom hiển thị

    // Chỉ set gợi ý cho maxValue nếu có
    switch (sensorType.dataType) {
      case SensorDataType.double:
        // Nếu có maxValue trong sensorType, dùng nó
        if (sensorType.maxValue != null) {
          _maxValueController.text = sensorType.maxValue.toString();
        }
        break;
      case SensorDataType.int:
        // Nếu có maxValue trong sensorType, dùng nó
        if (sensorType.maxValue != null) {
          _maxValueController.text = sensorType.maxValue.toString();
        }
        break;
      case SensorDataType.bool:
        // Boolean có thể set nhãn mặc định
        _displayType = DisplayType.boolean;
        _trueLabelController.text = 'Có';
        _falseLabelController.text = 'Không';
        break;
    }

    // Thiết lập icon mặc định dựa trên loại cảm biến
    _selectedIcon = _getDefaultIconForSensorType(sensorType);
  }

  /// Lấy icon mặc định cho loại cảm biến
  String _getDefaultIconForSensorType(SensorType sensorType) {
    switch (sensorType.id) {
      case 'temperature':
        return '🌡️';
      case 'humidity':
        return '💧';
      case 'light':
        return '💡';
      case 'motion':
        return '⚡'; // Sử dụng ⚡ cho motion
      case 'door':
        return '🚪';
      case 'window':
        return '🪟';
      case 'smoke':
        return '🔥';
      case 'rain':
        return '🌊';
      case 'wind':
        return '💨';
      case 'pressure':
        return '📊';
      case 'noise':
        return '🔔';
      case 'dust':
        return '🌪️'; // Sử dụng 🌪️ cho dust (có trong danh sách)
      case 'soil_moisture':
        return '💧';
      case 'ph':
        return '⚙️'; // Sử dụng ⚙️ cho pH (có trong danh sách)
      case 'co2':
        return '🌿'; // Giữ nguyên 🌿, sẽ fallback về 📡 nếu không có
      case 'gas':
        return '🔥';
      default:
        return '📡'; // Icon mặc định
    }
  }

  void _showIconPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn Icon'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              childAspectRatio: 1,
            ),
            itemCount: _commonIcons.length,
            itemBuilder: (context, index) {
              final icon = _commonIcons[index];
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedIcon = icon;
                  });
                  Navigator.of(context).pop();
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedIcon == icon
                          ? Theme.of(context).primaryColor
                          : Colors.transparent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(icon, style: const TextStyle(fontSize: 24)),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedIcon = null;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Dùng mặc định'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }

  static const List<String> _commonIcons = [
    '🌡️',
    '💧',
    '💨',
    '💡',
    '🔥',
    '⚡',
    '📊',
    '📈',
    '🔔',
    '🚨',
    '⚠️',
    '✅',
    '❌',
    '🟢',
    '🔴',
    '🟡',
    '🔵',
    '⚪',
    '🌪️',
    '🌊',
    '🔋',
    '⚙️',
    '🎛️',
    '📡',
    '🏠',
    '🚪',
    '🪟',
    '🛡️',
    '🔒',
    '🔓',
    '📱',
    '💻',
    '⌚',
    '🎯',
    '📍',
    '🔍',
  ];

  String _getDataTypeText(SensorDataType dataType) {
    switch (dataType) {
      case SensorDataType.double:
        return 'Số thực';
      case SensorDataType.int:
        return 'Số nguyên';
      case SensorDataType.bool:
        return 'True/False';
    }
  }

  Future<void> _addSensor() async {
    if (!_formKey.currentState!.validate() || _selectedSensorType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng điền đầy đủ thông tin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final sensorProvider = Provider.of<SensorProvider>(
        context,
        listen: false,
      );

      // ⚡ CHỈ tạo DisplayConfig khi sensor dataType là bool
      // Các sensor khác (double, int) sẽ hiển thị giá trị thô + unit
      DisplayConfig? displayConfig;

      // Chỉ tạo DisplayConfig cho Boolean type
      if (_selectedSensorType!.dataType == SensorDataType.bool) {
        displayConfig = DisplayConfig(
          type: DisplayType.boolean,
          trueLabel: _trueLabelController.text.trim().isNotEmpty
              ? _trueLabelController.text.trim()
              : 'Có',
          falseLabel: _falseLabelController.text.trim().isNotEmpty
              ? _falseLabelController.text.trim()
              : 'Không',
        );
      }
      // Nếu muốn, có thể uncomment để cho phép user custom percentage/pulse
      // else {
      //   switch (_displayType) {
      //     case DisplayType.percentage:
      //       final maxValue = double.tryParse(_maxValueController.text.trim());
      //       if (maxValue != null && maxValue > 0) {
      //         displayConfig = DisplayConfig(
      //           type: DisplayType.percentage,
      //           maxValue: maxValue,
      //         );
      //       }
      //       break;
      //     case DisplayType.pulse:
      //       displayConfig = DisplayConfig(type: DisplayType.pulse);
      //       break;
      //     default:
      //       displayConfig = null;
      //   }
      // }

      // Tạo cấu hình MQTT (bắt buộc)
      final mqttConfig = DeviceMqttConfig(
        deviceId: '', // Sẽ được set sau khi tạo sensor
        broker: _mqttBrokerController.text,
        port: int.parse(_mqttPortController.text),
        username: _mqttUsernameController.text.isEmpty
            ? null
            : _mqttUsernameController.text,
        password: _mqttPasswordController.text.isEmpty
            ? null
            : _mqttPasswordController.text,
        useSsl: _mqttUseSsl,
        useCustomConfig: true,
        customTopic: _deviceCodeController.text.isEmpty
            ? null
            : 'smart_home/sensors/${_deviceCodeController.text}/state',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Tạo configuration map
      final configuration = <String, dynamic>{};
      if (displayConfig != null) {
        configuration['displayConfig'] = displayConfig.toJson();
      }
      if (_selectedIcon != null) {
        configuration['customIcon'] = _selectedIcon;
      }

      await sensorProvider.addSensor(
        sensorTypeId: _selectedSensorType!.id,
        displayName: _displayNameController.text.trim(),
        customMqttTopic: _mqttTopicController.text.trim(),
        deviceCode: _deviceCodeController.text.trim(),
        configuration: configuration,
        mqttConfig: mqttConfig,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Đã thêm cảm biến "${_displayNameController.text}"',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true để báo đã thêm sensor
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
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
}
