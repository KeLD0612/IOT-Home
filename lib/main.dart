import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'config/app_theme.dart';
import 'providers/mqtt_provider.dart';
import 'providers/sensor_provider.dart';
import 'providers/device_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/automation_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'services/mqtt_service.dart';
import 'services/local_storage_service.dart';
import 'services/notification_service.dart';
import 'services/ai_voice_service.dart';
import 'controllers/voice_controller.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/devices/devices_screen.dart';
import 'screens/devices/device_detail_screen.dart';
import 'screens/devices/add_device_screen.dart';
import 'screens/devices/edit_device_screen.dart';
import 'screens/rooms/room_management_screen.dart';
import 'screens/sensors/sensors_screen.dart';
import 'screens/sensors/add_sensor_screen.dart';
import 'screens/sensors/edit_sensor_screen.dart';
import 'screens/sensors/dust_chart_screen.dart';
import 'screens/sensors/gas_monitor_screen.dart';
import 'screens/automation/automation_screen.dart';
import 'screens/automation/add_rule_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/rooms/rooms_screen.dart';
import 'screens/rooms/add_room_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/auth/login_screen.dart';
import 'widgets/automation_initializer.dart';
import 'widgets/auth_wrapper.dart';
import 'models/device_model.dart';
import 'models/user_sensor.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 KHỞI TẠO FIREBASE TRƯỚC TIÊN
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Khởi tạo services
  final mqttService = MqttService();
  final storageService = LocalStorageService();
  final notificationService = NotificationService();

  await storageService.init();
  await notificationService.init();

  runApp(
    MultiProvider(
      providers: [
        // Authentication Provider - First priority
        ChangeNotifierProvider(create: (_) => AuthProvider()),

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
        ChangeNotifierProvider(create: (_) => AutomationProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider(storageService)),

        // 🤖 AI Voice Control Provider
        ChangeNotifierProxyProvider<DeviceProvider, VoiceController>(
          create: (context) {
            final deviceProvider = context.read<DeviceProvider>();
            final controller = VoiceController(
              aiService: AiVoiceService(),
              deviceProvider: deviceProvider,
            );
            // Initialize sau khi build xong
            Future.microtask(() => controller.initialize());
            return controller;
          },
          update: (_, deviceProvider, voiceController) {
            return voiceController!;
          },
        ),
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
        return AutomationInitializer(
          child: MaterialApp(
            title: 'Smart Home IoT',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            initialRoute: '/auth',
            routes: {
              '/': (context) => AuthWrapper(),
              '/auth': (context) => AuthWrapper(),
              '/login': (context) => LoginScreen(),
              '/splash': (context) => SplashScreen(),
              '/home': (context) => HomeScreen(),
              '/devices': (context) => DevicesScreen(),
              '/add_device': (context) => AddDeviceScreen(),
              '/edit_device': (context) {
                final device =
                    ModalRoute.of(context)!.settings.arguments as Device;
                return EditDeviceScreen(device: device);
              },
              '/sensors': (context) => SensorsScreen(),
              '/add_sensor': (context) => AddSensorScreen(),
              '/dust_chart': (context) => DustChartScreen(),
              '/gas_monitor': (context) => GasMonitorScreen(),
              '/automation': (context) => AutomationScreen(),
              '/add_rule': (context) => AddRuleScreen(),
              '/settings': (context) => SettingsScreen(),
              '/dashboard': (context) => DashboardScreen(),
              '/profile': (context) => ProfileScreen(),
              '/history': (context) => HistoryScreen(),
              '/onboarding': (context) => OnboardingScreen(),
              '/rooms': (context) => RoomsScreen(),
              '/add_room': (context) => AddRoomScreen(),
              '/room_management': (context) => RoomManagementScreen(),
              '/notifications': (context) => NotificationsScreen(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == '/device_detail') {
                final device = settings.arguments as Device;
                return MaterialPageRoute(
                  builder: (context) => DeviceDetailScreen(device: device),
                );
              }
              if (settings.name == '/edit_sensor') {
                final sensor = settings.arguments as UserSensor;
                return MaterialPageRoute(
                  builder: (context) => EditSensorScreen(sensor: sensor),
                );
              }
              return null;
            },
          ),
        );
      },
    );
  }
}
