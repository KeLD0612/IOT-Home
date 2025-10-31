import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/mqtt_provider.dart';
import '../../providers/sensor_provider.dart';
import '../../providers/device_provider.dart';
import '../../config/app_colors.dart';
import '../../models/device_model.dart';
import '../../widgets/connection_status_badge.dart';
import '../../widgets/voice_control_button.dart';
import '../../controllers/voice_controller.dart';
import 'widgets/animated_sensor_card.dart';
import 'widgets/device_quick_control.dart';
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
  void initState() {
    super.initState();
    // Auto-connect MQTT when HomeScreen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoConnectMqtt();
    });
  }

  Future<void> _autoConnectMqtt() async {
    try {
      final mqtt = Provider.of<MqttProvider>(context, listen: false);
      if (!mqtt.isConnected) {
        print('🔌 Auto-connecting MQTT...');
        await mqtt.connect();

        // Quick retry với timeout ngắn hơn
        if (!mqtt.isConnected) {
          await Future.delayed(Duration(seconds: 1)); // Giảm từ 3 xuống 1 giây
          print('🔄 MQTT quick retry...');
          await mqtt.connect();
        }
      }
    } catch (e) {
      print('❌ Auto-connect MQTT failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Smart Home'),
        actions: [
          // 📡 CONNECTION STATUS BADGE (Hiển thị số thiết bị kết nối)
          const ConnectionStatusBadge(),
          const SizedBox(width: 16),
        ],
      ),

      body: _buildBody(),

      // 🎤 VOICE CONTROL FLOATING BUTTON
      floatingActionButton: VoiceControlButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

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
              builder: (context, sensorProvider, _) {
                final userSensors = sensorProvider.userSensors;

                if (userSensors.isEmpty) {
                  return Container(
                    padding: EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.sensors_off,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Chưa có cảm biến nào',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Thêm cảm biến để theo dõi môi trường',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/add_sensor'),
                          icon: Icon(Icons.add),
                          label: Text('Thêm cảm biến'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Build sensor cards from user's actual sensors
                final activeSensors = userSensors
                    .where((s) => s.isActive)
                    .take(4)
                    .toList();

                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.0,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: activeSensors.length,
                  itemBuilder: (context, index) {
                    final sensor = activeSensors[index];

                    return AnimatedSensorCard(
                      icon: _getSensorIcon(sensor.sensorTypeId),
                      title: sensor.displayName,
                      value: sensor.formattedValue,
                      color: _getSensorColor(sensor.sensorTypeId),
                    );
                  },
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
              builder: (context, deviceProvider, _) {
                final devices = deviceProvider.devices;

                if (devices.isEmpty) {
                  return Container(
                    padding: EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.device_hub_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Chưa có thiết bị nào',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Thêm thiết bị để điều khiển từ xa',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/add_device'),
                          icon: Icon(Icons.add),
                          label: Text('Thêm thiết bị'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Lọc chỉ thiết bị được ghim
                final pinnedDevices = devices
                    .where((device) => device.isPinned)
                    .toList();

                if (pinnedDevices.isEmpty) {
                  return Container(
                    padding: EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.push_pin_outlined,
                          size: 48,
                          color: Colors.blue[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Chưa có thiết bị được ghim',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Ghim thiết bị để điều khiển nhanh từ trang chủ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/devices'),
                          icon: Icon(Icons.devices),
                          label: Text('Quản lý thiết bị'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Sắp xếp devices theo độ ưu tiên: Relay -> Servo -> Fan
                pinnedDevices.sort((a, b) {
                  // Thứ tự ưu tiên: Relay (0), Servo (1), Fan (2)
                  int getPriority(DeviceType type) {
                    switch (type) {
                      case DeviceType.relay:
                        return 0;
                      case DeviceType.servo:
                        return 1;
                      case DeviceType.fan:
                        return 2;
                    }
                  }

                  int priorityCompare = getPriority(
                    a.type,
                  ).compareTo(getPriority(b.type));
                  // Nếu cùng loại, sắp xếp theo tên
                  if (priorityCompare == 0) {
                    return a.name.compareTo(b.name);
                  }
                  return priorityCompare;
                });

                // Hiển thị tất cả thiết bị được ghim (không giới hạn 6)
                return Column(
                  children: pinnedDevices.map((device) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: _buildQuickControl(device, deviceProvider),
                    );
                  }).toList(),
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

            // Rooms Section
            Consumer<DeviceProvider>(
              builder: (context, deviceProvider, _) {
                final devices = deviceProvider.devices;

                if (devices.isEmpty) {
                  return Container(
                    padding: EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.home_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Chưa có phòng nào',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Thêm thiết bị và phân bổ vào phòng',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/devices'),
                          icon: Icon(Icons.add),
                          label: Text('Thêm thiết bị'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Group devices by room
                Map<String, List<Device>> roomDevices = {};
                for (final device in devices) {
                  final room = device.room ?? 'Không xác định';
                  roomDevices[room] ??= [];
                  roomDevices[room]!.add(device);
                }

                if (roomDevices.isEmpty) {
                  return Container(
                    padding: EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.room_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Thiết bị chưa phân phòng',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Đi tới quản lý phòng để phân bổ thiết bị',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/add_room'),
                              icon: Icon(Icons.add_home),
                              label: Text('Thêm phòng'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/rooms'),
                              icon: Icon(Icons.room),
                              label: Text('Quản lý phòng'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }

                return SizedBox(
                  height: 170,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: roomDevices.length,
                    itemBuilder: (context, index) {
                      final roomName = roomDevices.keys.toList()[index];
                      final devicesInRoom = roomDevices[roomName]!;
                      final activeDevices = devicesInRoom
                          .where((d) => d.state)
                          .length;

                      return Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: RoomCard(
                          roomName: roomName,
                          deviceCount: devicesInRoom.length,
                          activeDevices: activeDevices,
                          icon: _getRoomIcon(roomName),
                          onTap: () => Navigator.pushNamed(context, '/rooms'),
                        ),
                      );
                    },
                  ),
                );
              },
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

  IconData _getSensorIcon(String sensorTypeId) {
    switch (sensorTypeId) {
      case 'temperature':
        return Icons.thermostat;
      case 'humidity':
        return Icons.water_drop;
      case 'rain':
        return Icons.grain;
      case 'light':
        return Icons.wb_sunny;
      case 'soil_moisture':
        return Icons.grass;
      case 'gas':
        return Icons.air;
      case 'dust':
        return Icons.cloud;
      case 'motion':
        return Icons.directions_walk;
      case 'pressure':
        return Icons.speed;
      case 'uv':
        return Icons.wb_sunny_outlined;
      default:
        return Icons.sensors;
    }
  }

  Color _getSensorColor(String sensorTypeId) {
    switch (sensorTypeId) {
      case 'temperature':
        return AppColors.temperature;
      case 'humidity':
        return AppColors.humidity;
      case 'rain':
        return Colors.blue[400]!;
      case 'light':
        return Colors.orange[400]!;
      case 'soil_moisture':
        return AppColors.soil;
      case 'gas':
        return Colors.red[400]!;
      case 'dust':
        return AppColors.dust;
      case 'motion':
        return Colors.purple[400]!;
      case 'pressure':
        return Colors.teal[400]!;
      case 'uv':
        return Colors.amber[400]!;
      default:
        return AppColors.primary;
    }
  }

  IconData _getDeviceIcon(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.relay:
        return Icons.lightbulb;
      case DeviceType.servo:
        return Icons.water_drop;
      case DeviceType.fan:
        return Icons.air;
    }
  }

  Color _getDeviceColor(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.relay:
        return AppColors.lightColor;
      case DeviceType.servo:
        return AppColors.pumpColor;
      case DeviceType.fan:
        return Colors.cyan[400]!;
    }
  }

  Widget _buildQuickControl(Device device, DeviceProvider deviceProvider) {
    if (device.isRelay) {
      // Relay: Dùng toggle switch
      return DeviceQuickControl(
        icon: _getDeviceIcon(device.type),
        title: device.name,
        isOn: device.state,
        onToggle: (value) => deviceProvider.toggleDevice(device.id),
        color: _getDeviceColor(device.type),
      );
    } else if (device.isServo) {
      // Servo: Hiển thị góc hiện tại và preset buttons
      return _buildServoQuickControl(device, deviceProvider);
    } else if (device.isFan) {
      // Fan: Hiển thị tốc độ hiện tại và preset buttons
      return _buildFanQuickControl(device, deviceProvider);
    } else {
      // Fallback: Default toggle
      return DeviceQuickControl(
        icon: _getDeviceIcon(device.type),
        title: device.name,
        isOn: device.state,
        onToggle: (value) => deviceProvider.toggleDevice(device.id),
        color: _getDeviceColor(device.type),
      );
    }
  }

  Widget _buildServoQuickControl(Device device, DeviceProvider deviceProvider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.pumpColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.settings,
                    color: AppColors.pumpColor,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Góc: ${device.value ?? 0}°',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            // ⚙️ Servo Slider
            Row(
              children: [
                Text('0°', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Expanded(
                  child: Slider(
                    value: (device.value ?? 0).toDouble().clamp(
                      0,
                      device.isServo360 == true ? 360 : 180,
                    ),
                    min: 0,
                    max: device.isServo360 == true ? 360 : 180,
                    divisions: device.isServo360 == true ? 36 : 18,
                    label: '${device.value ?? 0}°',
                    onChanged: (value) => deviceProvider.updateServoValue(
                      device.id,
                      value.toInt(),
                    ),
                    activeColor: AppColors.pumpColor,
                  ),
                ),
                Text(
                  '${device.isServo360 == true ? "360" : "180"}°',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            SizedBox(height: 8),
            // ⚙️ Preset Buttons
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [0, 45, 90, 135, 180].map((angle) {
                  return Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: ElevatedButton(
                      onPressed: () =>
                          deviceProvider.updateServoValue(device.id, angle),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (device.value == angle)
                            ? AppColors.pumpColor
                            : Colors.grey[200],
                        foregroundColor: (device.value == angle)
                            ? Colors.white
                            : Colors.black87,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: Size(0, 32),
                      ),
                      child: Text('${angle}°'),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFanQuickControl(Device device, DeviceProvider deviceProvider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.cyan[400]!.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.air, color: Colors.cyan[400], size: 24),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Tốc độ: ${device.value ?? 0}%',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            // 🌪️ Fan Speed Slider
            Row(
              children: [
                Text('Tắt', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Expanded(
                  child: Slider(
                    value: (device.value ?? 0).toDouble().clamp(0, 100),
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: '${device.value ?? 0}%',
                    onChanged: (value) => deviceProvider.updateServoValue(
                      device.id,
                      value.toInt(),
                    ),
                    activeColor: Colors.cyan[400],
                  ),
                ),
                Text(
                  'Mạnh',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            SizedBox(height: 8),
            // 🌪️ Preset Buttons
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFanPresetButtonQuick(
                    'Tắt',
                    0,
                    Colors.grey,
                    device,
                    deviceProvider,
                  ),
                  _buildFanPresetButtonQuick(
                    'Nhẹ',
                    33,
                    Colors.green,
                    device,
                    deviceProvider,
                  ),
                  _buildFanPresetButtonQuick(
                    'Khá',
                    67,
                    Colors.orange,
                    device,
                    deviceProvider,
                  ),
                  _buildFanPresetButtonQuick(
                    'Mạnh',
                    100,
                    Colors.red,
                    device,
                    deviceProvider,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFanPresetButtonQuick(
    String label,
    int value,
    Color color,
    Device device,
    DeviceProvider deviceProvider,
  ) {
    bool isSelected = (device.value == value);
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: ElevatedButton(
        onPressed: () => deviceProvider.updateServoValue(device.id, value),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? color : Colors.grey[200],
          foregroundColor: isSelected ? Colors.white : Colors.black87,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: Size(0, 32),
        ),
        child: Text(label),
      ),
    );
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
}
