import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/device_provider.dart';
import '../../models/device_model.dart';

class AddRoomScreen extends StatefulWidget {
  const AddRoomScreen({super.key});

  @override
  State<AddRoomScreen> createState() => _AddRoomScreenState();
}

class _AddRoomScreenState extends State<AddRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roomNameController = TextEditingController();
  String _selectedIcon = '🏠';
  bool _isLoading = false;

  // Available room icons
  final List<String> _roomIcons = [
    '🏠',
    '🛏️',
    '🍳',
    '🚿',
    '📚',
    '💼',
    '🎮',
    '🌱',
    '🏡',
    '🛋️',
    '🍽️',
    '🚪',
    '🪟',
    '🏢',
    '🎵',
    '🎨',
    '💻',
    '🔧',
    '🧹',
    '👶',
    '🎯',
    '⚡',
    '🔥',
    '❄️',
  ];

  @override
  void dispose() {
    _roomNameController.dispose();
    super.dispose();
  }

  /// 🔑 Generate device code (6 ký tự)
  String _generateDeviceCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    String result = '';

    for (int i = 0; i < 6; i++) {
      result += chars[(random + i) % chars.length];
    }

    return result;
  }

  /// Generate unique device ID
  String generateDeviceId() {
    return 'device_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Normalize device name to keyName
  String normalizeDeviceName(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll('_+', '_')
        .trim();
  }

  Future<void> _addRoomWithDevice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final deviceProvider = Provider.of<DeviceProvider>(
        context,
        listen: false,
      );

      // Create a basic device for this room to make it appear in rooms list
      final device = Device(
        id: generateDeviceId(),
        name: 'Đèn ${_roomNameController.text.trim()}',
        keyName: normalizeDeviceName('Đèn ${_roomNameController.text.trim()}'),
        deviceCode: _generateDeviceCode(), // 🔑 THÊM DEVICE CODE
        type: DeviceType.relay,
        room: _roomNameController.text.trim(),
        icon: _selectedIcon,
      );

      deviceProvider.addDevice(device);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã tạo phòng "${_roomNameController.text.trim()}" thành công!\nBạn có thể thêm thiết bị khác vào phòng này.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm phòng mới'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Preview Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Xem trước phòng',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green.shade50,
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Center(
                          child: Text(
                            _selectedIcon,
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _roomNameController.text.isEmpty
                            ? 'Tên phòng'
                            : _roomNameController.text,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Phòng mới',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Room Name Input
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thông tin phòng',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _roomNameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên phòng',
                          hintText:
                              'Nhập tên phòng (vd: Phòng khách, Phòng ngủ)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.home),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tên phòng';
                          }
                          if (value.trim().length < 2) {
                            return 'Tên phòng phải có ít nhất 2 ký tự';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {}); // Refresh preview
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Icon Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chọn biểu tượng',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 6,
                              childAspectRatio: 1,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                        itemCount: _roomIcons.length,
                        itemBuilder: (context, index) {
                          final icon = _roomIcons[index];
                          final isSelected = icon == _selectedIcon;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedIcon = icon;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: isSelected
                                    ? Colors.green.shade100
                                    : Colors.grey.shade100,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.green.shade400
                                      : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  icon,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Info Card
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade600),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Phòng mới sẽ được tạo với một thiết bị đèn mặc định. Bạn có thể thêm thiết bị khác sau.',
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Add Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addRoomWithDevice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Đang tạo phòng...'),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_home),
                            SizedBox(width: 8),
                            Text(
                              'Tạo phòng mới',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
