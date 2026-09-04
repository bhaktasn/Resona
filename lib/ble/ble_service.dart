import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import 'heart_rate_parser.dart';

/// A previously connected device remembered across app launches.
class SavedDevice {
  final String id;
  final String name;
  const SavedDevice({required this.id, required this.name});
}

class BleService {
  static const _savedDeviceIdKey = 'last_device_id';
  static const _savedDeviceNameKey = 'last_device_name';

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _hrCharacteristic;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _valueSubscription;
  final _heartRateController = StreamController<HeartRateData>.broadcast();
  final _connectionStateController = StreamController<BluetoothConnectionState>.broadcast();

  int _reconnectAttempts = 0;
  bool _manualDisconnect = false;
  static const _maxReconnectAttempts = 3;

  Stream<HeartRateData> get heartRateStream => _heartRateController.stream;
  Stream<BluetoothConnectionState> get connectionState => _connectionStateController.stream;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isConnected => _connectedDevice != null;

  Stream<BluetoothAdapterState> get adapterState => FlutterBluePlus.adapterState;

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  Future<void> startScan({Duration timeout = const Duration(seconds: 15)}) async {
    await FlutterBluePlus.startScan(
      withServices: [AppConstants.heartRateServiceUuid],
      timeout: timeout,
    );
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Future<void> connect(BluetoothDevice device) async {
    _manualDisconnect = false;
    await device.connect(autoConnect: false, timeout: const Duration(seconds: 10));
    _connectedDevice = device;
    _reconnectAttempts = 0;

    await _connectionSubscription?.cancel();
    _connectionSubscription = device.connectionState.listen((state) {
      _connectionStateController.add(state);
      if (state == BluetoothConnectionState.disconnected) {
        _hrCharacteristic = null;
        if (!_manualDisconnect) {
          _attemptReconnect();
        }
      }
    });

    await _discoverAndSubscribe(device);
    await _saveDevice(device);
  }

  /// Reconnect to the remembered device without scanning.
  Future<void> connectToSavedDevice(SavedDevice saved) async {
    final device = BluetoothDevice.fromId(saved.id);
    await connect(device);
  }

  Future<SavedDevice?> getSavedDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_savedDeviceIdKey);
    if (id == null) return null;
    return SavedDevice(
      id: id,
      name: prefs.getString(_savedDeviceNameKey) ?? 'Saved device',
    );
  }

  Future<void> forgetSavedDevice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedDeviceIdKey);
    await prefs.remove(_savedDeviceNameKey);
  }

  Future<void> _saveDevice(BluetoothDevice device) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedDeviceIdKey, device.remoteId.str);
    final name = device.platformName.isNotEmpty ? device.platformName : 'WHOOP';
    await prefs.setString(_savedDeviceNameKey, name);
  }

  Future<void> _discoverAndSubscribe(BluetoothDevice device) async {
    final services = await device.discoverServices();

    for (final service in services) {
      if (service.uuid == AppConstants.heartRateServiceUuid) {
        for (final char in service.characteristics) {
          if (char.uuid == AppConstants.heartRateMeasurementUuid) {
            _hrCharacteristic = char;
            await char.setNotifyValue(true);
            // Replace any listener from a previous (re)connect so beats
            // are never delivered twice.
            await _valueSubscription?.cancel();
            _valueSubscription = char.onValueReceived.listen((value) {
              final data = HeartRateParser.parse(value);
              _heartRateController.add(data);
            });
            return;
          }
        }
      }
    }
  }

  Future<void> _attemptReconnect() async {
    if (_reconnectAttempts >= _maxReconnectAttempts || _connectedDevice == null) return;

    _reconnectAttempts++;
    final delay = Duration(seconds: 1 << _reconnectAttempts); // 2, 4, 8 seconds
    await Future.delayed(delay);
    if (_manualDisconnect || _connectedDevice == null) return;

    try {
      await _connectedDevice!.connect(autoConnect: false, timeout: const Duration(seconds: 10));
      await _discoverAndSubscribe(_connectedDevice!);
      _reconnectAttempts = 0;
    } catch (_) {
      if (_reconnectAttempts < _maxReconnectAttempts) {
        _attemptReconnect();
      }
    }
  }

  Future<void> disconnect() async {
    _manualDisconnect = true;
    _connectionSubscription?.cancel();
    _connectionSubscription = null;
    _valueSubscription?.cancel();
    _valueSubscription = null;

    if (_hrCharacteristic != null) {
      try {
        await _hrCharacteristic!.setNotifyValue(false);
      } catch (_) {}
    }

    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
      } catch (_) {}
    }

    _connectedDevice = null;
    _hrCharacteristic = null;
    _reconnectAttempts = 0;

    // The state listener was cancelled above, so surface the final state
    // ourselves — otherwise the UI never learns the device is gone.
    _connectionStateController.add(BluetoothConnectionState.disconnected);
  }

  void dispose() {
    disconnect();
    _heartRateController.close();
    _connectionStateController.close();
  }
}
