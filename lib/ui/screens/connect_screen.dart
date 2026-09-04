import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../ble/ble_provider.dart';
import '../../ble/ble_service.dart';
import '../../ble/permission_handler.dart';
import '../../core/constants.dart';

class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  bool _scanning = false;
  bool _connecting = false;
  String? _connectingDeviceId;
  SavedDevice? _savedDevice;

  @override
  void initState() {
    super.initState();
    _loadSavedDevice();
    _startScan();
  }

  Future<void> _loadSavedDevice() async {
    final saved = await ref.read(bleServiceProvider).getSavedDevice();
    if (mounted) setState(() => _savedDevice = saved);
  }

  Future<void> _startScan() async {
    final granted = await BlePermissionHandler.requestPermissions();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bluetooth permissions are required to connect to your WHOOP.'),
            action: SnackBarAction(label: 'Settings', onPressed: BlePermissionHandler.requestPermissions),
          ),
        );
      }
      return;
    }

    setState(() => _scanning = true);
    final bleService = ref.read(bleServiceProvider);
    await bleService.startScan();
    if (mounted) setState(() => _scanning = false);
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      _connecting = true;
      _connectingDeviceId = device.remoteId.str;
    });

    try {
      final bleService = ref.read(bleServiceProvider);
      await bleService.stopScan();
      await bleService.connect(device);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to ${device.platformName.isNotEmpty ? device.platformName : "WHOOP"}'),
            backgroundColor: AppConstants.primaryTeal,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection failed. Ensure HR Broadcast is enabled in your WHOOP app.'),
          ),
        );
        setState(() {
          _connecting = false;
          _connectingDeviceId = null;
        });
      }
    }
  }

  Future<void> _connectToSaved(SavedDevice saved) async {
    setState(() {
      _connecting = true;
      _connectingDeviceId = saved.id;
    });

    try {
      final bleService = ref.read(bleServiceProvider);
      await bleService.stopScan();
      await bleService.connectToSavedDevice(saved);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to ${saved.name}'),
            backgroundColor: AppConstants.primaryTeal,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not reach the saved device. Make sure it is nearby and broadcasting.'),
          ),
        );
        setState(() {
          _connecting = false;
          _connectingDeviceId = null;
        });
      }
    }
  }

  Future<void> _disconnect() async {
    await ref.read(bleServiceProvider).disconnect();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device disconnected.')),
      );
    }
  }

  Future<void> _forgetSaved() async {
    await ref.read(bleServiceProvider).forgetSavedDevice();
    if (mounted) setState(() => _savedDevice = null);
  }

  @override
  Widget build(BuildContext context) {
    final adapterState = ref.watch(adapterStateProvider);
    final scanResults = ref.watch(scanResultsProvider);
    final isConnected = ref.watch(isDeviceConnectedProvider);
    final bleService = ref.read(bleServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Device'),
      ),
      body: Column(
        children: [
          // Adapter state warning
          adapterState.when(
            data: (state) {
              if (state != BluetoothAdapterState.on) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.orange.withValues(alpha: 0.15),
                  child: const Text(
                    'Bluetooth is off. Please enable it to scan for devices.',
                    style: TextStyle(color: Colors.orange),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (e, _) => const SizedBox.shrink(),
          ),

          // Currently connected device with disconnect action
          if (isConnected)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Card(
                color: AppConstants.cardDark,
                child: ListTile(
                  leading: const Icon(Icons.bluetooth_connected, color: AppConstants.primaryTeal),
                  title: Text(
                    bleService.connectedDevice?.platformName.isNotEmpty == true
                        ? bleService.connectedDevice!.platformName
                        : (_savedDevice?.name ?? 'Connected device'),
                    style: const TextStyle(color: AppConstants.textPrimary),
                  ),
                  subtitle: const Text(
                    'Connected',
                    style: TextStyle(color: AppConstants.primaryTeal, fontSize: 12),
                  ),
                  trailing: TextButton(
                    onPressed: _disconnect,
                    child: const Text('Disconnect', style: TextStyle(color: Colors.redAccent)),
                  ),
                ),
              ),
            ),

          // Previously connected device — reconnect without scanning
          if (!isConnected && _savedDevice != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Card(
                color: AppConstants.cardDark,
                child: ListTile(
                  leading: const Icon(Icons.history, color: AppConstants.accentBlue),
                  title: Text(
                    _savedDevice!.name,
                    style: const TextStyle(color: AppConstants.textPrimary),
                  ),
                  subtitle: const Text(
                    'Previously connected — tap to reconnect',
                    style: TextStyle(color: AppConstants.textSecondary, fontSize: 12),
                  ),
                  trailing: _connectingDeviceId == _savedDevice!.id
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppConstants.primaryTeal),
                        )
                      : IconButton(
                          icon: const Icon(Icons.close, size: 18, color: AppConstants.textSecondary),
                          tooltip: 'Forget device',
                          onPressed: _forgetSaved,
                        ),
                  onTap: _connecting ? null : () => _connectToSaved(_savedDevice!),
                ),
              ),
            ),

          // Scanning indicator
          if (_scanning)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  LinearProgressIndicator(color: AppConstants.primaryTeal),
                  SizedBox(height: 8),
                  Text(
                    'Scanning for heart rate devices...',
                    style: TextStyle(color: AppConstants.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ),

          // Device list
          Expanded(
            child: scanResults.when(
              data: (results) {
                if (results.isEmpty && !_scanning) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bluetooth_searching, size: 48, color: AppConstants.textSecondary),
                        const SizedBox(height: 16),
                        const Text(
                          'No heart rate devices found',
                          style: TextStyle(color: AppConstants.textSecondary, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ensure HR Broadcast is enabled\nin your WHOOP app settings',
                          style: TextStyle(color: AppConstants.textSecondary, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton(
                          onPressed: _startScan,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: results.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemBuilder: (context, index) {
                    final result = results[index];
                    final device = result.device;
                    final name = device.platformName.isNotEmpty
                        ? device.platformName
                        : 'Unknown Device';
                    final isThisConnecting = _connectingDeviceId == device.remoteId.str;

                    return Card(
                      color: AppConstants.cardDark,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: const Icon(Icons.favorite, color: AppConstants.primaryTeal),
                        title: Text(name, style: const TextStyle(color: AppConstants.textPrimary)),
                        subtitle: Text(
                          'RSSI: ${result.rssi} dBm',
                          style: const TextStyle(color: AppConstants.textSecondary, fontSize: 12),
                        ),
                        trailing: isThisConnecting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppConstants.primaryTeal),
                              )
                            : const Icon(Icons.chevron_right, color: AppConstants.textSecondary),
                        onTap: _connecting ? null : () => _connectToDevice(device),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppConstants.primaryTeal),
              ),
              error: (e, _) => Center(
                child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
