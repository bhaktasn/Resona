import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class AppConstants {
  static final heartRateServiceUuid = Guid('0000180d-0000-1000-8000-00805f9b34fb');
  static final heartRateMeasurementUuid = Guid('00002a37-0000-1000-8000-00805f9b34fb');

  static const defaultInhaleDuration = Duration(seconds: 5);
  static const defaultExhaleDuration = Duration(seconds: 5);
  static const defaultInhaleHoldDuration = Duration.zero;
  static const defaultExhaleHoldDuration = Duration.zero;

  static const coherenceWindowSeconds = 64;
  static const coherenceUpdateIntervalSeconds = 5;
  static const interpolationRateHz = 4;
  static const minCalibrationSeconds = 30;

  // Artifact rejection thresholds
  static const minRRInterval = 300; // ms (~200 bpm)
  static const maxRRInterval = 2000; // ms (~30 bpm)

  // Colors
  static const backgroundDark = Color(0xFF0A0E21);
  static const cardDark = Color(0xFF1D1E33);
  static const primaryTeal = Color(0xFF00BFA5);
  static const accentBlue = Color(0xFF448AFF);
  static const coherenceLow = Color(0xFF607D8B);
  static const coherenceMedium = Color(0xFF448AFF);
  static const coherenceHigh = Color(0xFF00BFA5);
  static const textPrimary = Color(0xFFE0E0E0);
  static const textSecondary = Color(0xFF9E9E9E);
}
