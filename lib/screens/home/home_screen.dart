import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/mqtt_provider.dart';
import '../../providers/sensor_provider.dart';
import '../../providers/device_provider.dart';
import '../../config/app_colors.dart';
import 'widgets/animated_sensor_card.dart';
import 'widgets/device_quick_control.dart';
import 'widgets/status_indicator.dart';
import 'widgets/alert_banner.dart';
import 'widgets/weather_widget.dart';
import 'widgets/room_card.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Smart Home'),
        actions: [
          // Connection Status
          Consumer<MqttProvider>(
            builder: (context, mqtt, _) {
              return StatusIndicator(
                isOnline: mqtt.isConnected,
                label: mqtt.connectionStatus,
              );
            },
          ),
          SizedBox(width: 16),
        ],
      ),

      body: _buildBody(),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);

          // Navigate to screens
          switch (index) {
            case 0:
              // Already on home
              break;
            case 1:
              Navigator.pushNamed(context, '/devices');
              break;
            case 2:
              Navigator.pushNamed(context, '/sensors');
              break;
            case 3:
              Navigator.pushNamed(context, '/automation');
              break;
            case 4:
              Navigator.pushNamed(context, '/settings');
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.devices), label: 'Thiết bị'),
          BottomNavigationBarItem(icon: Icon(Icons.sensors), label: 'Cảm biến'),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: 'Tự động',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Cài đặt'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Alert Banner
            Consumer<SensorProvider>(
              builder: (context, sensor, _) {
                final gasValue = sensor.currentData.gas;
                final dustValue = sensor.currentData.dust;

                if (gasValue > 1500) {
                  return AlertBanner(
                    type: AlertType.gas,
                    message: 'Cảnh báo: Nồng độ gas cao!',
                    value: gasValue,
                  );
                }
                if (dustValue > 150) {
                  return AlertBanner(
                    type: AlertType.dust,
                    message: 'Cảnh báo: Bụi mịn cao!',
                    value: dustValue,
                  );
                }
                return SizedBox.shrink();
              },
            ),

            SizedBox(height: 16),

            // Weather Widget
            WeatherWidget(),

            SizedBox(height: 24),

            // Sensors Section
            Text(
              'Cảm biến',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 16),

            Consumer<SensorProvider>(
              builder: (context, sensor, _) {
                final data = sensor.currentData;
                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.0,
                  children: [
                    AnimatedSensorCard(
                      icon: Icons.thermostat,
                      title: 'Nhiệt độ',
                      value: '${data.temperature.toStringAsFixed(1)}°C',
                      color: AppColors.temperature,
                    ),
                    AnimatedSensorCard(
                      icon: Icons.water_drop,
                      title: 'Độ ẩm',
                      value: '${data.humidity.toStringAsFixed(1)}%',
                      color: AppColors.humidity,
                    ),
                    AnimatedSensorCard(
                      icon: Icons.air,
                      title: 'Chất lượng KK',
                      value: '${data.dust}',
                      color: AppColors.dust,
                    ),
                    AnimatedSensorCard(
                      icon: Icons.grass,
                      title: 'Độ ẩm đất',
                      value: '${data.soilMoisture}%',
                      color: AppColors.soil,
                    ),
                  ],
                );
              },
            ),

            SizedBox(height: 32),

            // Devices Section
            Text(
              'Điều khiển nhanh',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 16),

            Consumer<DeviceProvider>(
              builder: (context, device, _) {
                return Column(
                  children: [
                    DeviceQuickControl(
                      icon: Icons.water_drop,
                      title: 'Máy bơm',
                      isOn: device.pumpState,
                      onToggle: (value) => device.togglePump(value),
                      color: AppColors.pumpColor,
                    ),
                    SizedBox(height: 12),
                    DeviceQuickControl(
                      icon: Icons.lightbulb,
                      title: 'Đèn phòng khách',
                      isOn: device.lightLivingState,
                      onToggle: (value) => device.toggleLightLiving(value),
                      color: AppColors.lightColor,
                    ),
                    SizedBox(height: 12),
                    DeviceQuickControl(
                      icon: Icons.lightbulb_outline,
                      title: 'Đèn sân',
                      isOn: device.lightYardState,
                      onToggle: (value) => device.toggleLightYard(value),
                      color: AppColors.lightColor,
                    ),
                    SizedBox(height: 12),
                    DeviceQuickControl(
                      icon: Icons.air,
                      title: 'Máy ion',
                      isOn: device.ionizerState,
                      onToggle: (value) => device.toggleIonizer(value),
                      color: AppColors.ionizerColor,
                    ),
                  ],
                );
              },
            ),

            SizedBox(height: 24),

            // Rooms Section
            Text(
              'Phòng',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 16),

            SizedBox(
              height: 170,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  RoomCard(
                    roomName: 'Phòng khách',
                    deviceCount: 5,
                    activeDevices: 3,
                    icon: Icons.living,
                    onTap: () => Navigator.pushNamed(context, '/rooms'),
                  ),
                  SizedBox(width: 12),
                  RoomCard(
                    roomName: 'Phòng ngủ',
                    deviceCount: 4,
                    activeDevices: 1,
                    icon: Icons.bed,
                    onTap: () => Navigator.pushNamed(context, '/rooms'),
                  ),
                  SizedBox(width: 12),
                  RoomCard(
                    roomName: 'Nhà bếp',
                    deviceCount: 0,
                    activeDevices: 0,
                    icon: Icons.kitchen,
                    onTap: () => Navigator.pushNamed(context, '/rooms'),
                  ),
                  SizedBox(width: 12),
                  RoomCard(
                    roomName: 'Sân vườn',
                    deviceCount: 2,
                    activeDevices: 1,
                    icon: Icons.yard,
                    onTap: () => Navigator.pushNamed(context, '/rooms'),
                  ),
                ],
              ),
            ),

            SizedBox(height: 32),

            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/sensors'),
                    icon: Icon(Icons.analytics),
                    label: Text('Xem chi tiết'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/devices'),
                    icon: Icon(Icons.settings_remote),
                    label: Text('Thiết bị'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    // Refresh MQTT connection if needed
    final mqtt = Provider.of<MqttProvider>(context, listen: false);
    if (!mqtt.isConnected) {
      await mqtt.connect();
    }

    await Future.delayed(Duration(seconds: 1));
  }
}
