import 'package:flutter/material.dart';

/// Màn hình scene (kịch bản) - bật/tắt nhiều thiết bị cùng lúc
class SceneScreen extends StatelessWidget {
  const SceneScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scenes = _getScenes();

    return Scaffold(
      appBar: AppBar(title: const Text('Kịch bản')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: scenes.length,
        itemBuilder: (context, index) {
          final scene = scenes[index];
          return _buildSceneCard(context, scene);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Thêm kịch bản mới
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSceneCard(BuildContext context, SceneData scene) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          _executeScene(context, scene);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scene.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(scene.icon, color: scene.color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          scene.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          scene.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      _showSceneOptions(context, scene);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: scene.devices.map((device) {
                  return Chip(
                    label: Text(device),
                    backgroundColor: scene.color.withOpacity(0.1),
                    labelStyle: TextStyle(color: scene.color),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _executeScene(BuildContext context, SceneData scene) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đang thực hiện "${scene.name}"...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSceneOptions(BuildContext context, SceneData scene) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.play_arrow),
                title: const Text('Thực hiện'),
                onTap: () {
                  Navigator.pop(context);
                  _executeScene(context, scene);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Chỉnh sửa'),
                onTap: () {
                  Navigator.pop(context);
                  // Chỉnh sửa scene
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Xóa', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  // Xóa scene
                },
              ),
            ],
          ),
        );
      },
    );
  }

  List<SceneData> _getScenes() {
    return [
      SceneData(
        name: 'Về nhà',
        description: 'Bật đèn phòng khách, tắt chế độ bảo vệ',
        icon: Icons.home,
        color: Colors.blue,
        devices: ['Đèn phòng khách', 'Cổng'],
      ),
      SceneData(
        name: 'Đi ngủ',
        description: 'Tắt tất cả đèn, đóng cửa',
        icon: Icons.bedtime,
        color: Colors.indigo,
        devices: ['Tất cả đèn', 'Cổng', 'Mái che'],
      ),
      SceneData(
        name: 'Đi làm',
        description: 'Tắt tất cả thiết bị không cần thiết',
        icon: Icons.work,
        color: Colors.orange,
        devices: ['Đèn', 'Máy phun sương'],
      ),
      SceneData(
        name: 'Tiệc tùng',
        description: 'Bật tất cả đèn, mở cổng',
        icon: Icons.celebration,
        color: Colors.pink,
        devices: ['Tất cả đèn', 'Cổng'],
      ),
    ];
  }
}

class SceneData {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> devices;

  SceneData({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.devices,
  });
}
