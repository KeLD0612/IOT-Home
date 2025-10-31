import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/sensor_provider.dart';
import '../../providers/automation_provider.dart';

/// Màn hình hồ sơ người dùng
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Chỉnh sửa hồ sơ
            },
          ),
        ],
      ),
      body: ListView(
        key: const PageStorageKey<String>('profile_list'),
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar và thông tin cơ bản
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.blue[100],
                      child: const Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.blue,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Nguyễn Văn A',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'nguyenvana@email.com',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Thông tin chi tiết
          Card(
            child: Column(
              children: [
                _buildInfoTile(
                  icon: Icons.phone,
                  title: 'Số điện thoại',
                  value: '0123 456 789',
                  onTap: () {},
                ),
                const Divider(height: 1),
                _buildInfoTile(
                  icon: Icons.location_on,
                  title: 'Địa chỉ',
                  value: 'TP. Hồ Chí Minh',
                  onTap: () {},
                ),
                const Divider(height: 1),
                _buildInfoTile(
                  icon: Icons.cake,
                  title: 'Ngày sinh',
                  value: '01/01/1990',
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Cài đặt
          Card(
            child: Column(
              children: [
                _buildActionTile(
                  icon: Icons.lock,
                  title: 'Đổi mật khẩu',
                  onTap: () {
                    // Đổi mật khẩu
                  },
                ),
                const Divider(height: 1),
                _buildActionTile(
                  icon: Icons.notifications,
                  title: 'Cài đặt thông báo',
                  onTap: () {
                    // Cài đặt thông báo
                  },
                ),
                const Divider(height: 1),
                _buildActionTile(
                  icon: Icons.privacy_tip,
                  title: 'Chính sách bảo mật',
                  onTap: () {
                    // Chính sách bảo mật
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Đăng xuất
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Đăng xuất',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _showLogoutDialog(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(value),
      trailing: const Icon(Icons.edit, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                // 🗑️ CLEAR ALL PROVIDER DATA FIRST
                final deviceProvider = Provider.of<DeviceProvider>(
                  context,
                  listen: false,
                );
                final sensorProvider = Provider.of<SensorProvider>(
                  context,
                  listen: false,
                );
                final automationProvider = Provider.of<AutomationProvider>(
                  context,
                  listen: false,
                );
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );

                print('🗑️ Clearing all provider data before logout...');
                await deviceProvider.clearUserData();
                sensorProvider.clearUserData();
                automationProvider.clearUserData();
                print('✅ All provider data cleared');

                // Call signOut method
                await authProvider.signOut();

                // Navigate to login screen
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false, // Remove all previous routes
                  );

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Đăng xuất thành công'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Lỗi đăng xuất: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}
