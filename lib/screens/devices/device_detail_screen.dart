import 'package:flutter/material.dart';

/// Màn hình chi tiết thiết bị
class DeviceDetailScreen extends StatelessWidget {
  final String deviceId;
  final String deviceName;
  final String deviceType;

  const DeviceDetailScreen({
    Key? key,
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(deviceName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Chỉnh sửa thiết bị
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              _showDeleteDialog(context);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Thông tin cơ bản
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin thiết bị',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Tên', deviceName),
                  const Divider(),
                  _buildInfoRow('Loại', _getDeviceTypeName(deviceType)),
                  const Divider(),
                  _buildInfoRow('ID', deviceId),
                  const Divider(),
                  _buildInfoRow(
                    'Trạng thái',
                    'Đang hoạt động',
                    valueColor: Colors.green,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Lịch sử hoạt động
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lịch sử hoạt động',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildActivityItem(
                    'Bật',
                    DateTime.now().subtract(const Duration(hours: 2)),
                    Icons.power_settings_new,
                    Colors.green,
                  ),
                  _buildActivityItem(
                    'Tắt',
                    DateTime.now().subtract(const Duration(hours: 5)),
                    Icons.power_off,
                    Colors.grey,
                  ),
                  _buildActivityItem(
                    'Bật',
                    DateTime.now().subtract(const Duration(hours: 8)),
                    Icons.power_settings_new,
                    Colors.green,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Thống kê
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thống kê',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Hôm nay', '3 giờ', Icons.today),
                      _buildStatItem(
                        'Tuần này',
                        '24 giờ',
                        Icons.calendar_view_week,
                      ),
                      _buildStatItem(
                        'Tháng này',
                        '120 giờ',
                        Icons.calendar_month,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    String action,
    DateTime time,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  _formatTime(time),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  String _getDeviceTypeName(String type) {
    switch (type) {
      case 'relay':
        return 'Relay (Công tắc)';
      case 'servo':
        return 'Servo (Động cơ)';
      default:
        return type;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inHours < 1) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} giờ trước';
    } else {
      return '${difference.inDays} ngày trước';
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa thiết bị'),
        content: Text('Bạn có chắc muốn xóa "$deviceName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              // Xóa thiết bị
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
