# 📊 GIẢI THÍCH FLOWCODE DỰ ÁN FLUTTER IoT SMART HOME

## 🎯 TỔNG QUAN KIẾN TRÚC

Dự án sử dụng **Pattern Provider State Management** với kiến trúc lớp:
- **Models** (Dữ liệu)
- **Providers** (Quản lý trạng thái)
- **Services** (Dịch vụ)
- **Screens** (Giao diện người dùng)
- **Widgets** (Thành phần tái sử dụng)

---

## 🚀 FLOWCODE KHỞI ĐỘNG ỨNG DỤNG (App Initialization Flow)

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. MAIN ENTRY POINT (main.dart)                                 │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 2. INITIALIZE FLUTTER BINDING                                   │
│    WidgetsFlutterBinding.ensureInitialized()                   │
│    ✓ Khởi tạo Flutter Engine                                   │
│    ✓ Cho phép gọi native platform code                         │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 3. INITIALIZE SERVICES                                          │
│    - MqttService() → Kết nối MQTT Broker                        │
│    - LocalStorageService() → SharedPreferences caching          │
│    - NotificationService() → Local notifications                │
│                                                                  │
│    await storageService.init()                                  │
│    await notificationService.init()                             │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 4. SETUP PROVIDERS (MultiProvider)                              │
│                                                                  │
│    ├─ MqttProvider(mqttService)                                 │
│    │  └─ Quản lý kết nối MQTT, publish/subscribe              │
│    │                                                             │
│    ├─ SensorProvider(storageService, notificationService)       │
│    │  └─ Quản lý dữ liệu 8 cảm biến (DHT22, MQ2, etc)         │
│    │                                                             │
│    ├─ DeviceProvider() [ProxyProvider with MqttProvider]        │
│    │  └─ Quản lý 6 thiết bị (relay, servo), phụ thuộc MQTT    │
│    │                                                             │
│    ├─ SettingsProvider(storageService)                          │
│    │  └─ Quản lý cài đặt app (ngôn ngữ, theme, etc)           │
│    │                                                             │
│    ├─ AutomationProvider(storageService)                        │
│    │  └─ Quản lý automation rules (nếu điều kiện → hành động)  │
│    │                                                             │
│    └─ ThemeProvider(storageService)                             │
│       └─ Quản lý Dark/Light theme                              │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 5. BUILD APP WITH MATERIALIZED THEME                            │
│    - Sử dụng Consumer<ThemeProvider>                            │
│    - Đọc isDarkMode từ ThemeProvider                            │
│    - Áp dụng AppTheme.lightTheme hoặc .darkTheme               │
│                                                                  │
│    routes: {                                                     │
│      '/': SplashScreen,                                         │
│      '/home': HomeScreen,                                       │
│      '/devices': DevicesScreen,                                 │
│      ... (19 routes total)                                      │
│    }                                                             │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 6. LOAD SPLASH SCREEN (SplashScreen)                            │
│    ✓ Hiển thị logo/splash                                       │
│    ✓ Khởi tạo Firebase                                         │
│    ✓ Kiểm tra đăng nhập                                         │
│    ✓ Điều hướng đến HomeScreen hoặc LoginScreen               │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔐 FLOWCODE XAUTHENTICATION (Đăng Nhập)

```
┌─────────────────────────────────────────────────────────────────┐
│ USER OPENS APP → SPLASH SCREEN                                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ SPLASH SCREEN CHECKS:                                           │
│ ✓ Is Firebase initialized?                                      │
│ ✓ Is there a logged-in user?                                    │
└─────────────────────────────────────────────────────────────────┘
                              ↓
        ┌────────────────────────────────────┬────────────────┐
        ↓                                    ↓                ↓
   [USER LOGGED IN]            [NO USER LOGGED IN]    [ERROR]
        ↓                                    ↓                ↓
    GO TO HOME                 GO TO LOGIN SCREEN    RETRY
        ↓                                    ↓
   ┌─────────────────┐      ┌──────────────────────┐
   │ HOME SCREEN     │      │ LOGIN SCREEN         │
   │ - Load devices  │      │ - Google Sign-In btn │
   │ - Load sensors  │      │ - Email/Password btn │
   │ - Start MQTT    │      └──────────────────────┘
   │ - Load rules    │                  ↓
   └─────────────────┘      ┌──────────────────────┐
                            │ AUTHENTICATE         │
                            │ - Call AuthProvider  │
                            │ - Firebase verify    │
                            │ - Save to Firestore  │
                            └──────────────────────┘
                                      ↓
                            ┌──────────────────────┐
                            │ IF SUCCESS:          │
                            │ 1. Save userId       │
                            │ 2. Init all providers│
                            │ 3. Connect MQTT      │
                            │ 4. Load user data    │
                            │ → GO TO HOME         │
                            └──────────────────────┘
```

---

## 🎛️ FLOWCODE ĐIỀU KHIỂN THIẾT BỊ (Device Control Flow)

### User nhấn nút bật/tắt thiết bị

```
┌─────────────────────────────────────────────────────────────────┐
│ USER TAP DEVICE ON/OFF BUTTON                                   │
│ (Tại HomeScreen, DevicesScreen, hay automation action)          │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ SCREEN CALLS PROVIDER METHOD                                    │
│ deviceProvider.toggleDevice(deviceId)                           │
│                                                                  │
│ // Hoặc:                                                        │
│ deviceProvider.updateDeviceState(deviceId, true/false)         │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ DEVICE PROVIDER (lib/providers/device_provider.dart)            │
│                                                                  │
│ 1. Update local state:                                          │
│    _devices[index].state = !_devices[index].state              │
│    notifyListeners() → Rebuild UI                              │
│                                                                  │
│ 2. Send MQTT command:                                           │
│    await _mqttProvider.publishCommand(...)                      │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ MQTT PROVIDER (lib/providers/mqtt_provider.dart)                │
│ mqtt_service.dart → mqtt_client package                         │
│                                                                  │
│ 1. Kiểm tra kết nối MQTT                                        │
│ 2. Tạo MQTT Message                                             │
│    Topic: smarthome/devices/[deviceId]/command                 │
│    Payload: {"action": "ON"/"OFF"}                              │
│                                                                  │
│ 3. Publish đến Broker                                           │
│    Broker: 16257efaa31f4843a11e19f83c34e594                    │
│            .s1.eu.hivemq.cloud:8883                             │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ MQTT BROKER (HiveMQ Cloud)                                      │
│ ✓ Nhận message                                                  │
│ ✓ Chuyển tiếp đến ESP32 subscribers                             │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ ESP32 FIRMWARE                                                  │
│ ✓ Nhận command từ MQTT broker                                   │
│ ✓ Parse action: ON/OFF/SET_VALUE                                │
│ ✓ Control hardware (relay, servo, LED, fan, etc)               │
│                                                                  │
│ Ví dụ: Relay ON                                                 │
│   digitalWrite(RELAY_PIN, HIGH)                                │
│                                                                  │
│ Ví dụ: Servo quay đến góc                                      │
│   servo.write(angle)                                            │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ DEVICE RESPONDS WITH STATUS (Optional)                          │
│ Topic: smarthome/devices/[deviceId]/status                     │
│ Payload: {"state": true/false, "power": 50}                    │
│                                                                  │
│ (Nếu firmware hỗ trợ feedback)                                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ APP RECEIVES STATUS UPDATE                                      │
│                                                                  │
│ MqttProvider.onMessage(message)                                 │
│   ↓                                                             │
│ SensorProvider.handleMqttMessage(message)                       │
│   ↓                                                             │
│ Update DeviceProvider state                                     │
│   ↓                                                             │
│ notifyListeners() → UI Updated ✓                                │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📊 FLOWCODE NHẬN DỮ LIỆU CẢM BIẾN (Sensor Data Flow)

### ESP32 đọc dữ liệu từ cảm biến và gửi đến app

```
┌─────────────────────────────────────────────────────────────────┐
│ ESP32 FIRMWARE (SmartHome_MultiDevice_ESP32.ino)                │
│                                                                  │
│ Setup():                                                        │
│   - Init WiFi + MQTT                                            │
│   - Init sensors (DHT22, MQ2, Rain, Dust, Soil, PIR)          │
│   - Setup reading interval (ví dụ: 5 seconds)                  │
│                                                                  │
│ Loop():                                                         │
│   - Read sensors every interval                                 │
│   - Format JSON: {"dht": 28.5, "humidity": 65, ...}            │
│   - Publish MQTT: smarthome/sensors/data                        │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ MQTT BROKER (HiveMQ Cloud)                                      │
│ ✓ Topic: smarthome/sensors/data                                 │
│ ✓ Relay to all subscribers (app)                                │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ APP RECEIVES SENSOR DATA                                        │
│                                                                  │
│ MqttProvider._onMessage(MqttReceivedMessage msg)               │
│   ↓                                                             │
│ messageHandler?.call(msg) // Handler từ SensorProvider         │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ SENSOR PROVIDER (lib/providers/sensor_provider.dart)            │
│                                                                  │
│ handleMqttMessage(MqttReceivedMessage msg):                    │
│   1. Parse JSON từ payload                                      │
│   2. Extract temperature, humidity, gas, etc                    │
│   3. Create SensorData objects                                  │
│   4. Update _sensorHistory                                      │
│   5. Save to local storage (cache)                              │
│   6. Check for alerts (vd: Temp > 35°C)                         │
│   7. notifyListeners() → UI Updated                             │
│                                                                  │
│ Example:                                                        │
│   _temperatureData.add(SensorData(                              │
│     value: 28.5,                                                │
│     timestamp: DateTime.now(),                                  │
│   ))                                                            │
│                                                                  │
│   if (28.5 > TEMP_ALERT_THRESHOLD) {                            │
│     _alerts.add(Alert(...))                                     │
│     notificationService.show("⚠️ Nhiệt độ cao!")               │
│   }                                                             │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ UI UPDATES (Sensors Screen, Charts, History)                   │
│                                                                  │
│ Consumer<SensorProvider>(                                       │
│   builder: (context, sensorProvider, child) {                  │
│     return Column(                                              │
│       children: [                                               │
│         // Display temperature                                  │
│         Text(sensorProvider.currentTemperature),                │
│         // Display humidity                                     │
│         Text(sensorProvider.currentHumidity),                   │
│         // Display charts                                       │
│         LineChart(sensorProvider.temperatureHistory),           │
│       ],                                                        │
│     )                                                           │
│   }                                                             │
│ )                                                               │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🤖 FLOWCODE VOICE CONTROL (Điều Khiển Bằng Giọng Nói)

### User nói lệnh để điều khiển thiết bị

```
┌─────────────────────────────────────────────────────────────────┐
│ USER TAPS VOICE CONTROL BUTTON                                  │
│ (VoiceControlButton widget)                                     │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ VOICE CONTROLLER (lib/controllers/voice_controller.dart)        │
│                                                                  │
│ startListening():                                               │
│   1. Check if initialized                                       │
│   2. Set _isListening = true                                    │
│   3. Call SpeechToText.listen() → Start recording               │
│   4. Trigger onResult callback                                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ SPEECH RECOGNITION SYSTEM (speech_to_text package)              │
│                                                                  │
│ 1. Record audio (Microphone)                                    │
│ 2. Send to speech recognition engine (Google Cloud Speech API)  │
│ 3. Return recognized text in Vietnamese/English                 │
│                                                                  │
│ Example:                                                        │
│   "Bật đèn phòng khách"                                         │
│   "Tắt quạt"                                                    │
│   "Đặt nhiệt độ 25 độ"                                          │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ VOICE CONTROLLER - _onSpeechResult()                            │
│                                                                  │
│ 1. Check if final result                                        │
│ 2. Store in _lastCommand                                        │
│ 3. Call processCommand(_lastCommand)                            │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ PROCESS COMMAND WITH GEMINI AI (ai_voice_service.dart)          │
│                                                                  │
│ _aiService.processVoiceCommand(                                 │
│   voiceCommand: "Bật đèn phòng khách",                          │
│   devices: [all user devices],                                  │
│ )                                                               │
│                                                                  │
│ API Call to Gemini:                                             │
│   "Parse this command and return:                              │
│    - deviceKeyName: 'light_living_room'                         │
│    - action: 'turn_on'                                          │
│    - value: null"                                               │
│                                                                  │
│ Gemini AI Response:                                             │
│   {                                                             │
│     "deviceKeyName": "light_living_room",                       │
│     "action": "turn_on",                                        │
│     "value": null,                                              │
│     "success": true,                                            │
│   }                                                             │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ VOICE CONTROLLER - _executeAction()                             │
│                                                                  │
│ 1. Find device by keyName                                       │
│    device = devices.firstWhere((d) =>                           │
│      d.keyName == result.deviceKeyName)                         │
│                                                                  │
│ 2. Execute corresponding action:                                │
│    - 'turn_on': deviceProvider.updateDeviceState(id, true)     │
│    - 'turn_off': deviceProvider.updateDeviceState(id, false)   │
│    - 'toggle': deviceProvider.toggleDevice(id)                 │
│    - 'set_value': deviceProvider.updateServoValue(id, value)   │
│                                                                  │
│ 3. Update UI with success message                               │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ DEVICE PROVIDER SENDS MQTT (Same as normal device control)      │
│                                                                  │
│ deviceProvider.updateDeviceState(id, true)                      │
│   → MqttProvider.publishCommand(...)                            │
│   → ESP32 receives and controls hardware                        │
│   → Status update sent back                                     │
│   → UI updates                                                  │
│                                                                  │
│ Status message: "✅ Đã thực hiện: Bật đèn phòng khách"         │
└─────────────────────────────────────────────────────────────────┘
```

---

## ⚙️ FLOWCODE AUTOMATION RULES (Quy Tắc Tự Động)

### If conditions met → Execute actions

```
┌─────────────────────────────────────────────────────────────────┐
│ USER CREATES AUTOMATION RULE                                    │
│ (add_edit_rule_screen.dart)                                     │
│                                                                  │
│ Rule Example:                                                   │
│   IF: Temperature > 30°C                                        │
│   THEN: Turn ON fan, Send notification                          │
│   END ACTIONS (optional): Turn OFF fan                          │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ SAVE RULE TO FIRESTORE & LOCAL STORAGE                          │
│                                                                  │
│ AutomationProvider.addRule(rule):                               │
│   1. Create AutomationRule object                               │
│   2. Save to Firestore: /users/{userId}/automation_rules       │
│   3. Cache in local storage                                     │
│   4. Add to _rules list                                         │
│   5. notifyListeners()                                          │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ RULE ENGINE EVALUATES CONDITIONS (Always Running)               │
│                                                                  │
│ AutomationProvider.evaluateRules():                             │
│   Called periodically or on sensor data update                  │
│                                                                  │
│   FOR EACH rule IN _rules:                                      │
│     FOR EACH condition IN rule.conditions:                      │
│       Evaluate: sensorValue [operator] threshold                │
│       Examples:                                                 │
│         - temperature > 30                                      │
│         - humidity < 40                                         │
│         - gasLevel > 200 ppm                                    │
│         - motionDetected == true                                │
│                                                                  │
│       Store result: condition[satisfied/not satisfied]          │
│                                                                  │
│     Check ALL conditions:                                       │
│       - ALL satisfied? → Execute startActions                   │
│       - NONE satisfied? → Execute endActions (if defined)       │
│       - SOME satisfied? → Wait for all or none                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ EXECUTE START ACTIONS (When conditions MET)                     │
│                                                                  │
│ FOR EACH action IN rule.startActions:                           │
│   1. Get device by deviceCode                                   │
│   2. Execute action based on type:                              │
│      - turn_on/off:                                             │
│        deviceProvider.updateDeviceState(deviceId, true/false)   │
│      - set_value:                                               │
│        deviceProvider.updateServoValue(deviceId, value)         │
│      - send_notification:                                       │
│        notificationService.show("Rule triggered!")              │
│      - trigger_scene:                                           │
│        Execute multiple device commands                         │
│                                                                  │
│ 3. Log action: _actionHistory.add(ActionLog(...))               │
│ 4. Save rule state: _ruleState[ruleId] = 'active'             │
│ 5. notifyListeners()                                            │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ MQTT COMMANDS SENT TO ESP32 (Same device control flow)          │
│                                                                  │
│ deviceProvider.updateDeviceState() → MqttProvider.publish()    │
│   → ESP32 receives → Hardware controls                          │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ EXECUTE END ACTIONS (When conditions NO LONGER MET)             │
│                                                                  │
│ Wait until ALL conditions become false:                         │
│   - Temperature drops below 30°C                                │
│   - AND other conditions also become false                      │
│                                                                  │
│ Then execute endActions:                                        │
│   - Turn OFF fan                                                │
│   - Turn OFF LED                                                │
│   - Reset device to default state                               │
│                                                                  │
│ OR use getEffectiveEndActions():                                │
│   If no custom endActions defined:                              │
│   → Reverse all startActions (turn ON → OFF, etc)               │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ UPDATE RULE STATE & UI                                          │
│                                                                  │
│ _ruleState[ruleId] = 'inactive'                                 │
│ _actionHistory.add(ActionLog(                                   │
│   ruleId: ruleId,                                               │
│   action: 'end_actions_executed',                               │
│   timestamp: DateTime.now(),                                    │
│ ))                                                              │
│                                                                  │
│ notifyListeners() → UI shows rule is no longer active           │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📱 DATA MODELS (Dữ Liệu Chính)

```
Device Model:
  ├─ id: String (unique identifier)
  ├─ name: String (user-friendly name)
  ├─ type: DeviceType (relay, servo, etc)
  ├─ room: String (phòng nào)
  ├─ state: bool (trạng thái hiện tại)
  ├─ value: int (0-100, cho servo/fan)
  ├─ keyName: String (unique key for voice control)
  ├─ deviceCode: String (hardware ID)
  ├─ mqttConfig: DeviceMqttConfig (custom MQTT settings)
  └─ timestamp: DateTime

SensorData Model:
  ├─ sensorId: String
  ├─ type: SensorType (DHT22, MQ2, Rain, etc)
  ├─ value: double (current reading)
  ├─ unit: String (°C, %, ppm, etc)
  ├─ timestamp: DateTime
  └─ status: String (ok, error, etc)

AutomationRule Model:
  ├─ id: String
  ├─ name: String
  ├─ enabled: bool
  ├─ conditions: List<Condition>
  │   ├─ sensorId: String
  │   ├─ operator: String (>, <, ==, !=)
  │   └─ value: dynamic
  ├─ startActions: List<Action>
  ├─ endActions: List<Action> (optional)
  ├─ hasEndActions: bool
  └─ priority: int

Action Model:
  ├─ deviceId: String (device to control)
  ├─ deviceCode: String (hardware code)
  ├─ action: String (turn_on, turn_off, set_value, etc)
  ├─ value: dynamic (ví dụ: 180 for servo angle)
  ├─ speed: int (for motors)
  └─ timestamp: DateTime
```

---

## 🔄 STATE MANAGEMENT FLOW

```
PROVIDER PATTERN LIFECYCLE:

1. Provider Creation (main.dart):
   ChangeNotifierProvider → Creates provider instance
   
2. Widget Reads Provider:
   Consumer<Provider> → Builds UI with provider data
   context.read<Provider>() → Access provider directly
   context.watch<Provider>() → Watch for changes
   
3. Data Changes:
   provider.updateSomething() → Modifies state
   provider.notifyListeners() → Notify all consumers
   
4. UI Rebuilds:
   Widgets dependent on provider → Rebuild automatically
   Only widgets using changed data rebuild (Performance!)

Example:
  // Device changes state
  deviceProvider.toggleDevice(id)
    ├─ Update internal _devices list
    ├─ Call MqttProvider to send command
    ├─ Call notifyListeners()
    └─ All Consumers<DeviceProvider> rebuild
```

---

## 🔗 PROVIDER DEPENDENCIES

```
MqttProvider
  └─ No dependencies
     └─ Used by: DeviceProvider, SensorProvider

DeviceProvider (ProxyProvider with MqttProvider)
  ├─ Depends on: MqttProvider
  ├─ Used by: HomeScreen, DevicesScreen, Automation
  └─ Functions:
     ├─ updateDeviceState()
     ├─ toggleDevice()
     ├─ updateServoValue()
     ├─ setFanPreset()
     └─ room management

SensorProvider
  ├─ Depends on: LocalStorageService, NotificationService
  ├─ Used by: SensorsScreen, Charts, Automation
  └─ Functions:
     ├─ updateSensorData()
     ├─ handleMqttMessage()
     ├─ checkAlerts()
     └─ sensor history management

AutomationProvider
  ├─ Depends on: LocalStorageService
  ├─ Used by: AutomationScreen, Background service
  └─ Functions:
     ├─ addRule()
     ├─ editRule()
     ├─ evaluateRules()
     ├─ executeActions()
     └─ rule management

SettingsProvider
  ├─ Depends on: LocalStorageService
  ├─ Used by: SettingsScreen
  └─ Functions:
     ├─ updateSetting()
     └─ preference storage

ThemeProvider
  ├─ Depends on: LocalStorageService
  ├─ Used by: MyApp (root level)
  └─ Functions:
     ├─ toggleTheme()
     └─ isDarkMode getter
```

---

## 🏗️ FOLDER STRUCTURE & RESPONSIBILITIES

```
lib/
├── main.dart
│   └─ App entry point, provider setup, routes
│
├── models/
│   ├─ device_model.dart (Device, DeviceType)
│   ├─ automation_rule.dart (Rule, Condition, Action)
│   ├─ sensor_data.dart (SensorData, SensorType)
│   ├─ user_model.dart (User)
│   └─ ... other models
│
├── providers/
│   ├─ mqtt_provider.dart (MQTT connection & publish)
│   ├─ device_provider.dart (Device control logic)
│   ├─ sensor_provider.dart (Sensor data management)
│   ├─ automation_provider.dart (Rule evaluation)
│   ├─ settings_provider.dart (User preferences)
│   ├─ theme_provider.dart (Dark/Light mode)
│   └─ auth_provider.dart (Authentication)
│
├── services/
│   ├─ mqtt_service.dart (MQTT client wrapper)
│   ├─ device_mqtt_service.dart (Per-device MQTT)
│   ├─ local_storage_service.dart (SharedPreferences)
│   ├─ notification_service.dart (Alerts & notifications)
│   ├─ ai_voice_service.dart (Gemini AI parsing)
│   └─ ... other services
│
├── screens/
│   ├─ splash/ (Initial loading)
│   ├─ auth/ (Login/Register)
│   ├─ home/ (Main dashboard)
│   ├─ devices/ (Device list & control)
│   ├─ sensors/ (Sensor readings & charts)
│   ├─ automation/ (Rule creation & management)
│   ├─ settings/ (App configuration)
│   ├─ profile/ (User account)
│   └─ ... other screens
│
├── widgets/
│   ├─ auth_wrapper.dart (Auth guard, provider init)
│   ├─ device_avatar.dart (Device display card)
│   ├─ sensor_avatar.dart (Sensor display card)
│   ├─ voice_control_button.dart (Voice control UI)
│   ├─ connection_status_badge.dart (MQTT status)
│   └─ ... other reusable widgets
│
├── controllers/
│   └─ voice_controller.dart (Voice command logic)
│
├── utils/
│   ├─ mqtt_topics.dart (MQTT topic constants)
│   ├─ device_icons.dart (Device icon mapping)
│   └─ ... other utilities
│
└── config/
    ├─ app_theme.dart (Theme definition)
    ├─ app_colors.dart (Color palette)
    ├─ mqtt_config.dart (MQTT constants)
    └─ constants.dart (App-wide constants)
```

---

## 🔌 MQTT COMMUNICATION TOPICS

```
Device Commands (App → ESP32):
  smarthome/devices/{deviceId}/command
  Payload: {"action": "ON"/"OFF"/"SET_VALUE", "value": ...}

Device Status (ESP32 → App):
  smarthome/devices/{deviceId}/status
  Payload: {"state": true/false, "value": 0-100}

Sensor Data (ESP32 → App):
  smarthome/sensors/data
  Payload: {
    "temp": 28.5,
    "humidity": 65,
    "gas": 150,
    "rain": 0,
    "dust": 50,
    "motion": false,
    "servo": 90,
    "moisture": 45,
    "timestamp": "2025-01-20T10:30:00Z"
  }

Automation Status (App):
  smarthome/automation/{ruleId}/status
  Payload: {"active": true, "triggered_at": "...", "actions": [...]}
```

---

## 📊 SUMMARY: COMPLETE REQUEST FLOW

```
1. USER ACTION (UI)
   ↓
2. SCREEN CALLS PROVIDER METHOD
   ↓
3. PROVIDER UPDATES LOCAL STATE + notifyListeners()
   ↓
4. UI REBUILDS (Consumer/watch)
   ↓
5. PROVIDER CALLS SERVICE (MQTT/Firebase/Local Storage)
   ↓
6. SERVICE EXECUTES ACTION (Send MQTT, Save to DB, etc)
   ↓
7. EXTERNAL SYSTEM RESPONDS (ESP32, Firebase, etc)
   ↓
8. SERVICE NOTIFIES PROVIDER OF RESPONSE
   ↓
9. PROVIDER UPDATES STATE + notifyListeners()
   ↓
10. UI UPDATES WITH FINAL STATE ✓
```

---

## 🎯 KEY CONCEPTS

| Concept | Explanation |
|---------|-------------|
| **Provider** | State management class that notifies listeners of changes |
| **Consumer** | Widget that watches provider and rebuilds when data changes |
| **notifyListeners()** | Triggers rebuild of all dependent widgets |
| **MQTT** | Protocol for IoT communication (publish/subscribe) |
| **Broker** | Central MQTT server that relays messages |
| **Payload** | Data sent in MQTT message (usually JSON) |
| **Topic** | MQTT channel for publishing/subscribing |
| **Automation Rule** | IF (conditions) THEN (execute actions) |
| **Local Storage** | SharedPreferences for caching app data |
| **Firestore** | Cloud database for user data persistence |

---

## 📝 FLOW EXAMPLES

### Example 1: Turn ON light
```
User → Tap light button
  → HomeScreen calls: deviceProvider.updateDeviceState('light_01', true)
  → DeviceProvider updates state + notifyListeners()
  → DeviceProvider calls: mqttProvider.publishCommand(...)
  → MqttProvider publishes: smarthome/devices/light_01/command → {"action":"ON"}
  → ESP32 receives message → digitalWrite(LIGHT_PIN, HIGH)
  → ESP32 publishes status: smarthome/devices/light_01/status → {"state":true}
  → App receives status → SensorProvider.handleMqttMessage()
  → DeviceProvider updates UI
  → Light appears ON in UI ✓
```

### Example 2: Voice command "Bật quạt"
```
User → Tap voice button, says "Bật quạt"
  → VoiceController.startListening()
  → Speech recognition returns "Bật quạt"
  → VoiceController calls: aiService.processVoiceCommand("Bật quạt", devices)
  → Gemini AI returns: {deviceKeyName: "fan_01", action: "turn_on"}
  → VoiceController finds device by keyName
  → VoiceController calls: deviceProvider.updateDeviceState('fan_01', true)
  → (Same as Example 1 from here...)
  → Fan turns ON ✓
```

### Example 3: Automation rule triggers
```
Rule: IF temp > 30°C THEN turn ON fan
  → SensorProvider receives sensor data: temp = 32°C
  → AutomationProvider.evaluateRules()
  → Checks rule conditions: 32 > 30? YES ✓
  → Condition satisfied → Execute startActions
  → Call deviceProvider.updateDeviceState('fan_01', true)
  → (Same device control flow...)
  → Fan turns ON automatically ✓
  
When temp drops to 25°C:
  → Condition no longer satisfied
  → Trigger endActions (default or custom)
  → Turn OFF fan automatically ✓
```

---

**Đây là kiến trúc hoàn chỉnh của dự án. Tất cả các luồng dữ liệu đều theo mô hình Provider Pattern với MQTT làm backbone cho IoT communication!**

