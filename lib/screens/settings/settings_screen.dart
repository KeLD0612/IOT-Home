import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/settings_provider.dart';
import '../../config/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cài đặt')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // App Settings
          _buildSectionTitle('Ứng dụng'),
          SizedBox(height: 12),
          _buildSettingsCard(
            context,
            children: [
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) {
                  return SwitchListTile(
                    title: Text('Chế độ tối'),
                    subtitle: Text('Bật giao diện tối'),
                    secondary: Icon(
                      themeProvider.isDarkMode
                          ? Icons.dark_mode
                          : Icons.light_mode,
                      color: AppColors.primary,
                    ),
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.setDarkMode(value);
                    },
                    activeColor: AppColors.primary,
                  );
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.language, color: AppColors.primary),
                title: Text('Ngôn ngữ'),
                subtitle: Text('Tiếng Việt'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showLanguageDialog(context),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Notifications
          _buildSectionTitle('Thông báo'),
          SizedBox(height: 12),
          _buildSettingsCard(
            context,
            children: [
              Consumer<SettingsProvider>(
                builder: (context, settingsProvider, _) {
                  return SwitchListTile(
                    title: Text('Bật thông báo'),
                    subtitle: Text('Nhận thông báo từ ứng dụng'),
                    secondary: Icon(
                      Icons.notifications,
                      color: AppColors.primary,
                    ),
                    value: settingsProvider.notificationsEnabled,
                    onChanged: (value) {
                      settingsProvider.setNotificationsEnabled(value);
                    },
                    activeColor: AppColors.primary,
                  );
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.tune, color: AppColors.primary),
                title: Text('Cài đặt thông báo'),
                subtitle: Text('Tùy chỉnh loại thông báo'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () =>
                    Navigator.pushNamed(context, '/notification_settings'),
              ),
            ],
          ),
          SizedBox(height: 24),

          // MQTT Settings
          _buildSectionTitle('Kết nối'),
          SizedBox(height: 12),
          _buildSettingsCard(
            context,
            children: [
              ListTile(
                leading: Icon(Icons.cloud_queue, color: AppColors.primary),
                title: Text('Cài đặt MQTT'),
                subtitle: Text('Cấu hình kết nối MQTT broker'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.pushNamed(context, '/mqtt_settings'),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Account
          _buildSectionTitle('Tài khoản'),
          SizedBox(height: 12),
          _buildSettingsCard(
            context,
            children: [
              ListTile(
                leading: Icon(Icons.person, color: AppColors.primary),
                title: Text('Thông tin tài khoản'),
                subtitle: Text('Xem và chỉnh sửa hồ sơ'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.pushNamed(context, '/account'),
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.security, color: AppColors.primary),
                title: Text('Bảo mật'),
                subtitle: Text('Đổi mật khẩu, xác thực 2 yếu tố'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showComingSoonDialog(context),
              ),
            ],
          ),
          SizedBox(height: 24),

          // About
          _buildSectionTitle('Về ứng dụng'),
          SizedBox(height: 12),
          _buildSettingsCard(
            context,
            children: [
              ListTile(
                leading: Icon(Icons.info, color: AppColors.primary),
                title: Text('Giới thiệu'),
                subtitle: Text('Phiên bản 3.0.0'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.pushNamed(context, '/about'),
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.description, color: AppColors.primary),
                title: Text('Điều khoản sử dụng'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showComingSoonDialog(context),
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.privacy_tip, color: AppColors.primary),
                title: Text('Chính sách bảo mật'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showComingSoonDialog(context),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Danger Zone
          _buildSectionTitle('Nguy hiểm'),
          SizedBox(height: 12),
          _buildSettingsCard(
            context,
            children: [
              ListTile(
                leading: Icon(Icons.refresh, color: AppColors.warning),
                title: Text('Đặt lại cài đặt'),
                subtitle: Text('Khôi phục cài đặt mặc định'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showResetDialog(context),
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.delete_forever, color: AppColors.error),
                title: Text('Xóa tất cả dữ liệu'),
                subtitle: Text('Xóa toàn bộ dữ liệu ứng dụng'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showClearDataDialog(context),
              ),
            ],
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(children: children),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chọn ngôn ngữ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Tiếng Việt'),
              leading: Radio(
                value: 'vi',
                groupValue: 'vi',
                onChanged: (value) {},
              ),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: Text('English'),
              leading: Radio(
                value: 'en',
                groupValue: 'vi',
                onChanged: (value) {},
              ),
              onTap: () {
                Navigator.pop(context);
                _showComingSoonDialog(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sắp ra mắt'),
        content: Text('Tính năng này đang được phát triển'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Đặt lại cài đặt?'),
        content: Text(
          'Bạn có chắc chắn muốn đặt lại tất cả cài đặt về mặc định?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              final settingsProvider = Provider.of<SettingsProvider>(
                context,
                listen: false,
              );
              settingsProvider.resetToDefaults();
              Navigator.pop(context);

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Đã đặt lại cài đặt')));
            },
            child: Text('Đặt lại', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xóa tất cả dữ liệu?'),
        content: Text(
          'Thao tác này sẽ xóa toàn bộ dữ liệu ứng dụng và không thể khôi phục. Bạn có chắc chắn?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showComingSoonDialog(context);
            },
            child: Text('Xóa', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
