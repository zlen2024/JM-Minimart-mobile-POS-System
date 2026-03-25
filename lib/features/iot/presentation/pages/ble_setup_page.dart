import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

// --- YOUR ESP32 UUIDS (Must match your C++ code exactly) ---
const String SERVICE_UUID = "12345678-1234-1234-1234-123456789000";
const String SSID_UUID    = "12345678-1234-1234-1234-123456789001";
const String PASS_UUID    = "12345678-1234-1234-123456789002";
const String WSURL_UUID   = "12345678-1234-1234-1234-123456789003";
const String PIN_UUID     = "12345678-1234-1234-1234-123456789004";

class BLEProvisioningPage extends StatefulWidget {
  const BLEProvisioningPage({super.key});

  @override
  State<BLEProvisioningPage> createState() => _BLEProvisioningPageState();
}

class _BLEProvisioningPageState extends State<BLEProvisioningPage> {
  // UI Controllers
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _pinController = TextEditingController(text: "0000");

  // State Variables
  BluetoothDevice? _connectedDevice;
  bool _isScanning = false;
  String _statusLog = "Ready to scan.";

  // Characteristic Holders
  BluetoothCharacteristic? _ssidChar;
  BluetoothCharacteristic? _passChar;
  BluetoothCharacteristic? _urlChar;
  BluetoothCharacteristic? _pinChar;

  StreamSubscription? _scanSubscription;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _ssidController.dispose();
    _passController.dispose();
    _urlController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  // 1. Request Permissions (Android 12+ needs this)
  Future<void> _checkPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  // 2. Scan for your specific device "MyIoT-Setup"
  void _startScan() async {
    setState(() {
      _isScanning = true;
      _statusLog = "Scanning for 'MyIoT-Setup'...";
    });

    // Listen to scan results
    _scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.device.platformName == "MyIoT-Setup" || r.device.advName == "MyIoT-Setup") {
          _connectToDevice(r.device);
          FlutterBluePlus.stopScan(); // Stop scanning once found
          break;
        }
      }
    }, onError: (e) => print(e));

    // Start scanning
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    // Auto-stop scanning UI if timeout reached without finding device
    await Future.delayed(const Duration(seconds: 10));
    if (_connectedDevice == null && mounted) {
        setState(() {
          _isScanning = false;
          if(_statusLog.contains("Scanning")) _statusLog = "Device not found. Try again.";
        });
    }
  }

  // 3. Connect and Discover Services
  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() => _statusLog = "Found! Connecting...");

    try {
      await device.connect();
      setState(() {
        _connectedDevice = device;
        _statusLog = "Connected! Discovering Services...";
      });

      // Discover Services
      List<BluetoothService> services = await device.discoverServices();

      // Find our specific service and characteristics
      for (var service in services) {
        if (service.uuid.toString() == SERVICE_UUID.toLowerCase()) {
          for (var c in service.characteristics) {
            String uuid = c.uuid.toString();
            if (uuid == SSID_UUID.toLowerCase()) _ssidChar = c;
            if (uuid == PASS_UUID.toLowerCase()) _passChar = c;
            if (uuid == WSURL_UUID.toLowerCase()) _urlChar = c;
            if (uuid == PIN_UUID.toLowerCase()) _pinChar = c;
          }
        }
      }

      if (_ssidChar != null) {
        setState(() => _statusLog = "Ready to Provision!");
      } else {
        setState(() => _statusLog = "Error: Service UUID not found on device.");
        await device.disconnect();
      }

    } catch (e) {
      setState(() => _statusLog = "Connection failed: $e");
    }
  }

  // 4. Send Data to ESP32
  Future<void> _provisionDevice() async {
    if (_connectedDevice == null) return;

    setState(() => _statusLog = "Sending data...");

    try {
      // Write data to characteristics (convert String to Bytes)
      // Note: We write PIN last if your ESP logic checks it last,
      // but usually the ESP waits for all 4 flags.

      if (_ssidChar != null) await _ssidChar!.write(utf8.encode(_ssidController.text));
      await Future.delayed(const Duration(milliseconds: 100)); // Small delay for stability

      if (_passChar != null) await _passChar!.write(utf8.encode(_passController.text));
      await Future.delayed(const Duration(milliseconds: 100));

      if (_urlChar != null) await _urlChar!.write(utf8.encode(_urlController.text));
      await Future.delayed(const Duration(milliseconds: 100));

      if (_pinChar != null) await _pinChar!.write(utf8.encode(_pinController.text));

      setState(() => _statusLog = "Sent! Check ESP32 Serial Monitor.");

      // Optional: Disconnect after success
      // await _connectedDevice!.disconnect();

    } catch (e) {
      setState(() => _statusLog = "Write failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ESP32 BLE Setup")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Status Display
              Container(
                padding: const EdgeInsets.all(10),
                color: Colors.grey[200],
                width: double.infinity,
                child: Text(_statusLog, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),

              // Scan Button
              if (_connectedDevice == null)
                ElevatedButton.icon(
                  icon: _isScanning
                    ? const SizedBox(width:12, height:12, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(Icons.bluetooth_searching),
                  label: Text(_isScanning ? "Scanning..." : "Scan for ESP32"),
                  onPressed: _isScanning ? null : _startScan,
                ),

              // Input Fields (Only show when connected)
              if (_connectedDevice != null) ...[
                const SizedBox(height: 20),
                TextField(controller: _ssidController, decoration: const InputDecoration(labelText: "WiFi SSID")),
                TextField(controller: _passController, decoration: const InputDecoration(labelText: "WiFi Password")),
                TextField(controller: _urlController, decoration: const InputDecoration(labelText: "WebSocket URL (ws://...)")),
                TextField(controller: _pinController, decoration: const InputDecoration(labelText: "Security PIN")),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                    onPressed: _provisionDevice,
                    child: const Text("PROVISION DEVICE"),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
