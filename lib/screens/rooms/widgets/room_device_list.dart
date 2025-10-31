import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/device_provider.dart';

/// Widget danh sách thiết bị trong phòng
class RoomDeviceList extends StatelessWidget {
  final String roomId;
  final String roomName;

  const RoomDeviceList({Key? key, required this.roomId, required this.roomName})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final devices = _getDevices(roomId);

    return Consumer<DeviceProvider>(
      builder: (context, deviceProvider, _) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: devices.length,
          itemBuilder: (context, index) {
            final device = devices[index];
            final deviceId = device['id'] as String;

            // Lấy trạng thái thực từ provider
            bool currentState = false;
            int servoValue = 0;

            if (device['type'] == 'relay') {
              switch (deviceId) {
                case 'light_living':
                  currentState = deviceProvider.lightLivingState;
                  break;
                case 'ionizer':
                  currentState = deviceProvider.ionizerState;
                  break;
                case 'pump':
                  currentState = deviceProvider.pumpState;
                  break;
                case 'light_yard':
                  currentState = deviceProvider.lightYardState;
                  break;
              }
            } else if (device['type'] == 'servo') {
              switch (deviceId) {
                case 'roof':
                  servoValue = deviceProvider.roofServoValue;
                  break;
                case 'gate':
                  servoValue = deviceProvider.gateServoValue;
                  break;
              }
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: device['color'].withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(device['icon'], color: device['color']),
                ),
                title: Text(device['name']),
                subtitle: Text(
                  device['type'] == 'relay'
                      ? (currentState ? 'Đang bật' : 'Đang tắt')
                      : 'Mở ${(servoValue * 100 / 180).round()}%',
                ),
                trailing: device['type'] == 'relay'
                    ? Switch(
                        value: currentState,
                        onChanged: (value) {
                          // Toggle device
                          switch (deviceId) {
                            case 'light_living':
                              deviceProvider.toggleLightLiving(value);
                              break;
                            case 'ionizer':
                              deviceProvider.toggleIonizer(value);
                              break;
                            case 'pump':
                              deviceProvider.togglePump(value);
                              break;
                            case 'light_yard':
                              deviceProvider.toggleLightYard(value);
                              break;
                          }
                        },
                      )
                    : Icon(Icons.chevron_right),
                onTap: () {
                  // Nếu là servo, mở dialog điều khiển
                  if (device['type'] == 'servo') {
                    _showServoControlDialog(
                      context,
                      deviceProvider,
                      deviceId,
                      device['name'],
                      servoValue,
                    );
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showServoControlDialog(
    BuildContext context,
    DeviceProvider deviceProvider,
    String deviceId,
    String deviceName,
    int currentValue,
  ) {
    // Chuyển góc (0-180) sang % (0-100)
    int tempPercent = (currentValue * 100 / 180).round();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(deviceName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hiển thị %
              Text(
                'Mở: $tempPercent%',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),

              // Nút Đóng và Mở
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        tempPercent = 0;
                      });
                      // Gửi ngay khi bấm Đóng
                      int angleValue = 0;
                      switch (deviceId) {
                        case 'roof':
                          deviceProvider.setRoofServo(angleValue);
                          break;
                        case 'gate':
                          deviceProvider.setGateServo(angleValue);
                          break;
                      }
                    },
                    icon: Icon(Icons.close),
                    label: Text('Đóng'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        tempPercent = 100;
                      });
                      // Gửi ngay khi bấm Mở
                      int angleValue = 180;
                      switch (deviceId) {
                        case 'roof':
                          deviceProvider.setRoofServo(angleValue);
                          break;
                        case 'gate':
                          deviceProvider.setGateServo(angleValue);
                          break;
                      }
                    },
                    icon: Icon(Icons.check),
                    label: Text('Mở'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade400,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Slider từ 0-100%
              Slider(
                value: tempPercent.toDouble(),
                min: 0,
                max: 100,
                divisions: 20,
                label: '$tempPercent%',
                onChanged: (value) {
                  setState(() {
                    tempPercent = value.toInt();
                  });

                  // Gửi MQTT ngay khi kéo slider
                  int angleValue = (tempPercent * 180 / 100).round();
                  switch (deviceId) {
                    case 'roof':
                      deviceProvider.setRoofServo(angleValue);
                      break;
                    case 'gate':
                      deviceProvider.setGateServo(angleValue);
                      break;
                  }
                },
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Đóng'),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getDevices(String roomId) {
    // Dữ liệu demo theo phòng
    switch (roomId) {
      case 'living_room':
        return [
          {
            'id': 'light_living',
            'name': 'Đèn phòng khách',
            'type': 'relay',
            'state': true,
            'status': 'Đang bật',
            'icon': Icons.lightbulb,
            'color': Colors.amber,
          },
          {
            'id': 'ionizer',
            'name': 'Máy ion hóa',
            'type': 'relay',
            'state': false,
            'status': 'Đang tắt',
            'icon': Icons.air,
            'color': Colors.blue,
          },
        ];
      case 'garden':
        return [
          {
            'id': 'pump',
            'name': 'Máy bơm',
            'type': 'relay',
            'state': false,
            'status': 'Đang tắt',
            'icon': Icons.water_drop,
            'color': Colors.blue,
          },
          {
            'id': 'light_yard',
            'name': 'Đèn sân vườn',
            'type': 'relay',
            'state': true,
            'status': 'Đang bật',
            'icon': Icons.lightbulb,
            'color': Colors.amber,
          },
          {
            'id': 'roof',
            'name': 'Mái che',
            'type': 'servo',
            'value': 90,
            'status': 'Mở 50%',
            'icon': Icons.roofing,
            'color': Colors.brown,
          },
        ];
      case 'entrance':
        return [
          {
            'id': 'gate',
            'name': 'Cổng',
            'type': 'servo',
            'value': 0,
            'status': 'Đóng',
            'icon': Icons.door_front_door,
            'color': Colors.grey,
          },
        ];
      default:
        return [];
    }
  }
}
