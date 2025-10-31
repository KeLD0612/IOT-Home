import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/device_provider.dart';
import '../home/widgets/room_card.dart';
import 'room_detail_screen.dart';
import '../../config/app_colors.dart';

/// Màn hình danh sách các phòng - Lấy device count thật từ DeviceProvider
class RoomsScreen extends StatelessWidget {
  RoomsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceProvider>(
      builder: (context, deviceProvider, _) {
        final rooms = _getRoomsWithRealCounts(deviceProvider);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Phòng'),
            actions: [
              Text(
                '${deviceProvider.devicesCount} thiết bị',
                style: TextStyle(fontSize: 12),
              ),
              SizedBox(width: 16),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => Navigator.pushNamed(context, '/add_room'),
            backgroundColor: Colors.green.shade600,
            child: Icon(Icons.add_home, color: Colors.white),
            tooltip: 'Thêm phòng mới',
          ),
          body: rooms.isEmpty
              ? _buildEmptyState(context)
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    return RoomCard(
                      roomName: room['name'],
                      icon: room['icon'],
                      deviceCount: room['deviceCount'],
                      activeDevices: room['activeDevices'],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RoomDetailScreen(
                              roomId: room['id'],
                              roomName: room['name'],
                              icon: room['icon'],
                            ),
                          ),
                        );
                      },
                      onEdit: () => _editRoom(
                        context,
                        room['name'],
                        room['icon'],
                        deviceProvider,
                      ),
                      onDelete: () =>
                          _deleteRoom(context, room['name'], deviceProvider),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_outlined, size: 80, color: Colors.grey[400]),
            SizedBox(height: 24),
            Text(
              'Chưa có phòng nào',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Thêm thiết bị và phân bổ vào phòng để bắt đầu quản lý',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
            SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/add_room'),
                  icon: Icon(Icons.add_home),
                  label: Text('Tạo phòng'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/add_device'),
                  icon: Icon(Icons.add),
                  label: Text('Thêm thiết bị'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Tính device count thật từ DeviceProvider - DYNAMIC, KHÔNG HARD-CODE
  List<Map<String, dynamic>> _getRoomsWithRealCounts(DeviceProvider provider) {
    final allDevices = provider.devices;

    return [
      // Dynamic rooms based on actual devices
      ...getRoomsFromDevices(allDevices),
    ];
  }

  List<Map<String, dynamic>> getRoomsFromDevices(List<dynamic> allDevices) {
    if (allDevices.isEmpty) {
      return []; // Không có devices thì không có phòng nào
    }

    // Group devices theo room field
    Map<String, List<dynamic>> roomDevicesMap = {};
    for (final device in allDevices) {
      final roomName = device.room ?? 'Không xác định';
      roomDevicesMap[roomName] ??= [];
      roomDevicesMap[roomName]!.add(device);
    }

    // Convert thành list cho GridView
    List<Map<String, dynamic>> rooms = [];
    roomDevicesMap.forEach((roomName, devices) {
      final activeDevices = devices.where((d) => d.state).length;

      rooms.add({
        'id': roomName.toLowerCase().replaceAll(' ', '_'),
        'name': roomName,
        'icon': _getRoomIcon(roomName),
        'deviceCount': devices.length,
        'activeDevices': activeDevices,
      });
    });

    return rooms;
  }

  IconData _getRoomIcon(String roomName) {
    final lowerCaseRoom = roomName.toLowerCase();
    if (lowerCaseRoom.contains('khách') || lowerCaseRoom.contains('living')) {
      return Icons.living;
    } else if (lowerCaseRoom.contains('ngủ') ||
        lowerCaseRoom.contains('bedroom')) {
      return Icons.bed;
    } else if (lowerCaseRoom.contains('bếp') ||
        lowerCaseRoom.contains('kitchen')) {
      return Icons.kitchen;
    } else if (lowerCaseRoom.contains('tắm') ||
        lowerCaseRoom.contains('bathroom')) {
      return Icons.bathtub;
    } else if (lowerCaseRoom.contains('sân') ||
        lowerCaseRoom.contains('vườn') ||
        lowerCaseRoom.contains('garden')) {
      return Icons.yard;
    } else if (lowerCaseRoom.contains('garage') ||
        lowerCaseRoom.contains('nhà xe')) {
      return Icons.garage;
    } else {
      return Icons.room;
    }
  }

  // Phương thức sửa phòng
  void _editRoom(
    BuildContext context,
    String roomName,
    IconData currentIcon,
    DeviceProvider deviceProvider,
  ) {
    final TextEditingController roomNameController = TextEditingController(
      text: roomName,
    );
    String selectedAvatar = _getRoomIconString(currentIcon);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sửa phòng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: roomNameController,
              decoration: const InputDecoration(
                labelText: 'Tên phòng',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chọn avatar:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _availableAvatars.length,
                itemBuilder: (context, index) {
                  final avatar = _availableAvatars[index];
                  final isSelected = selectedAvatar == avatar;

                  return GestureDetector(
                    onTap: () {
                      selectedAvatar = avatar;
                      Navigator.pop(context);
                      _editRoom(
                        context,
                        roomNameController.text,
                        _getIconFromString(avatar),
                        deviceProvider,
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.2)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          avatar,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newRoomName = roomNameController.text.trim();
              if (newRoomName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập tên phòng'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                await deviceProvider.updateRoom(
                  roomName,
                  newRoomName,
                  selectedAvatar,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Đã cập nhật phòng "$newRoomName"'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
                Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Lỗi: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  // Phương thức xóa phòng
  void _deleteRoom(
    BuildContext context,
    String roomName,
    DeviceProvider deviceProvider,
  ) async {
    final deviceCount = deviceProvider.devices
        .where((d) => d.room == roomName)
        .length;

    if (deviceCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Không thể xóa phòng "$roomName" vì còn $deviceCount thiết bị',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa phòng "$roomName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await deviceProvider.deleteRoom(roomName);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Đã xóa phòng "$roomName"'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // Danh sách avatar có sẵn
  final List<String> _availableAvatars = [
    '🏠',
    '🏡',
    '🏢',
    '🏬',
    '🏭',
    '🏪',
    '🏫',
    '🏩',
    '🏨',
    '🏦',
    '🏥',
    '🏤',
    '🏣',
    '🏰',
    '🏯',
    '🏮',
    '🏭',
    '🏬',
    '🏫',
    '🏪',
    '🏨',
    '🏦',
    '🏥',
    '🏤',
    '🏣',
    '🏰',
    '🏯',
    '🏮',
    '🏭',
    '🏬',
    '🏫',
    '🏪',
    '🏨',
    '🏦',
    '🏥',
    '🏤',
    '🏣',
    '🏰',
    '🏯',
    '🏮',
  ];

  // Helper methods để convert giữa IconData và String
  String _getRoomIconString(IconData icon) {
    // Map IconData to emoji string
    if (icon == Icons.living) return '🏠';
    if (icon == Icons.bed) return '🛏️';
    if (icon == Icons.kitchen) return '🍳';
    if (icon == Icons.bathtub) return '🛁';
    if (icon == Icons.yard) return '🌳';
    if (icon == Icons.garage) return '🚗';
    return '🏠'; // default
  }

  IconData _getIconFromString(String emoji) {
    // Map emoji string to IconData
    if (emoji == '🏠' || emoji == '🏡') return Icons.living;
    if (emoji == '🛏️') return Icons.bed;
    if (emoji == '🍳') return Icons.kitchen;
    if (emoji == '🛁') return Icons.bathtub;
    if (emoji == '🌳') return Icons.yard;
    if (emoji == '🚗') return Icons.garage;
    return Icons.room; // default
  }
}
