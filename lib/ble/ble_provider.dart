import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ble_service.dart';
import 'heart_rate_parser.dart';

final bleServiceProvider = Provider<BleService>((ref) {
  final service = BleService();
  ref.onDispose(() => service.dispose());
  return service;
});

final adapterStateProvider = StreamProvider<BluetoothAdapterState>((ref) {
  return ref.watch(bleServiceProvider).adapterState;
});

final scanResultsProvider = StreamProvider<List<ScanResult>>((ref) {
  return ref.watch(bleServiceProvider).scanResults;
});

final connectionStateProvider = StreamProvider<BluetoothConnectionState>((ref) {
  return ref.watch(bleServiceProvider).connectionState;
});

final heartRateDataProvider = StreamProvider<HeartRateData>((ref) {
  return ref.watch(bleServiceProvider).heartRateStream;
});

final heartRateProvider = Provider<int?>((ref) {
  final data = ref.watch(heartRateDataProvider);
  return data.whenOrNull(data: (d) => d.heartRate);
});

final isDeviceConnectedProvider = Provider<bool>((ref) {
  final connState = ref.watch(connectionStateProvider);
  return connState.whenOrNull(data: (s) => s == BluetoothConnectionState.connected) ?? false;
});
