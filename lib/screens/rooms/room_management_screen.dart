import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/device_provider.dart';
import '../../models/device_model.dart';
import '../../config/app_colors.dart';

class RoomManagementScreen extends StatefulWidget {
  const RoomManagementScreen({super.key});

  @override
  State<RoomManagementScreen> createState() => _RoomManagementScreenState();
}

class _RoomManagementScreenState extends State<RoomManagementScreen> {
  final _roomNameController = TextEditingController();
  String? _editingRoomId;
  bool _isEditing = false;
  String? _selectedAvatar;
  String? _selectedRoomForMove;

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

  @override
  void dispose() {
    _roomNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý phòng'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<DeviceProvider>(
        builder: (context, deviceProvider, child) {
          final rooms = deviceProvider.availableRooms;

          return Column(
            children: [
              // Header với thống kê
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Tổng số phòng: ${rooms.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Quản lý và tổ chức các phòng trong nhà',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Danh sách phòng
              Expanded(
                child: rooms.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: rooms.length,
                        itemBuilder: (context, index) {
                          final room = rooms[index];
                          final deviceCount = deviceProvider.devices
                              .where((d) => d.room == room)
                              .length;

                          // Lấy avatar của phòng từ thiết bị đầu tiên trong phòng
                          final roomDevice = deviceProvider.devices
                              .where((d) => d.room == room)
                              .firstOrNull;
                          final roomAvatar = roomDevice?.icon ?? '🏠';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary.withOpacity(
                                  0.1,
                                ),
                                child: Text(
                                  roomAvatar,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                              title: Text(
                                room,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                '$deviceCount thiết bị',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _editRoom(room, roomAvatar);
                                  } else if (value == 'move_devices') {
                                    _moveDevicesToOtherRoom(
                                      room,
                                      deviceProvider,
                                    );
                                  } else if (value == 'delete') {
                                    _deleteRoom(room, deviceProvider);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem<String>(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 20),
                                        SizedBox(width: 8),
                                        Text('Sửa phòng'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem<String>(
                                    value: 'move_devices',
                                    child: Row(
                                      children: [
                                        Icon(Icons.swap_horiz, size: 20),
                                        SizedBox(width: 8),
                                        Text('Chuyển thiết bị'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete,
                                          size: 20,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Xóa phòng',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                icon: const Icon(Icons.more_vert),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewRoom,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.room_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Chưa có phòng nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thêm phòng đầu tiên để tổ chức thiết bị',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addNewRoom,
            icon: const Icon(Icons.add),
            label: const Text('Thêm phòng'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _addNewRoom() {
    _roomNameController.clear();
    _isEditing = false;
    _editingRoomId = null;
    _showRoomDialog();
  }

  void _editRoom(String roomName, String currentAvatar) {
    _roomNameController.text = roomName;
    _selectedAvatar = currentAvatar;
    _isEditing = true;
    _editingRoomId = roomName;
    _showRoomDialog();
  }

  void _moveDevicesToOtherRoom(String fromRoom, DeviceProvider deviceProvider) {
    final devicesInRoom = deviceProvider.devices
        .where((d) => d.room == fromRoom && !d.id.startsWith('room_'))
        .toList();

    if (devicesInRoom.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Phòng "$fromRoom" không có thiết bị nào để chuyển'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _showMoveDevicesDialog(fromRoom, devicesInRoom, deviceProvider);
  }

  void _showRoomDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isEditing ? 'Sửa phòng' : 'Thêm phòng mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _roomNameController,
                decoration: const InputDecoration(
                  labelText: 'Tên phòng',
                  hintText: 'VD: Phòng khách, Phòng ngủ, Nhà bếp',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.room),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              // Avatar picker
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chọn avatar:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 120,
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 6,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: _availableAvatars.length,
                      itemBuilder: (context, index) {
                        final avatar = _availableAvatars[index];
                        final isSelected = _selectedAvatar == avatar;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedAvatar = avatar;
                            });
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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: _saveRoom,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(_isEditing ? 'Cập nhật' : 'Thêm'),
          ),
        ],
      ),
    );
  }

  void _saveRoom() async {
    final roomName = _roomNameController.text.trim();

    if (roomName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tên phòng'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedAvatar == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn avatar cho phòng'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);

    try {
      if (_isEditing) {
        // Sửa phòng (tên và avatar)
        await deviceProvider.updateRoom(
          _editingRoomId!,
          roomName,
          _selectedAvatar!,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Đã cập nhật phòng "$roomName"'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Thêm phòng mới - chỉ tạo phòng trống, không tự động thêm thiết bị
        await deviceProvider.addEmptyRoom(roomName, _selectedAvatar!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Đã thêm phòng "$roomName"'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showMoveDevicesDialog(
    String fromRoom,
    List<Device> devicesInRoom,
    DeviceProvider deviceProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chuyển thiết bị từ "$fromRoom"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Chọn phòng đích để chuyển ${devicesInRoom.length} thiết bị:'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRoomForMove,
              decoration: const InputDecoration(
                labelText: 'Phòng đích',
                border: OutlineInputBorder(),
              ),
              items: deviceProvider.availableRooms
                  .where((room) => room != fromRoom)
                  .map(
                    (room) => DropdownMenuItem(value: room, child: Text(room)),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRoomForMove = value;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: _selectedRoomForMove != null
                ? () async {
                    try {
                      for (final device in devicesInRoom) {
                        await deviceProvider.moveDeviceToRoom(
                          device.id,
                          _selectedRoomForMove!,
                        );
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '✅ Đã chuyển ${devicesInRoom.length} thiết bị sang "$_selectedRoomForMove"',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                      Navigator.pop(context);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('❌ Lỗi: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Chuyển'),
          ),
        ],
      ),
    );
  }

  void _deleteRoom(String roomName, DeviceProvider deviceProvider) async {
    final deviceCount = deviceProvider.devices
        .where((d) => d.room == roomName)
        .length;

    if (deviceCount > 0) {
      // Không cho phép xóa phòng có thiết bị
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Không thể xóa phòng'),
          content: Text(
            'Phòng "$roomName" đang có $deviceCount thiết bị.\n'
            'Vui lòng di chuyển hoặc xóa các thiết bị trước khi xóa phòng.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
      return;
    }

    // Xác nhận xóa phòng trống
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa phòng'),
        content: Text('Bạn có chắc chắn muốn xóa phòng "$roomName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await deviceProvider.deleteRoom(roomName);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Đã xóa phòng "$roomName"'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
