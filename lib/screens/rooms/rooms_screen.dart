import 'package:flutter/material.dart';
import '../home/widgets/room_card.dart';
import 'room_detail_screen.dart';

/// Màn hình danh sách các phòng
class RoomsScreen extends StatelessWidget {
  const RoomsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final rooms = _getRooms();

    return Scaffold(
      appBar: AppBar(title: const Text('Phòng')),
      body: GridView.builder(
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddRoomDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  List<Map<String, dynamic>> _getRooms() {
    return [
      {
        'id': 'living_room',
        'name': 'Phòng khách',
        'icon': Icons.living,
        'deviceCount': 2,
        'activeDevices': 1,
      },
      {
        'id': 'bedroom',
        'name': 'Phòng ngủ',
        'icon': Icons.bed,
        'deviceCount': 0,
        'activeDevices': 0,
      },
      {
        'id': 'kitchen',
        'name': 'Bếp',
        'icon': Icons.kitchen,
        'deviceCount': 0,
        'activeDevices': 0,
      },
      {
        'id': 'bathroom',
        'name': 'Phòng tắm',
        'icon': Icons.bathtub,
        'deviceCount': 0,
        'activeDevices': 0,
      },
      {
        'id': 'garden',
        'name': 'Sân vườn',
        'icon': Icons.yard,
        'deviceCount': 3,
        'activeDevices': 1,
      },
      {
        'id': 'entrance',
        'name': 'Lối vào',
        'icon': Icons.door_front_door,
        'deviceCount': 1,
        'activeDevices': 0,
      },
    ];
  }

  void _showAddRoomDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm phòng mới'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Tên phòng',
            hintText: 'VD: Phòng ngủ tầng 2',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã thêm phòng "${nameController.text}"'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }
}
