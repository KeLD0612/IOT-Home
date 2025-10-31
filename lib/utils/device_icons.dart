import 'package:flutter/material.dart';

class DeviceIcons {
  // Get icon for device type
  static IconData getDeviceIcon(String deviceId) {
    switch (deviceId) {
      case 'pump':
        return Icons.water_drop;
      case 'light_living':
        return Icons.lightbulb;
      case 'light_yard':
        return Icons.light;
      case 'mist_maker':
        return Icons.cloud;
      case 'roof_servo':
        return Icons.roofing;
      case 'gate_servo':
        return Icons.door_front_door;
      default:
        return Icons.device_unknown;
    }
  }

  // Get icon for sensor type
  static IconData getSensorIcon(String sensorType) {
    switch (sensorType) {
      case 'temperature':
        return Icons.thermostat;
      case 'humidity':
        return Icons.water_drop;
      case 'rain':
        return Icons.cloud;
      case 'light':
        return Icons.wb_sunny;
      case 'soil_moisture':
        return Icons.grass;
      case 'gas':
        return Icons.cloud_queue;
      case 'dust':
        return Icons.blur_on;
      case 'pir':
      case 'motion':
        return Icons.sensors;
      default:
        return Icons.sensors;
    }
  }

  // Get icon for room
  static IconData getRoomIcon(String room) {
    switch (room.toLowerCase()) {
      case 'living room':
      case 'phòng khách':
        return Icons.weekend;
      case 'bedroom':
      case 'phòng ngủ':
        return Icons.bed;
      case 'kitchen':
      case 'nhà bếp':
        return Icons.kitchen;
      case 'bathroom':
      case 'phòng tắm':
        return Icons.bathtub;
      case 'yard':
      case 'sân':
        return Icons.yard;
      case 'garden':
      case 'vườn':
        return Icons.eco;
      case 'garage':
      case 'nhà để xe':
        return Icons.garage;
      case 'office':
      case 'văn phòng':
        return Icons.desk;
      default:
        return Icons.home;
    }
  }

  // Get icon for automation condition
  static IconData getConditionIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'temperature':
        return Icons.thermostat;
      case 'humidity':
        return Icons.water_drop;
      case 'light':
        return Icons.wb_sunny;
      case 'motion':
        return Icons.sensors;
      case 'time':
        return Icons.schedule;
      case 'rain':
        return Icons.cloud;
      case 'soil':
        return Icons.grass;
      case 'gas':
        return Icons.cloud_queue;
      case 'dust':
        return Icons.blur_on;
      default:
        return Icons.rule;
    }
  }

  // Get icon for automation action
  static IconData getActionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'turn_on':
      case 'on':
        return Icons.power_settings_new;
      case 'turn_off':
      case 'off':
        return Icons.power_off;
      case 'notify':
      case 'notification':
        return Icons.notifications;
      case 'set':
        return Icons.settings;
      case 'toggle':
        return Icons.swap_horiz;
      default:
        return Icons.play_arrow;
    }
  }

  // Get icon for alert type
  static IconData getAlertIcon(String alertType) {
    switch (alertType.toLowerCase()) {
      case 'gas':
      case 'gas_warning':
        return Icons.warning_amber;
      case 'rain':
      case 'rain_detected':
        return Icons.cloud;
      case 'soil':
      case 'low_soil_moisture':
        return Icons.water_drop;
      case 'dust':
        return Icons.blur_on;
      case 'motion':
        return Icons.sensors;
      case 'temperature':
        return Icons.thermostat;
      default:
        return Icons.notification_important;
    }
  }

  // Get icon for settings category
  static IconData getSettingsIcon(String category) {
    switch (category.toLowerCase()) {
      case 'general':
        return Icons.settings;
      case 'mqtt':
      case 'connection':
        return Icons.wifi;
      case 'notifications':
        return Icons.notifications;
      case 'theme':
      case 'appearance':
        return Icons.palette;
      case 'account':
      case 'profile':
        return Icons.person;
      case 'about':
      case 'info':
        return Icons.info;
      case 'privacy':
        return Icons.privacy_tip;
      case 'security':
        return Icons.security;
      case 'backup':
        return Icons.backup;
      case 'help':
        return Icons.help;
      default:
        return Icons.settings;
    }
  }

  // Get icon for connection status
  static IconData getConnectionIcon(bool isConnected) {
    return isConnected ? Icons.wifi : Icons.wifi_off;
  }

  // Get icon for battery level
  static IconData getBatteryIcon(int level) {
    if (level >= 90) {
      return Icons.battery_full;
    } else if (level >= 60) {
      return Icons.battery_6_bar;
    } else if (level >= 30) {
      return Icons.battery_3_bar;
    } else if (level >= 10) {
      return Icons.battery_2_bar;
    } else {
      return Icons.battery_alert;
    }
  }

  // Get icon for navigation
  static IconData getNavIcon(String navItem) {
    switch (navItem.toLowerCase()) {
      case 'home':
        return Icons.home;
      case 'devices':
        return Icons.devices;
      case 'sensors':
        return Icons.sensors;
      case 'automation':
        return Icons.auto_awesome;
      case 'settings':
        return Icons.settings;
      case 'history':
        return Icons.history;
      case 'dashboard':
        return Icons.dashboard;
      case 'notifications':
        return Icons.notifications;
      default:
        return Icons.apps;
    }
  }
}
