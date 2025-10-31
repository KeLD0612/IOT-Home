import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF2196F3);
  static const Color primaryLight = Color(0xFF64B5F6);
  static const Color primaryDark = Color(0xFF1976D2);

  // Accent Colors
  static const Color accent = Color(0xFF00BCD4);
  static const Color accentLight = Color(0xFF4DD0E1);
  static const Color accentDark = Color(0xFF00838F);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Sensor Colors
  static const Color temperature = Color(0xFFFF6B6B);
  static const Color humidity = Color(0xFF4ECDC4);
  static const Color rain = Color(0xFF95E1D3);
  static const Color light = Color(0xFFFFA502);
  static const Color soil = Color(0xFF8B4513);
  static const Color gas = Color(0xFF9B59B6);
  static const Color dust = Color(0xFF95A5A6);
  static const Color motion = Color(0xFF3498DB);

  // Device Colors
  static const Color pumpColor = Color(0xFF00BCD4);
  static const Color lightColor = Color(0xFFFFEB3B);
  static const Color mistMakerColor = Color(0xFF00BCD4); // Cyan for mist
  static const Color servoColor = Color(0xFF607D8B);

  // Gradient Colors
  static const List<Color> blueGradient = [
    Color(0xFF2196F3),
    Color(0xFF00BCD4),
  ];

  static const List<Color> greenGradient = [
    Color(0xFF4CAF50),
    Color(0xFF8BC34A),
  ];

  static const List<Color> orangeGradient = [
    Color(0xFFFF9800),
    Color(0xFFFF5722),
  ];

  static const List<Color> purpleGradient = [
    Color(0xFF9C27B0),
    Color(0xFF673AB7),
  ];

  static const List<Color> sunsetGradient = [
    Color(0xFFFF6B6B),
    Color(0xFFFFE66D),
  ];

  static const List<Color> oceanGradient = [
    Color(0xFF4ECDC4),
    Color(0xFF556270),
  ];

  // Background Colors
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF1E1E1E);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textWhite = Colors.white;

  // Border Colors
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderDark = Color(0xFF424242);

  // Shadow Colors
  static const Color shadow = Color(0x1A000000);
  static const Color shadowDark = Color(0x33000000);

  // Status Indicator Colors
  static const Color online = Color(0xFF4CAF50);
  static const Color offline = Color(0xFFF44336);
  static const Color idle = Color(0xFFFF9800);

  // Chart Colors
  static const List<Color> chartColors = [
    Color(0xFF2196F3),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFF9C27B0),
    Color(0xFFFF5722),
    Color(0xFF00BCD4),
  ];

  // Alert Level Colors
  static const Color alertLow = Color(0xFF4CAF50);
  static const Color alertMedium = Color(0xFFFF9800);
  static const Color alertHigh = Color(0xFFFF5722);
  static const Color alertCritical = Color(0xFFF44336);

  // Helper Methods
  static Color getDeviceColor(String deviceId) {
    switch (deviceId) {
      case 'pump':
        return pumpColor;
      case 'light_living':
      case 'light_yard':
        return lightColor;
      case 'mist_maker':
        return mistMakerColor;
      case 'roof_servo':
      case 'gate_servo':
        return servoColor;
      default:
        return primary;
    }
  }

  static Color getSensorColor(String sensorType) {
    switch (sensorType) {
      case 'temperature':
        return temperature;
      case 'humidity':
        return humidity;
      case 'rain':
        return rain;
      case 'light':
        return light;
      case 'soil':
        return soil;
      case 'gas':
        return gas;
      case 'dust':
        return dust;
      case 'motion':
        return motion;
      default:
        return primary;
    }
  }

  static Color getAlertColor(int value, int threshold) {
    if (value < threshold * 0.5) {
      return alertLow;
    } else if (value < threshold * 0.75) {
      return alertMedium;
    } else if (value < threshold) {
      return alertHigh;
    } else {
      return alertCritical;
    }
  }

  static LinearGradient getGradient(
    List<Color> colors, {
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return LinearGradient(begin: begin, end: end, colors: colors);
  }
}
