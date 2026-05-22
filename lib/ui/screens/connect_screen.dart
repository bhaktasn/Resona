import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../ble/ble_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _startScan();
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

  @override
  Widget build(BuildContext context) {
    final adapterState = ref.watch(adapterStateProvider);
    final scanResults = ref.watch(scanResultsProvider);

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
