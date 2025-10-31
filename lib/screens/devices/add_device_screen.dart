import 'package:flutter/material.dart';
import '../../utils/device_icons.dart';

/// Màn hình thêm thiết bị mới
class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({Key? key}) : super(key: key);

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedType = 'relay';
  String _selectedRoom = 'Phòng khách';

  final List<String> _deviceTypes = ['relay', 'servo', 'sensor'];

  final List<String> _rooms = [
    'Phòng khách',
    'Phòng ngủ',
    'Bếp',
    'Sân vườn',
    'Nhà kho',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm thiết bị')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Tên thiết bị
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên thiết bị',
                hintText: 'VD: Đèn phòng khách',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.devices),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập tên thiết bị';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Loại thiết bị
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Loại thiết bị',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: _deviceTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(DeviceIcons.getDeviceIcon(type)),
                      const SizedBox(width: 8),
                      Text(_getTypeName(type)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Phòng
            DropdownButtonFormField<String>(
              value: _selectedRoom,
              decoration: const InputDecoration(
                labelText: 'Phòng',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.room),
              ),
              items: _rooms.map((room) {
                return DropdownMenuItem(value: room, child: Text(room));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRoom = value!;
                });
              },
            ),
            const SizedBox(height: 24),

            // Mô tả loại thiết bị
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'Thông tin',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getTypeDescription(_selectedType),
                      style: TextStyle(color: Colors.grey[700], height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Nút thêm
            ElevatedButton(
              onPressed: _handleAddDevice,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Thêm thiết bị',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAddDevice() {
    if (_formKey.currentState!.validate()) {
      // Thêm thiết bị mới
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm ${_nameController.text}'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    }
  }

  String _getTypeName(String type) {
    switch (type) {
      case 'relay':
        return 'Relay (Công tắc)';
      case 'servo':
        return 'Servo (Động cơ)';
      case 'sensor':
        return 'Cảm biến';
      default:
        return type;
    }
  }

  String _getTypeDescription(String type) {
    switch (type) {
      case 'relay':
        return 'Relay được sử dụng để điều khiển các thiết bị bật/tắt như đèn, quạt, máy bơm...';
      case 'servo':
        return 'Servo được sử dụng để điều khiển các thiết bị chuyển động như cửa, mái che...';
      case 'sensor':
        return 'Cảm biến được sử dụng để đo các thông số môi trường như nhiệt độ, độ ẩm...';
      default:
        return '';
    }
  }
}
