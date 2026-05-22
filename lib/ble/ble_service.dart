import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../core/constants.dart';
import 'heart_rate_parser.dart';

class BleService {
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _hrCharacteristic;
  StreamSubscription? _connectionSubscription;
  final _heartRateController = StreamController<HeartRateData>.broadcast();
  final _connectionStateController = StreamController<BluetoothConnectionState>.broadcast();

  int _reconnectAttempts = 0;
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
    await device.connect(autoConnect: false, timeout: const Duration(seconds: 10));
    _connectedDevice = device;
    _reconnectAttempts = 0;

    _connectionSubscription = device.connectionState.listen((state) {
      _connectionStateController.add(state);
      if (state == BluetoothConnectionState.disconnected) {
        _hrCharacteristic = null;
        _attemptReconnect();
      }
    });

    await _discoverAndSubscribe(device);
  }

  Future<void> _discoverAndSubscribe(BluetoothDevice device) async {
    final services = await device.discoverServices();

    for (final service in services) {
      if (service.uuid == AppConstants.heartRateServiceUuid) {
        for (final char in service.characteristics) {
          if (char.uuid == AppConstants.heartRateMeasurementUuid) {
            _hrCharacteristic = char;
            await char.setNotifyValue(true);
            char.onValueReceived.listen((value) {
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
    _connectionSubscription?.cancel();
    _connectionSubscription = null;

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
  }

  void dispose() {
    disconnect();
    _heartRateController.close();
    _connectionStateController.close();
  }
}
