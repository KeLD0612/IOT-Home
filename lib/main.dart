import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'providers/mqtt_provider.dart';
import 'providers/sensor_provider.dart';
import 'providers/device_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/automation_provider.dart';
import 'providers/theme_provider.dart';
import 'services/mqtt_service.dart';
import 'services/local_storage_service.dart';
import 'services/notification_service.dart';
import 'models/device_model.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/devices/devices_screen.dart';
// ignore: unused_import
import 'screens/devices/device_detail_screen.dart';
import 'screens/sensors/sensors_screen.dart';
import 'screens/sensors/dust_chart_screen.dart';
import 'screens/sensors/gas_monitor_screen.dart';
import 'screens/automation/automation_screen.dart';
import 'screens/automation/add_rule_screen.dart';
import 'screens/settings/settings_screen.dart';
// ignore: unused_import
import 'screens/settings/mqtt_settings_screen.dart';
// ignore: unused_import
import 'screens/settings/notification_settings_screen.dart';
// ignore: unused_import
import 'screens/settings/about_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/rooms/rooms_screen.dart';
import 'screens/notifications/notifications_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo services
  final mqttService = MqttService();
  final storageService = LocalStorageService();
  final notificationService = NotificationService();

  await storageService.init();
  await notificationService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MqttProvider(mqttService)),
        ChangeNotifierProvider(
          create: (_) => SensorProvider(storageService, notificationService),
        ),
        ChangeNotifierProxyProvider<MqttProvider, DeviceProvider>(
          create: (_) => DeviceProvider(),
          update: (_, mqtt, device) {
            device?.setMqttProvider(mqtt);
            return device!;
          },
        ),
        ChangeNotifierProvider(create: (_) => SettingsProvider(storageService)),
        ChangeNotifierProvider(
          create: (_) => AutomationProvider(storageService),
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider(storageService)),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'Smart Home IoT',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          initialRoute: '/',
          routes: {
            '/': (context) => SplashScreen(),
            '/home': (context) => HomeScreen(),
            '/devices': (context) => DevicesScreen(),
            '/device_detail': (context) {
              final device =
                  ModalRoute.of(context)!.settings.arguments as Device;
              return DeviceDetailScreen(
                deviceId: device.id,
                deviceName: device.name,
                deviceType: device.type.toString(),
              );
            },
            '/sensors': (context) => SensorsScreen(),
            '/dust_chart': (context) => DustChartScreen(),
            '/gas_monitor': (context) => GasMonitorScreen(),
            '/automation': (context) => AutomationScreen(),
            '/add_rule': (context) => AddRuleScreen(),
            '/settings': (context) => SettingsScreen(),
            '/mqtt_settings': (context) => MqttSettingsScreen(),
            '/notification_settings': (context) => NotificationSettingsScreen(),
            '/about': (context) => AboutScreen(),
            '/dashboard': (context) => DashboardScreen(),
            '/profile': (context) => ProfileScreen(),
            '/account': (context) => ProfileScreen(),
            '/history': (context) => HistoryScreen(),
            '/onboarding': (context) => OnboardingScreen(),
            '/rooms': (context) => RoomsScreen(),
            '/notifications': (context) => NotificationsScreen(),
          },
        );
      },
    );
  }
}
